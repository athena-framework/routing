require "./ext/*"

require "http/request"

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

module Athena::Routing
  VERSION = "0.1.0"

  {% if @top_level.has_constant? "Athena::Framework::Request" %}
    alias Request = Athena::Framework::Request
  {% else %}
    alias Request = HTTP::Request
  {% end %}

  module Exception; end

  def self.compile(routes : ART::RouteCollection) : Nil
    ART::RouteProvider.compile routes
  end
end
