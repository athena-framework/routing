record Athena::Routing::CompiledRoute,
  static_prefix : String,
  regex : Regex,
  tokens : Array(ART::RouteCompiler::Token),
  path_variables : Set(String),
  host_regex : Regex? = nil,
  host_tokens : Array(ART::RouteCompiler::Token) = Array(ART::RouteCompiler::Token).new,
  host_variables : Set(String) = Set(String).new,
  variables : Set(String) = Set(String).new
