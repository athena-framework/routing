module Athena::Routing::RouteCompiler
  private PATH_REGEX = /{(!)?(\w+)}/
  private SEPARATORS = "/,;.:-_~+*=@|"
  private MAX_LENGTH = 32

  # :nodoc:
  struct Token
    enum Type
      TEXT
      VARIABLE
    end

    getter type : Type
    getter prefix : String
    getter regex : Regex?
    getter var_name : String?
    getter regex_options : Nil
    getter important : Bool

    def initialize(
      @type : Type,
      @prefix : String,
      @regex : Regex? = nil,
      @var_name : String? = nil,
      @regex_options : Nil = nil,
      @important : Bool = false
    )
    end
  end

  private record CompiledPattern,
    static_prefix : String,
    regex : Regex,
    tokens : Array(Token),
    variables : Set(String)

  def self.compile(route : Route) : CompiledRoute
    host_variables = Set(String).new
    variables = Set(String).new
    host_regex = nil
    host_tokens = Array(Token).new

    if host = route.host.presence
      pattern = self.compile_pattern route, host, true

      variables = host_variables = pattern.variables

      host_tokens = pattern.tokens
      host_regex = pattern.regex
    end

    # TODO: Do something with _locale

    path = route.path

    pattern = self.compile_pattern route, path, false

    path_variables = pattern.variables

    raise "Cannot use _fragment in path param" if path_variables.includes? "_fragment"

    variables.concat path_variables

    CompiledRoute.new(
      pattern.static_prefix,
      pattern.regex,
      pattern.tokens,
      path_variables,
      host_regex,
      host_tokens,
      host_variables,
      variables
    )
  end

  private def self.compile_pattern(route : Route, pattern : String, is_host : Bool)
    pos = 0
    variables = Set(String).new
    tokens = Array(Token).new
    default_separator = is_host ? "." : "/"

    # Matches and iterates over all variables within `{}`.
    # match[0] => var name with {}
    # match[1] => (optional) `!` symbol
    # match[2] => var name without {}
    pattern.scan(PATH_REGEX) do |match|
      is_important = !match[1]?.nil?
      var_name = match[2]

      # Static text before the match
      preceding_text = pattern[pos, match.begin - pos]
      pos = match.begin + match[0].size

      preceding_char = preceding_text.empty? ? "" : preceding_text[-1].to_s
      is_separator = !preceding_char.empty? && SEPARATORS.includes?(preceding_char)

      raise "Can't start with digit" if var_name.starts_with? /\d/
      raise "Used more than once" unless variables.add? var_name
      raise "Too long" if var_name.size > MAX_LENGTH

      if is_separator && preceding_text != preceding_char
        tokens << Token.new :text, preceding_text[0...-preceding_char.size]
      elsif !is_separator && !preceding_text.empty?
        tokens << Token.new :text, preceding_text
      end

      if regex = route.requirements
        # TODO: Handle var specific requirements.
        regex = Regex.new ""
      else
        following_pattern = pattern[pos..]
        next_separator = self.find_next_separator following_pattern

        regex = /[^#{Regex.escape default_separator}#{default_separator != next_separator && "" != next_separator ? Regex.escape(next_separator) : ""}]+/

        if (!next_separator.empty? && !following_pattern.matches?(/^\{\w+\}/)) || following_pattern.empty?
          regex = /#{regex.source}+/
        end
      end

      tokens << if is_important
        Token.new :variable, is_separator ? preceding_char : "", regex, var_name, important: true
      else
        Token.new :variable, is_separator ? preceding_char : "", regex, var_name
      end
    end

    if pos < pattern.size
      tokens << Token.new :text, pattern[pos..]
    end

    first_optional_index = tokens.index do |token|
      token.type.variable? && !token.important && route.has_default?(token.var_name.not_nil!)
    end

    route_pattern = ""
    tokens.each_with_index do |token, idx|
      route_pattern += self.compute_regex tokens, idx, first_optional_index
    end

    route_regex = Regex.new "^#{route_pattern}$", is_host ? Regex::Options::IGNORE_CASE : Regex::Options::None

    # Crystal has UTF-8 regex mode enabled by default, so no need to add it.

    CompiledPattern.new(
      self.determine_static_prefix(route, tokens),
      route_regex,
      tokens.reverse!,
      variables
    )
  end

  private def self.determine_static_prefix(route : Route, tokens : Array(Token)) : String
    first_token = tokens.first

    unless first_token.type.text?
      return (route.has_default?(first_token.var_name.not_nil!) || "/" == first_token.prefix) ? "" : first_token.prefix
    end

    prefix = first_token.prefix

    if (second_token = tokens[1]?) && ("/" != second_token.prefix) && !route.has_default?(second_token.var_name.not_nil!)
      prefix += second_token.prefix
    end

    prefix
  end

  private def self.find_next_separator(pattern : String) : String
    return "" if pattern.empty?
    return "" if (pattern = pattern.gsub(/\{\w+\}/, "")).empty?

    SEPARATORS.includes?(pattern) ? pattern : ""
  end

  private def self.compute_regex(tokens : Array(Token), idx : Int, first_optional_index : Int?) : String
    token = tokens[idx]

    case token.type
    in .text? then Regex.escape token.prefix
    in .variable?
      if idx.zero? && 0 == first_optional_index
        "#{Regex.escape token.prefix}(?P<#{token.var_name}>#{token.regex.not_nil!.source})?"
      else
        regex = "#{Regex.escape token.prefix}(?P<#{token.var_name}>#{token.regex.not_nil!.source})"

        if first_optional_index && idx > first_optional_index
          regex = "(?:#{regex}"
          num_tokens = tokens.size

          if idx == num_tokens - 1
            regex += ")?" * (num_tokens - first_optional_index - (first_optional_index.zero? ? 1 : 0))
          end
        end

        regex
      end
    end
  end
end
