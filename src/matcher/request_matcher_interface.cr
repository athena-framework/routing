module Athena::Routing::Matcher::RequestMatcherInterface
  abstract def match(request : ART::Request) : Hash(String, String?)
end
