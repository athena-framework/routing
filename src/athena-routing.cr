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

# pp ART::Route.new("/{foo}/{!bar}").set_default("bar", "<>").set_default("foo", "\\").set_requirement("bar", /\\/).set_requirement("foo", ".")
# pp ART::Route.new("/{foo<.>?\\}/{!bar<\\>?<>}")

# pp ART::Route.new("/foo/{bar?}", Hash(String, String?){"bar" => "baz"})
# route = ART::Route.new "/get/books/{id?14}"
# route.set_requirement "id", /\A\d+\z/
# pp route

# athena_routes = ART::RouteCollection.new
# athena_routes.add "root", route

# ART::RouteProvider.compile athena_routes

# pp ART::RouteProvider.static_routes

# athena_routes.add "root", ART::Route.new "/get"
# athena_routes.add "alphabet", ART::Route.new "/get/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z", "GET"
# athena_routes.add "alphabet2", ART::Route.new "/get/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/2", "GET"
# athena_routes.add "book_chapters", route = ART::Route.new("/get/books/{id}/chapters").requirements=({"id" => /\d+/})
# athena_routes.add "variable_alphabet", ART::Route.new "/get/var/{b}/{c}/{d}/{e}/{f}/{g}/{h}/{i}/{j}/{k}/{l}/{m}/{n}/{o}/{p}/{q}/{r}/{s}/{t}/{u}/{v}/{w}/{x}/{y}/{z}", "GET"

# pp route.compile

# # # pp dynamic_route.compile

# require "digest"

# 1000.times do |idx|
#   hash = Digest::MD5.hexdigest(idx.to_s)[0...6]
#   athena_routes.add "Route#{idx}", ART::Route.new "/#{hash}/{a}/{b}/{c}/#{hash}", "GET"
# end

# ART::RouteProvider.compile athena_routes

# pp ART::RouteProvider

# LibGC.set_warn_proc ->(_msg, _v) { raise "wtf" }
# # pp ART::RouteProvider.static_routes
# regex = ART::RouteProvider.route_regexes
# pp regex
# dynamic_routes = ART::RouteProvider.dynamic_routes
# pp dynamic_routes
# pp dynamic_routes[regex.values.last.match("/get/books/5/chapters").not_nil!.mark.not_nil!.to_i]
# # puts
# # puts
# # puts

# matcher = ART::Matcher::URLMatcher.new

# pp matcher.match "/get/books/24"
# pp matcher.match "/get/books"
# pp matcher.match "/get/var/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6"
# ^(?|/get/books/([^/]++)(*:26))/?$
# ^(?|/get/books(?:/([^/]++))?(*:31))/?$

# FORMATTER BUG:
# ART::Route.new("/").host=("{bar}").set_default("bar", nil)
