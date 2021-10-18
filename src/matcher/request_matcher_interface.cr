module Athena::Routing::Matcher::RequestMatcherInterface
  abstract def match(request : HTTP::Request) : Hash(String, String?)
end
