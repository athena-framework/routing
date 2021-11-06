require "./ext/*"

require "http/request"

require "./compiled_route"
require "./request_context"
require "./route"
require "./route_collection"
require "./route_compiler"
require "./route_provider"

require "./exceptions/*"
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

  def self.compile(routes : ART::RouteCollection) : Nil
    ART::RouteProvider.compile routes
  end
end

collection = ART::RouteCollection.new

collection.add "a", ART::Route.new "/admin/post"
collection.add "b", ART::Route.new "/admin/post/new"
collection.add "c", ART::Route.new "/admin/post/{id}", requirements: {"id" => /\d+/}
collection.add "d", ART::Route.new "/admin/post/{id}/edit", requirements: {"id" => /\d+/}
collection.add "e", ART::Route.new "/admin/post/{id}/delete", requirements: {"id" => /\d+/}

collection.add "f", ART::Route.new "/blog/"
collection.add "g", ART::Route.new "/blog/rss.xml"
collection.add "h", ART::Route.new "/blog/page/{page}", requirements: {"id" => /\d+/}
collection.add "i", ART::Route.new "/blog/posts/{page}", requirements: {"page" => /\d+/}
collection.add "j", ART::Route.new "/blog/comments/{id}/new", requirements: {"id" => /\d+/}

collection.add "k", ART::Route.new "/blog/search"
collection.add "l", ART::Route.new "/login"
collection.add "m", ART::Route.new "/logout"

ART.compile collection

matcher = ART::Matcher::URLMatcher.new ART::RequestContext.new

request = HTTP::Request.new "GET", "/admin/post/10"

pp matcher.match request
