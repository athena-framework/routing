require "./static_prefix_collection"

# :nodoc:
# Exposes getters to static/dynamic routes as well as the full route regex.
# Values are cached on the class level for performance resaons.
class Athena::Routing::RouteProvider
  private alias Condition = Proc(HTTP::Request, Bool)

  # We store this as a tuple in order to get splatting/unpacking features.
  # defaults, variables, method, schemas, trailing slash? trailing var?, condition
  private alias RouteData = Tuple(Hash(String, String?), Set(String)?, String, Set(String)?, Bool, Bool, Condition?)

  private record PreCompiledStaticRoute, route : ART::Route, has_trailing_slash : Bool
  private record PreCompiledDynamicRegex, host_regex : Regex?, regex : Regex, static_prefix : String

  @@match_host : Bool? = nil
  @@static_routes : Hash(String, RouteData)? = nil
  @@dynamic_routes : Hash(String, RouteData)? = nil
  @@route_regex : Regex? = nil
  @@conditions : Hash(String, Condition)? = nil

  @@compiled : Bool = false

  getter routes : ART::RouteCollection

  def initialize(@routes : ART::RouteCollection); end

  def static_routes : Hash(String, RouteData)
    self.compile unless @@compiled

    @@static_routes.not_nil!
  end

  # def dynamic_routes : Hash(String, RouteData)
  #   self.class.dynamic_routes
  # end

  # def route_regex : Regex
  #   self.class.route_regex
  # end

  private def compile : Nil
    match_host = false
    routes = Athena::Routing::RouteProvider::StaticPrefixCollection.new

    @routes.each do |name, route|
      if host = route.host
        match_host = true

        # TODO: Build host pattern
      end

      routes.add_route (host || "/(.*)"), {name, route}
    end

    if match_host
      @@match_host = true
      routes = routes.populate_collection ART::RouteCollection.new
    else
      @@match_host = false
      routes = @routes
    end

    static_routes, dynamic_routes = self.group_static_routes routes

    conditions = Array(Condition).new

    self.compile_static_routes static_routes, conditions
  end

  private alias StaticRoutes = Hash(String, Hash(String, PreCompiledStaticRoute))

  private def compile_static_routes(static_routes : StaticRoutes, conditions : Array(Condition)) : Nil
    return if static_routes.empty?

    sr = Hash(String, RouteData).new

    static_routes.each do |url, routes|
      # TODO: Will there ever be more than 1?
      name, pre_compiled_route = routes.first

      route = pre_compiled_route.route

      variables = if route.compile.host_variables.empty? && (host = route.host)
                    Set{host}
                  elsif pattern = route.compile.host_pattern
                    Set{pattern}
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

  private def compile_route(route : ART::Route, name : String, vars : Set(String)?, has_trailing_slash : Bool, has_trailing_var : Bool, conditions : Array(Condition)) : RouteData
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

  private def group_static_routes(routes : ART::RouteCollection) : Tuple(StaticRoutes, ART::RouteCollection)
    static_routes = Hash(String, Hash(String, PreCompiledStaticRoute)).new { |hash, key| hash[key] = Hash(String, PreCompiledStaticRoute).new }
    dynamic_regex = Array(PreCompiledDynamicRegex).new
    dynamic_routes = ART::RouteCollection.new

    routes.each do |name, route|
      compiled_route = route.compile
      static_prefix = compiled_route.static_prefix.rstrip '/'
      host_regex = compiled_route.host_regex
      pattern = compiled_route.pattern

      has_trailing_slash = "/" != route.path

      if has_trailing_slash
        pos = pattern.index('$').not_nil!
        has_trailing_slash = "/" == pattern[pos - 1]
        pattern = pattern.sub((pos - (has_trailing_slash ? 1 : 0))..(pos + (has_trailing_slash ? 1 : 0)), "/?$")
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
            dynamic_regex << PreCompiledDynamicRegex.new host_regex, Regex.new(pattern), static_prefix
            dynamic_routes.add name, route
            break true
          end
        end

        next if should_next

        static_routes[url][name] = PreCompiledStaticRoute.new route, has_trailing_slash
      else
        dynamic_regex << PreCompiledDynamicRegex.new host_regex, Regex.new(pattern), static_prefix
        dynamic_routes.add name, route
      end
    end

    {static_routes, dynamic_routes}
  end
end
