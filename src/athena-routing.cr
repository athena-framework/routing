require "./ext/*"

require "http/request"

require "./compiled_route"
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

  def self.compile(routes : ART::RouteCollection) : Nil
    ART::RouteProvider.compile routes
  end
end

# pp ART::Route.new("/{foo}/{!bar}").set_default("bar", "<>").set_default("foo", "\\").set_requirement("bar", /\\/).set_requirement("foo", ".")
# pp ART::Route.new("/{foo<.>?\\}/{!bar<\\>?<>}")

# pp ART::Route.new("/foo/{bar?}", Hash(String, String?){"bar" => "baz"})
# route = ART::Route.new "/get/books/{id?14}"
# route.set_requirement "id", /\A\d+\z/
# pp route

# routes = ART::RouteCollection.new

# routes.add "root", ART::Route.new "/get"
# routes.add "alphabet", ART::Route.new "/get/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z"
# routes.add "book_chapters", route = ART::Route.new("/get/books/{id}/chapters").requirements=({"id" => /\d+/})
# routes.add "variable_alphabet", ART::Route.new "/get/var/{b}/{c}/{d}/{e}/{f}/{g}/{h}/{i}/{j}/{k}/{l}/{m}/{n}/{o}/{p}/{q}/{r}/{s}/{t}/{u}/{v}/{w}/{x}/{y}/{z}"

# ART.compile routes

# pp ART::RouteProvider

# collection1 = ART::RouteCollection.new
# collection1.add "route11", ART::Route.new "/route11", host: "{var1}.example.com"
# collection1.add "route12", ART::Route.new "/route12", {"var1" => "val"}, host: "{var1}.example.com"
# collection1.add "route13", ART::Route.new "/route13/{name}", host: "{var1}.example.com"
# collection1.add "route14", ART::Route.new "/route14/{name}", {"var1" => "val"}, host: "{var1}.example.com"
# collection1.add "route15", ART::Route.new "/route15/{name}", host: "c.example.com"
# collection1.add "route16", ART::Route.new "/route16/{name}", {"var1" => "val"}, host: nil
# collection1.add "route17", ART::Route.new "/route17", host: nil

# ART.compile collection1

# pp ART::RouteProvider
