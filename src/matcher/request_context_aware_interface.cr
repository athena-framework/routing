module Athena::Routing::RequestContextAwareInterface
  abstract def context : ART::RequestContext
  abstract def context=(context : ART::RequestContext)
end
