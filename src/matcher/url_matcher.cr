require "./url_matcher_interface"

class Athena::Routing::Matcher::URLMatcher
  include Athena::Routing::Matcher::RequestMatcherInterface
  include Athena::Routing::Matcher::URLMatcherInterface

  property context : ART::RequestContext

  @request : ART::Request? = nil

  def initialize(@context : ART::RequestContext); end

  def match(@request : ART::Request) : Hash(String, String?)
    self.match @request.not_nil!.path
  ensure
    @request = nil
  end

  def match(path : String) : Hash(String, String?)
    allow = allow_schemas = Array(String).new

    if match = self.do_match path, allow, allow_schemas
      return match
    end

    unless allow.empty?
      raise ART::Exceptions::MethodNotAllowed.new allow
    end

    raise ART::Exceptions::ResourceNotFound.new "No routes found for '#{path}'."
  end

  private def do_match(path : String, allow : Array(String), allow_schemas : Array(String)) : Hash(String, String?)?
    allow.clear
    allow_schemas.clear

    path = URI.decode(path).presence || "/"
    path = path.presence || "/"
    trimmed_path = path.rstrip('/').presence || "/"
    request_method = canonical_method = @context.method

    host = @context.host.downcase if ART::RouteProvider.match_host

    canonical_method = "GET" if "HEAD" == request_method
    supports_redirect = false # TODO: Support this

    ART::RouteProvider.static_routes[trimmed_path]?.try &.each do |data, required_host, required_methods, required_schemas, has_trailing_slash, has_trailing_var, condition|
      if condition && (request = @request) && !(ART::RouteProvider.conditions[condition].call(request))
        next
      end

      required_host.try do |h|
        case h
        in String then next if h != host
        in Regex
          if (match = host.try &.match h)
            host_matches = match.named_captures
            host_matches["_route"] = data["_route"]

            host_matches.each do |key, value|
              data[key] = value unless value.nil?
            end
          else
            next
          end
        end
      end

      if "/" != path && has_trailing_slash == (trimmed_path == path)
        # TODO: Support redirects
        next
      end

      # TODO: Check schemas
      has_required_scheme = required_schemas.nil? || required_schemas.includes? @context.scheme
      if has_required_scheme && required_methods && !required_methods.includes?(canonical_method) && !required_methods.includes?(request_method)
        allow.concat required_methods
        next
      end

      if !has_required_scheme
        required_schemas.try do |schemes|
          allow_schemas.concat schemes
        end
        next
      end

      return data
    end

    matched_path = ART::RouteProvider.match_host ? "#{host}.#{path}" : path

    ART::RouteProvider.route_regexes.each do |offset, regex|
      regex.match(matched_path).try do |match|
        ART::RouteProvider.dynamic_routes[matched_mark = match.mark.not_nil!]?.try &.each do |data, vars, required_methods, required_schemas, has_trailing_slash, has_trailing_var, condition|
          # Dup the data hash so we don't mutate the original.
          data = data.dup

          if condition && (request = @request) && !(ART::RouteProvider.conditions[condition].call(request))
            next
          end

          has_trailing_var = trimmed_path != path && has_trailing_var

          has_n = has_trailing_slash || false # FIXME: When some test fails because of it :S

          if has_trailing_var && has_n && (sub_match = regex.match(ART::RouteProvider.match_host ? "#{host}.#{trimmed_path}" : trimmed_path)) && (matched_mark == sub_match.mark.not_nil!)
            if has_trailing_slash
              match = sub_match
            else
              has_trailing_var = false
            end
          end

          if "/" != path && !has_trailing_var && has_trailing_slash == (trimmed_path == path)
            # TODO: Support redirections
            next
          end

          vars.try &.each_with_index do |var, idx|
            if m = match[idx + 1]?
              data[var] = m
            end
          end

          if required_schemas && required_schemas.includes? @context.scheme
            allow_schemas.concat required_schemas
            next
          end

          if required_methods && !required_methods.includes?(canonical_method) && !required_methods.includes?(request_method)
            allow.concat required_methods
            next
          end

          return data
        end
      end
    end

    nil
  end
end
