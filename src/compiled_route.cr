struct Athena::Routing::CompiledRoute
  getter static_prefix : String
  getter regex : Regex
  getter tokens : Array(ART::RouteCompiler::Token)
  getter path_variables : Set(String)
  getter host_regex : Regex?
  getter host_tokens : Array(ART::RouteCompiler::Token)
  getter host_variables : Set(String)
  getter variables : Set(String)

  getter regex : Regex
  getter host_regex : Regex?

  def initialize(
    @static_prefix : String,
    @regex : Regex,
    @tokens : Array(ART::RouteCompiler::Token),
    @path_variables : Set(String),
    @host_regex : Regex? = nil,
    @host_tokens : Array(ART::RouteCompiler::Token) = Array(ART::RouteCompiler::Token).new,
    @host_variables : Set(String) = Set(String).new,
    @variables : Set(String) = Set(String).new
  )
  end

  def_clone
end
