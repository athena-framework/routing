require "http/request"

require "./compiled_route"
require "./route"
require "./route_collection"
require "./route_compiler"
require "./route_provider"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

module Athena::Routing
  VERSION = "0.1.0"
end

collection = ART::RouteCollection.new
collection.add "app_add", Athena::Routing::Route.new "/add/{val1}/{val2}", "GET"
collection.add "app_index", Athena::Routing::Route.new "/", "GET"

provider = ART::RouteProvider.new collection

pp provider.static_routes
