# TODO: How to store a reference to the "Controller"
# in quotes because it technically doesn't need to be an ART::Controller.
class Athena::Routing::Route
  getter path : String
  getter defaults : Hash(String, String?) = Hash(String, String?).new
  getter requirements : Hash(String, Regex) = Hash(String, Regex).new
  getter host : String?
  getter methods : Set(String)?
  getter schemas : Set(String)? = nil

  # TODO: Don't think we actually know what this is:
  # getter condition_key : String? = nil
  # getter condition : Proc(HTTP::Request, Bool)? = nil

  @compiled_route : ART::CompiledRoute? = nil

  def initialize(
    @path : String,
    defaults : Hash(String, String?) = Hash(String, String?).new,
    requirements : Hash(String, Regex | String) = Hash(String, Regex | String).new,
    @host : String? = nil,
    methods : String | Enumerable(String)? = nil,
    schemas : String | Enumerable(String)? = nil
  )
    self.path = @path
    self.add_defaults defaults
    self.add_requirements requirements
    self.methods = methods unless methods.nil?
    self.schemas = schemas unless schemas.nil?
  end

  def_equals @path, @defaults, @requirements, @host, @methods, @schemas

  def host=(pattern : String | Regex) : self
    @host = self.extract_inline_defaults_and_requirements pattern
    @compiled_route = nil

    self
  end

  def path=(pattern : String) : self
    pattern = self.extract_inline_defaults_and_requirements pattern
    @path = "/#{pattern.strip.lstrip '/'}"
    @compiled_route = nil

    self
  end

  def schemas=(schemas : String | Enumerable(String)) : self
    schemas = schemas.is_a?(String) ? {schemas} : schemas
    @schemas ||= Set(String).new
    schemas.each { |s| @schemas.not_nil! << s.downcase }

    @compiled_route = nil

    self
  end

  def methods=(methods : String | Enumerable(String)) : self
    methods = methods.is_a?(String) ? {methods} : methods
    @methods ||= Set(String).new
    methods.each { |m| @methods.not_nil! << m.upcase }

    @compiled_route = nil

    self
  end

  def compile : CompiledRoute
    @compiled_route ||= ART::RouteCompiler.compile self
  end

  def has_default(key : String) : Bool
    @defaults.has_key? key
  end

  def default(key : String) : String?
    @defaults[key]?
  end

  def defaults=(defaults : Hash(String, String?)) : self
    @defaults.clear

    self.add_defaults defaults
  end

  def add_defaults(defaults : Hash(String, String?)) : self
    if defaults.has_key?("_locale") && self.localized?
      defaults.delete "_locale"
    end

    defaults.each do |key, value|
      @defaults[key] = value
    end

    @compiled_route = nil

    self
  end

  def set_default(key : String, value : String?) : self
    if "_locale" == key && self.localized?
      return self
    end

    @defaults[key] = value
    @compiled_route = nil

    self
  end

  def has_requirement(key : String) : Bool
    @requirements.has_key? key
  end

  def requirement(key : String) : Regex?
    @requirements[key]?
  end

  def requirements=(requirements : Hash(String, Regex | String)) : self
    @requirements.clear

    self.add_requirements requirements
  end

  def add_requirements(requirements : Hash(String, Regex | String)) : self
    if requirements.has_key?("_locale") && self.localized?
      requirements.delete "_locale"
    end

    requirements.each do |key, regex|
      @requirements[key] = self.sanitize_requirement key, regex
    end

    @compiled_route = nil

    self
  end

  def set_requirement(key : String, requirement : Regex | String) : self
    if "_locale" == key && self.localized?
      return self
    end

    @requirements[key] = self.sanitize_requirement key, requirement

    @compiled_route = nil

    self
  end

  def has_default?(name : String) : Bool
    !!@defaults.try &.has_key?(name)
  end

  private def extract_inline_defaults_and_requirements(pattern : String) : String
    return pattern if !pattern.includes?('?') && !pattern.includes?('<')

    pattern.gsub /\{(!?)(\w++)(<.*?>)?(\?[^\}]*+)?\}/ do |_, match|
      if requirement = match[3]?.presence
        self.set_requirement match[2], requirement[1...-1]
      end

      if default = match[4]?.presence
        self.set_default match[2], "?" != match[4] ? match[4][1..] : nil
      end

      "{#{match[1]}#{match[2]}}"
    end
  end

  private def sanitize_requirement(key : String, pattern : Regex) : Regex
    self.sanitize_requirement key, pattern.source
  end

  private def sanitize_requirement(key : String, pattern : String) : Regex
    unless pattern.empty?
      if p = pattern.lchop? '^'
        pattern = p
      elsif p = pattern.lchop? "\\A"
        pattern = p
      end
    end

    if p = pattern.rchop? '$'
      pattern = p
    elsif p = pattern.rchop? "\\z"
      pattern = p
    end

    pattern = "\\\\" if pattern == "\\"

    raise ArgumentError.new "Routing requirement for '#{key}' cannot be empty." if pattern.empty?

    Regex.new pattern
  end

  private def localized? : Bool
    return false unless (locale = @defaults["_locale"]?)
    @defaults.has_key?("_canonical_route") && self.requirement("_locale").try &.source == Regex.escape(locale)
  end
end
