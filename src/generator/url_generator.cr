class Athena::Routing::Generator::URLGenerator
  include Athena::Routing::Generator::Interface
  include Athena::Routing::Generator::ConfigurableRequirementsInterface

  property context : ART::RequestContext
  property? strict_requirements : Bool? = true

  def initialize(
    @context : ART::RequestContext,
    @default_locale : String? = nil
  )
  end

  def generate(route : String, params : Hash(String, _) = Hash(String, String).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    if locale = params["_locale"]? || @default_locale
      if (locale_route = ART::RouteProvider.route_generation_data["#{route}.#{locale}"]?) && (route == locale_route[1]["_canonical_route"]?)
        route = "#{route}.#{locale}"
      end
    end

    unless (generation_data = ART::RouteProvider.route_generation_data[route]?)
      raise ART::Exceptions::RouteNotFound.new "No route with the name '#{route}' exists."
    end

    variables, defaults, requirements, tokens, host_tokens, schemes = generation_data

    if defaults.has_key?("_canonical_route") && defaults.has_key?("_locale")
      if !variables.includes? "_locale"
        params.delete "_locale"
      elsif !params.has_key?("_locale")
        params = params.merge({"_locale" => defaults["_locale"]})
      end
    end

    self.do_generate variables, defaults, requirements, tokens, params, route, reference_type, host_tokens, schemes
  end

  private def do_generate(
    variables : Set(String),
    defaults : Hash(String, String?),
    requirements : Hash(String, Regex),
    tokens : Array(ART::RouteCompiler::Token),
    params : Hash(String, _),
    name : String,
    reference_type : ART::Generator::ReferenceType,
    host_tokens : Array(ART::RouteCompiler::Token),
    required_schemes : Set(String)?
  ) : String
    merged_params = defaults.merge params

    unless (missing_params = variables - merged_params.keys).empty?
      raise "Missing params #{missing_params}"
    end

    url = ""
    optional = true
    message = "Route parameter '{parameter}' for route '{route}' must match '{expected}' (got '{given}') to generate the correspdonding URL."
    tokens.each do |token|
      case token.type
      in .variable?
        var_name = token.var_name
        important = token.important?

        if !optional || important || !defaults.has_key?(var_name) || (!merged_params[var_name]?.nil? && merged_params[var_name].to_s != defaults[var_name].to_s)
          if !@strict_requirements.nil? && !(token.var_name || "").matches?(/./)
            raise "Invalid param" if @strict_requirements

            return ""
          end

          url = "#{token.prefix}#{merged_params[var_name]}#{url}"
          optional = false
        end
      in .text?
        url = "#{token.prefix}#{url}"
        optional = false
      end
    end

    url = "/" if url.empty?

    url = URI.encode_path url

    # TODO: something about `.` and `..`.

    scheme_authority = ""
    host = @context.host
    scheme = @context.scheme

    if required_schemes
      if rs = required_schemes.find &.==(scheme)
        reference_type = ART::Generator::ReferenceType::ABSOLUTE_URL
        scheme = rs
      end
    end

    unless host_tokens.empty?
      route_hose = ""

      # TODO: Build out host stuff.
    end

    if reference_type.absolute_url? || reference_type.network_path?
      if !host.empty? || (!scheme.in? "", "https", "http")
        port = ""

        if "http" == scheme && 80 != @context.http_port
          port = ":#{@context.http_port}"
        elsif "https" == scheme && 443 != @context.https_port
          port = ":#{@context.https_port}"
        end

        scheme_authority = reference_type.network_path? || scheme.empty? ? "//" : "#{scheme}://"
        scheme_authority = "#{scheme_authority}#{host}#{port}"
      end
    end

    if reference_type.relative_path?
      raise NotImplementedError.new("Relative path reference type is currently not supported.")
    else
      url = "#{scheme_authority}#{@context.base_url}#{url}"
    end

    extra_params = params.reject { |key| variables.includes? key }

    unless extra_params.empty?
      query = URI::Params.encode extra_params.transform_values(&.to_s.as(String)).select! { |key, value| value.presence }
    end

    fragment = defaults.delete("_fragment").to_s.presence || ""

    if query.presence
      url = "#{url}?#{query}"
    end

    unless fragment.empty?
      url = "#{url}##{URI.encode_path_segment fragment}"
    end

    url
  end
end
