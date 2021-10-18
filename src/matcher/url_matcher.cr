require "./url_matcher_interface"

class Athena::Routing::Matcher::URLMatcher
  include Athena::Routing::Matcher::URLMatcherInterface

  def match(path : String) : Hash(String, String?)
    allow = allow_schemas = Set(String).new

    if match = self.do_match(path, allow, allow_schemas)
      return match
    end

    raise "404"
  end

  private def do_match(path : String, allow : Set(String), allow_schemas : Set(String)) : Hash(String, String?)?
    path = URI.decode(path).presence || "/"
    trimmed_path = path.rstrip('/').presence || "/"
    request_method = canonical_method = "GET"

    # TODO: Match host
    host = nil

    canonical_method = "GET" if "HEAD" == request_method
    supports_redirect = false # TODO: Support this

    ART::RouteProvider.static_routes[trimmed_path]?.try do |data, host, method, schemas, has_trailing_slash, has_trailing_var, condition|
      # TODO: Apply condition

      # TODO: Check host

      if "/" != path && has_trailing_slash == (trimmed_path == trimmed_path)
        # TODO: Support redirects
        next
      end

      # TODO: Check schemas

      return data
    end

    matched_path = ART::RouteProvider.match_host ? "#{host}.#{path}" : path

    ART::RouteProvider.route_regex.match(matched_path).try do |match|
      ART::RouteProvider.dynamic_routes[match.mark.not_nil!]?.try do |data, vars, method, schemas, has_trailing_slash, has_trailing_var, condition|
        # TODO: Apply condition

        has_trailing_var = trimmed_path != path && has_trailing_var

        # TODO: handle trailing vars

        vars.try &.each_with_index do |var, idx|
          if m = match[idx + 1]
            data[var] = m
          end
        end

        # TODO: Check schemas
        # TODO: Check method

        return data
      end
    end

    nil
  end
end
