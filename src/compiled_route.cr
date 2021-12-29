struct Athena::Routing::CompiledRoute
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
    getter? important : Bool

    def initialize(
      @type : Type,
      @prefix : String,
      @regex : Regex? = nil,
      @var_name : String? = nil,
      @regex_options : Nil = nil,
      @important : Bool = false
    )
    end

    def_clone
  end

  getter static_prefix : String
  getter regex : Regex
  getter tokens : Array(ART::CompiledRoute::Token)
  getter path_variables : Set(String)
  getter host_regex : Regex?
  getter host_tokens : Array(ART::CompiledRoute::Token)
  getter host_variables : Set(String)
  getter variables : Set(String)

  getter regex : Regex
  getter host_regex : Regex?

  def initialize(
    @static_prefix : String,
    @regex : Regex,
    @tokens : Array(ART::CompiledRoute::Token),
    @path_variables : Set(String),
    @host_regex : Regex? = nil,
    @host_tokens : Array(ART::CompiledRoute::Token) = Array(ART::CompiledRoute::Token).new,
    @host_variables : Set(String) = Set(String).new,
    @variables : Set(String) = Set(String).new
  )
  end

  def_clone
end
