require "./routing_exception"

class Athena::Routing::Exceptions::MethodNotAllowed < Athena::Routing::Exceptions::RoutingException
  getter allowed_methods : Array(String)

  def initialize(allowed_methods : Enumerable(String), message : String? = nil, cause : ::Exception? = nil)
    @allowed_methods = allowed_methods.map &.upcase
    super message, cause
  end
end
