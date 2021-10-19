require "./ext/*"

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

athena_routes = ART::RouteCollection.new
athena_routes.add "root", ART::Route.new "/get", "GET"
# athena_routes.add "alphabet", ART::Route.new "/get/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z", "GET"
# athena_routes.add "book_chapters", ART::Route.new "/get/books/{id}/chapters", "GET"
athena_routes.add "variable_alphabet", ART::Route.new "/get/var/{b}/{c}/{d}/{e}/{f}/{g}/{h}/{i}/{j}/{k}/{l}/{m}/{n}/{o}/{p}/{q}/{r}/{s}/{t}/{u}/{v}/{w}/{x}/{y}/{z}", "GET"

# # # pp dynamic_route.compile

ART::RouteProvider.init athena_routes

# LibGC.set_warn_proc ->(_msg, _v) { raise "wtf" }
# # pp ART::RouteProvider.static_routes
pp regex = ART::RouteProvider.route_regex
# # pp ART::RouteProvider.dynamic_routes
# # pp regex.match "/add/10/20"

# # puts
# # puts
# # puts

# matcher = ART::Matcher::URLMatcher.new

# pp matcher.match "/get/books/24/chapters"
# pp matcher.match "/get/var/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6"
