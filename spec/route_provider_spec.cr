require "./spec_helper"

struct RouteProviderTest < ASPEC::TestCase
  private COLLECTIONS = [
    ART::RouteCollection.new,
    self.default_collection,
  ]

  def tear_down : Nil
    ART::RouteProvider.reset
  end

  {% begin %}
    {% for test_case in 0..1 %}
      def test_compile_{{test_case}} : Nil
        \{% begin %}
          ART::RouteProvider.compile COLLECTIONS[{{test_case}}]

          \{% data = read_file("#{__DIR__}/fixtures/route_provider/route_collection{{test_case}}.cr").split("####") %}

          ART::RouteProvider.match_host.should eq (\{{data[0].id}})
          ART::RouteProvider.static_routes.should eq (\{{data[1].id}})
          ART::RouteProvider.route_regexes.should eq (\{{data[2].id}})
          ART::RouteProvider.dynamic_routes.should eq (\{{data[3].id}})
        \{% end %}
      end
    {% end %}
  {% end %}

  def self.default_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "overridden", ART::Route.new "/overridden"

    # Defaults and requirements
    collection.add "foo", ART::Route.new "/foo/{bar}", {"def" => "test"}, {"bar" => /baz|athenaa/}

    # Method requirement
    collection.add "bar", ART::Route.new "/bar/{foo}", methods: {"GET", "head"}

    # GET also adds HEAD as valid
    collection.add "barhead", ART::Route.new "/barhead/{foo}", methods: {"GET"}

    # Simple
    collection.add "baz", ART::Route.new "/test/baz"

    # Simple with extension
    collection.add "baz2", ART::Route.new "/test/baz.html"

    # Trailing slash
    collection.add "baz3", ART::Route.new "/test/baz3/"

    # Trailing slash with variable
    collection.add "baz4", ART::Route.new "/test/{foo}/"

    # Trailing slash and method
    collection.add "baz5", ART::Route.new "/test/{foo}/", methods: "post"

    # Complex name
    collection.add "baz.baz6", ART::Route.new "/test/{foo}/", methods: "put"

    # Defaults without variable
    collection.add "foofoo", ART::Route.new "/foofoo", {"def" => "test"}

    # Pattern with quotes
    collection.add "quoter", ART::Route.new "/{quoter}", requirements: {"quoter" => /[']+/}

    # Space in pattern
    collection.add "space", ART::Route.new "/spa ce"

    # Prefixes
    collection1 = ART::RouteCollection.new
    collection1.add "overridden", ART::Route.new "/overridden1"
    collection1.add "foo1", ART::Route.new("/{foo}").methods=("PUT")
    collection1.add "bar1", ART::Route.new "/{bar}"
    collection1.add_prefix "/b\"b"
    collection2 = ART::RouteCollection.new
    collection2.add collection1
    collection2.add "overridden", ART::Route.new "/{var}", requirements: {"var" => /.*/}
    collection1 = ART::RouteCollection.new
    collection1.add "foo2", ART::Route.new "/{foo1}"
    collection1.add "bar2", ART::Route.new "/{bar1}"
    collection1.add_prefix "/b\"b"
    collection2.add collection1
    collection2.add_prefix "/a"
    collection.add collection2

    # Overridden through add (collection) and multiple sub-collections with no own prefix
    collection1 = ART::RouteCollection.new
    collection1.add "overridden2", ART::Route.new "/old"
    collection1.add "helloWorld", ART::Route.new "/hello/{who}", {"who" => "World!"}
    collection2 = ART::RouteCollection.new
    collection3 = ART::RouteCollection.new
    collection3.add "overridden2", ART::Route.new "/new"
    collection3.add "hey", ART::Route.new "/hey/"
    collection2.add collection3
    collection1.add collection2
    collection1.add_prefix "/multi"
    collection.add collection1

    # "dynamic" prefix"
    collection1 = ART::RouteCollection.new
    collection1.add "foo3", ART::Route.new "/{foo}"
    collection1.add "bar3", ART::Route.new "/{bar}"
    collection1.add_prefix "/b"
    collection1.add_prefix "{_locale}"
    collection.add collection1

    # Route between collections
    collection.add "ababa", ART::Route.new "/ababa"

    # Collection with static prefix but only one route"
    collection1 = ART::RouteCollection.new
    collection1.add "foo4", ART::Route.new "/{foo}"
    collection1.add_prefix "/aba"
    collection.add collection1

    # Prefix and host
    collection1 = ART::RouteCollection.new
    collection1.add "route1", ART::Route.new "/route1", host: "a.example.com"
    collection1.add "route2", ART::Route.new "/c2/route2", host: "a.example.com"
    collection1.add "route3", ART::Route.new "/c2/route3", host: "b.example.com"
    collection1.add "route4", ART::Route.new "/route4", host: "a.example.com"
    collection1.add "route5", ART::Route.new "/route5", host: "c.example.com"
    collection1.add "route6", ART::Route.new "/route6", host: nil
    collection.add collection1

    # Host and variables
    collection1 = ART::RouteCollection.new
    collection1.add "route11", ART::Route.new "/route11", host: "{var1}.example.com"
    collection1.add "route12", ART::Route.new "/route12", {"var1" => "val"}, host: "{var1}.example.com"
    collection1.add "route13", ART::Route.new "/route13/{name}", host: "{var1}.example.com"
    collection1.add "route14", ART::Route.new "/route14/{name}", {"var1" => "val"}, host: "{var1}.example.com"
    collection1.add "route15", ART::Route.new "/route15/{name}", host: "c.example.com"
    collection1.add "route16", ART::Route.new "/route16/{name}", {"var1" => "val"}, host: nil
    collection1.add "route17", ART::Route.new "/route17", host: nil
    collection.add collection1

    # Multiple sub-collections with a single route and prefix each
    collection1 = ART::RouteCollection.new
    collection1.add "a", ART::Route.new "/a..."
    collection2 = ART::RouteCollection.new
    collection2.add "b", ART::Route.new "/{var}"
    collection3 = ART::RouteCollection.new
    collection3.add "c", ART::Route.new "/{var}"
    collection3.add_prefix "/c"
    collection2.add collection3
    collection2.add_prefix "/b"
    collection1.add collection2
    collection1.add_prefix "/a"
    collection.add collection1

    collection
  end
end
