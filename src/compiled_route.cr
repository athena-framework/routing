struct Athena::Routing::CompiledRoute
  getter static_prefix : String
  getter pattern : String
  getter tokens : Array(ART::RouteCompiler::Token)
  getter path_variables : Set(String)
  getter host_pattern : String?
  getter host_tokens : Array(ART::RouteCompiler::Token)
  getter host_variables : Set(String)
  getter variables : Set(String)

  getter regex : Regex
  getter host_regex : Regex?

  def initialize(
    @static_prefix : String,
    @pattern : String,
    @tokens : Array(ART::RouteCompiler::Token),
    @path_variables : Set(String),
    @host_pattern : String? = nil,
    @host_tokens : Array(ART::RouteCompiler::Token) = Array(ART::RouteCompiler::Token).new,
    @host_variables : Set(String) = Set(String).new,
    @variables : Set(String) = Set(String).new
  )
    @regex = Regex.new @pattern
    @host_pattern.try { |pattern| @host_regex = Regex.new pattern }
  end
end
