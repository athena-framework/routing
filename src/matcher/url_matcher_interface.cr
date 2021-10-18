module Athena::Routing::Matcher::URLMatcherInterface
  abstract def match(path : String) : Hash(String, String?)
end
