module Athena::Routing::Matcher::URLMatcherInterface
  include Athena::Routing::RequestContextAwareInterface

  abstract def match(path : String) : Hash(String, String?)
end
