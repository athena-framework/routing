require "./static_prefix_collection"

# :nodoc:
#
# Exposes getters to static/dynamic routes as well as the full route regex.
# Values are cached on the class level for performance resaons.
class Athena::Routing::RouteProvider
  private alias Condition = Proc(HTTP::Request, Bool)

  # We store this as a tuple in order to get splatting/unpacking features.
  # defaults, variables, methods, schemas, trailing slash?, trailing var?, conditions
  private alias RouteData = Tuple(Hash(String, String?), Set(String)?, Set(String)?, Set(String)?, Bool, Bool, Condition?)

  private record PreCompiledStaticRoute, route : ART::Route, has_trailing_slash : Bool
  private record PreCompiledDynamicRegex, host_regex : Regex?, regex : Regex, static_prefix : String
  private record PreCompiledDynamicRoute, pattern : String, routes : ART::RouteCollection

  private class State
    property vars : Set(String) = Set(String).new
    property host_vars : Set(String) = Set(String).new
    property mark : Int32 = 0
    property mark_tail : Int32 = 0
    getter routes : Hash(String, RouteData)
    property regex : String = ""

    def initialize(@routes : Hash(String, RouteData)); end

    def vars(subject : String) : String
      subject.gsub(/\?P<([^>]++)>/) do |_, match|
        next "?:" if "_route" == match[1]

        @vars << match[1].to_s

        ""
      end
    end
  end

  @@match_host : Bool = false
  @@static_routes : Hash(String, RouteData) = Hash(String, RouteData).new
  @@dynamic_routes : Hash(String, RouteData) = Hash(String, RouteData).new
  @@route_regexes : Hash(Int32, ART::FastRegex) = Hash(Int32, ART::FastRegex).new
  @@conditions : Hash(String, Condition)? = nil

  class_getter compiled : Bool = false

  def self.compile(routes : ART::RouteCollection) : Nil
    return unless @@routes.nil?

    @@routes = routes
  end

  def self.match_host : Bool
    self.compile unless @@compiled

    @@match_host
  end

  def self.static_routes : Hash(String, RouteData)
    self.compile unless @@compiled

    @@static_routes
  end

  def self.dynamic_routes : Hash(String, RouteData)
    self.compile unless @@compiled

    @@dynamic_routes
  end

  def self.route_regexes : Hash(Int32, ART::FastRegex)
    self.compile unless @@compiled

    @@route_regexes
  end

  private def self.compile : Nil
    match_host = false
    routes = ART::RouteProvider::StaticPrefixCollection.new

    self.routes.each do |name, route|
      if host = route.host
        match_host = true

        # TODO: Build host pattern
      end

      routes.add_route (host || "/(.*)"), ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute.new name, route
    end

    if match_host
      @@match_host = true
      routes = routes.populate_collection ART::RouteCollection.new
    else
      @@match_host = false
      routes = self.routes
    end

    static_routes, dynamic_routes = self.group_static_routes routes

    conditions = Array(Condition).new

    self.compile_static_routes static_routes, conditions

    chunk_limit = dynamic_routes.size

    loop do
      self.compile_dynamic_routes dynamic_routes, match_host, chunk_limit, conditions
      break
    rescue e : ArgumentError
      if 1 < chunk_limit && e.message.try(&.starts_with?("regular expression is too large"))
        chunk_limit = 1 + (chunk_limit >> 1)
        next
      end

      raise e
    end

    @@compiled = true
  end

  private def self.compile_dynamic_routes(collection : ART::RouteCollection, match_host : Bool, chunk_limit : Int, conditions : Array(Condition)) : Nil
    dr = Hash(String, RouteData).new

    if collection.empty?
      return @@dynamic_routes = dr
    end

    state = State.new dr

    chunk_size = 0
    routes = nil
    collections = Array(ART::RouteCollection).new

    collection.each do |name, route|
      if chunk_limit < (chunk_size += 1) || routes.nil?
        chunk_size = 1
        routes = ART::RouteCollection.new
        collections << routes
      end

      routes.not_nil!.add name, route
    end

    collections.each do |collection|
      previous_regex = false
      per_host_routes = Hash(Regex?, ART::RouteCollection).new
      host_routes = nil

      collection.each do |name, route|
        regex = route.compile.host_regex
        if previous_regex != regex
          host_routes = ART::RouteCollection.new
          per_host_routes[regex] = host_routes
          previous_regex = regex
        end

        host_routes.not_nil!.add name, route
      end

      previous_regex = false
      final_regex = "^(?"
      starting_mark = state.mark
      state.mark += final_regex.size + 1 # Add 1 to account for the eventual `/`.
      state.regex = final_regex

      per_host_routes.each do |host_regex, routes|
        # TODO: Match host: 316

        tree = ART::RouteProvider::StaticPrefixCollection.new

        routes.each do |name, route|
          # TODO: Handle matching host
          matched_regex = route.compile.regex.source.match(/\^(.*)\$$/).not_nil!

          state.vars = Set(String).new
          pattern = state.vars matched_regex[1]

          if has_trailing_slash = "/" != pattern && pattern.ends_with? '/'
            pattern = pattern.rchop '/'
          end

          has_trailing_var = route.path.matches? /\{\w+\}\/?$/

          tree.add_route pattern, ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute.new name, pattern, state.vars, route, has_trailing_slash, has_trailing_var
        end

        self.compile_static_prefix_collection tree, state, 0, conditions
      end

      if match_host
        state.regex += ")"
      end

      state.regex += ")/?$"
      state.mark_tail = 0

      @@route_regexes[starting_mark] = ART::FastRegex.new state.regex
    end

    @@dynamic_routes = state.routes
  end

  private def self.compile_static_prefix_collection(tree : ART::RouteProvider::StaticPrefixCollection, state : State, prefix_length : Int32, conditions) : Nil
    previous_regex = nil

    tree.items.each do |item|
      case item
      in ART::RouteProvider::StaticPrefixCollection
        previous_regex = nil
        prefix = item.prefix[prefix_length..]
        pattern = "|#{prefix}(?"
        state.mark += pattern.size
        state.regex += pattern

        self.compile_static_prefix_collection item, state, prefix_length + prefix.size, conditions

        state.regex += ")"
        state.mark_tail += 1

        next
      in ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute
        compiled_route = item.route.compile
        vars = item.variables + state.host_vars

        if compiled_route.regex == previous_regex
          state.routes[state.mark.to_s] = self.compile_route item.route, item.name, vars, item.has_trailing_slash, item.has_trailing_var, conditions
          next
        end

        state.mark += 3 + state.mark_tail + item.pattern.size - prefix_length
        state.mark_tail = 2 + state.mark.digits.size

        state.regex += "|#{item.pattern[prefix_length..]}(*:#{state.mark})"

        previous_regex = compiled_route.regex
        state.routes[state.mark.to_s] = self.compile_route item.route, item.name, vars, item.has_trailing_slash, item.has_trailing_var, conditions
      in ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute
        raise "BUG: StaticTreeNamedRoute"
      in ART::RouteProvider::StaticPrefixCollection::StaticTreeName
        raise "BUG: StaticTreeName"
      end
    end
  end

  private alias StaticRoutes = Hash(String, Hash(String, PreCompiledStaticRoute))

  private def self.compile_static_routes(static_routes : StaticRoutes, conditions : Array(Condition)) : Nil
    return if static_routes.empty?

    sr = Hash(String, RouteData).new

    static_routes.each do |url, routes|
      # TODO: Will there ever be more than 1 hash of routes?
      name, pre_compiled_route = routes.first

      route = pre_compiled_route.route

      variables = if route.compile.host_variables.empty? && (host = route.host)
                    Set{host}
                  elsif regex = route.compile.host_regex
                    Set{regex.source}
                  end

      sr[url] = self.compile_route(
        route,
        name,
        variables,
        pre_compiled_route.has_trailing_slash,
        false,
        conditions
      )
    end

    @@static_routes = sr
  end

  private def self.compile_route(route : ART::Route, name : String, vars : Set(String)?, has_trailing_slash : Bool, has_trailing_var : Bool, conditions : Array(Condition)) : RouteData
    defaults = route.defaults

    if cannonical_route = defaults["_canonical_route"]?
      name = cannonical_route
      defaults.delete "_canonical_route"
    end

    # TODO: Handle setting these?
    condition = nil

    {
      Hash(String, String?){"_route" => name}.merge!(defaults),
      vars,
      route.methods,
      route.schemas,
      has_trailing_slash,
      has_trailing_var,
      condition,
    }
  end

  private def self.group_static_routes(routes : ART::RouteCollection) : Tuple(StaticRoutes, ART::RouteCollection)
    static_routes = Hash(String, Hash(String, PreCompiledStaticRoute)).new { |hash, key| hash[key] = Hash(String, PreCompiledStaticRoute).new }
    dynamic_regex = Array(PreCompiledDynamicRegex).new
    dynamic_routes = ART::RouteCollection.new

    routes.each do |name, route|
      compiled_route = route.compile
      static_prefix = compiled_route.static_prefix.rstrip '/'
      host_regex = compiled_route.host_regex
      regex = compiled_route.regex

      has_trailing_slash = "/" != route.path

      if has_trailing_slash
        pos = regex.source.index('$').not_nil!
        has_trailing_slash = "/" == regex.source[pos - 1]
        regex = /#{regex.source.sub((pos - (has_trailing_slash ? 1 : 0))..(pos + (has_trailing_slash ? 1 : 0)), "/?$")}/
      end

      if compiled_route.path_variables.empty?
        host = compiled_route.host_variables.empty? ? "" : route.host
        url = route.path

        if has_trailing_slash
          url = url.rstrip '/'
        end

        should_next = dynamic_regex.each do |dr|
          host_regex_matches = host ? dr.host_regex.try &.matches?(host) : false

          if (dr.static_prefix.empty? || url.starts_with?(dr.static_prefix)) && (dr.regex.matches?(url) || dr.regex.matches?("#{url}/")) && (host.presence || host_regex.nil? || host_regex_matches)
            dynamic_regex << PreCompiledDynamicRegex.new host_regex, regex, static_prefix
            dynamic_routes.add name, route
            break true
          end
        end

        next if should_next

        static_routes[url][name] = PreCompiledStaticRoute.new route, has_trailing_slash
      else
        dynamic_regex << PreCompiledDynamicRegex.new host_regex, regex, static_prefix
        dynamic_routes.add name, route
      end
    end

    {static_routes, dynamic_routes}
  end

  private def self.routes : ART::RouteCollection
    @@routes || raise "RouteProvider has not been intialized!"
  end
end
