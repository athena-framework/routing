require "./ext/*"

require "http/request"

require "./annotations"
require "./compiled_route"
require "./request_context"
require "./request_context_aware_interface"
require "./route"
require "./route_collection"
require "./route_compiler"
require "./route_provider"

require "./exception/*"
require "./generator/*"
require "./matcher/*"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

alias ARTA = ART::Annotations

module Athena::Routing
  VERSION = "0.1.0"

  {% if @top_level.has_constant? "Athena::Framework::Request" %}
    # Represents the type of the *request* parameter within an `ART::Route::Condition`.
    #
    # Will be an `ATH::Request` instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
    alias Request = Athena::Framework::Request
  {% else %}
    # Represents the type of the *request* parameter within `ART::Route::Condition`.
    #
    # Will be an `ATH::Request` instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
    alias Request = HTTP::Request
  {% end %}

  module Exception; end

  def self.compile(routes : ART::RouteCollection) : Nil
    ART::RouteProvider.compile routes
  end
end
