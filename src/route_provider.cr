require "./static_prefix_collection"

# :nodoc:
#
# Exposes getters to static/dynamic routes as well as the full route regex.
# Values are cached on the class level for performance resaons.
class Athena::Routing::RouteProvider
  private alias Condition = Proc(HTTP::Request, Bool)

  # We store this as a tuple in order to get splatting/unpacking features.
  # defaults, variables, method, schemas, trailing slash? trailing var?, condition
  private alias RouteData = Tuple(Hash(String, String?), Set(String)?, String, Set(String)?, Bool, Bool, Condition?)

  private record PreCompiledStaticRoute, route : ART::Route, has_trailing_slash : Bool
  private record PreCompiledDynamicRegex, host_regex : Regex?, regex : Regex, static_prefix : String
  private record PreCompiledDynamicRoute, pattern : String, routes : ART::RouteCollection

  @@match_host : Bool? = nil
  @@static_routes : Hash(String, RouteData)? = nil
  @@dynamic_routes : Hash(String, RouteData)? = nil
  @@route_regex : Regex? = nil
  @@conditions : Hash(String, Condition)? = nil

  @@compiled : Bool = false

  def self.init(routes : ART::RouteCollection)
    return unless @@routes.nil?

    @@routes = routes
  end

  def self.match_host : Bool
    self.compile unless @@compiled

    @@match_host.not_nil!
  end

  def self.static_routes : Hash(String, RouteData)
    self.compile unless @@compiled

    @@static_routes.not_nil!
  end

  def self.dynamic_routes : Hash(String, RouteData)
    self.compile unless @@compiled

    @@dynamic_routes.not_nil!
  end

  def self.route_regex : Regex
    self.compile unless @@compiled

    @@route_regex.not_nil!
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

    self.compile_dynamic_routes dynamic_routes, match_host, chunk_limit, conditions

    @@compiled = true
  end

  private def self.compile_dynamic_routes(collection : ART::RouteCollection, match_host : Bool, chunk_limit : Int, conditions : Array(Condition)) : Nil
    raise "FIXME: Empty collection" if collection.empty?

    # TODO: Handle chunking the regex if too big.

    final_pattern = "^(?"
    dr = Hash(String, RouteData).new

    # TODO: Handle diff host values

    previous_regex : Regex? = nil
    tree = ART::RouteProvider::StaticPrefixCollection.new

    collection.each do |name, route|
      # TODO: Handle matching host
      matched_regex = route.compile.regex.source.match(/\^(.*)\$$/).not_nil!

      vars = Set(String).new
      pattern = matched_regex[1].gsub(/\?P<([^>]++)>/) do |_, match|
        next "?:" if "_route" == match[1]

        vars << match[1].to_s

        ""
      end

      if has_trailing_slash = "/" != pattern && pattern.ends_with? '/'
        pattern = pattern.rchop '/'
      end

      has_trailing_var = route.path.matches? /\{\w+\}\/?$/

      tree.add_route pattern, ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute.new name, pattern, vars, route, has_trailing_slash, has_trailing_var
    end

    previous_regex = nil
    prefix_len = 0

    tree.items.each do |item|
      case item
      in ART::RouteProvider::StaticPrefixCollection
        previous_regex = nil
        prefix = item.prefix[prefix_len..]
        pattern = "|#{prefix}(?"
        final_pattern += pattern
        final_pattern += ")"
        next
      in ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute
        compiled_route = item.route.compile

        # TODO: Merge in host vars.
        vars = item.variables

        if compiled_route.regex == previous_regex
          next
        end

        final_pattern += "|#{item.pattern}(*:10)"

        dr["10"] = self.compile_route item.route, item.name, vars, item.has_trailing_slash, item.has_trailing_var, conditions
      in ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute
        raise "BUG: StaticTreeNamedRoute"
      end
    end

    # TODO: Handle matching host.

    final_pattern += ")/?$"

    @@route_regex = Regex.new final_pattern
    @@dynamic_routes = dr
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
      route.method,
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
