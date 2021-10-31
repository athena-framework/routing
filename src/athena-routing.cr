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
# athena_routes.add "alphabet2", ART::Route.new "/get/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/2", "GET"
# athena_routes.add "book_chapters", ART::Route.new "/get/books/{id}/chapters", "GET"
# athena_routes.add "variable_alphabet", ART::Route.new "/get/var/{b}/{c}/{d}/{e}/{f}/{g}/{h}/{i}/{j}/{k}/{l}/{m}/{n}/{o}/{p}/{q}/{r}/{s}/{t}/{u}/{v}/{w}/{x}/{y}/{z}", "GET"

# # # pp dynamic_route.compile

1000.times do |idx|
  hash = Random::DEFAULT.hex 3
  athena_routes.add "Route#{idx}", ART::Route.new "/#{hash}/{a}/{b}/{c}/#{hash}", "GET"
end

ART::RouteProvider.compile athena_routes

# LibGC.set_warn_proc ->(_msg, _v) { raise "wtf" }
# # pp ART::RouteProvider.static_routes
regex = ART::RouteProvider.route_regexes
pp regex.keys
# pp ART::RouteProvider.dynamic_routes
# puts regex.match "/add/10/20"
# # puts
# # puts
# # puts

# matcher = ART::Matcher::URLMatcher.new

# pp matcher.match "/get/books/24/chapters"
# pp matcher.match "/get/var/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6"
