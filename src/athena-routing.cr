require "http/request"

require "./compiled_route"
require "./route"
require "./route_collection"
require "./route_compiler"
require "./route_provider"

require "./matcher/*"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

module Athena::Routing
  VERSION = "0.1.0"
end

collection = ART::RouteCollection.new
collection.add "app_add", dynamic_route = Athena::Routing::Route.new "/add/{val1}/{val2}", "GET"
collection.add "app_index", static_route = Athena::Routing::Route.new "/", "GET"

# pp dynamic_route.compile

ART::RouteProvider.init collection

pp ART::RouteProvider.static_routes
pp regex = ART::RouteProvider.route_regex
pp ART::RouteProvider.dynamic_routes

pp regex.match "/add/10/20"

puts
puts
puts

matcher = ART::Matcher::URLMatcher.new

pp matcher.match "/"
pp matcher.match "/add/10/20"
