require "../spec_helper"

@[ASPEC::TestCase::Focus]
struct URLMatcherTest < ASPEC::TestCase
  def tear_down : Nil
    ART::RouteProvider.reset
  end

  def test_match_no_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_method_not_allowed : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "post"
    end

    ex = expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST"]
  end

  def test_match_method_not_allowed_root : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/", methods: "get"
    end

    ex = expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/"
    end

    ex.allowed_methods.should eq ["GET"]
  end

  def test_match_head_allowed_when_requirements_includes_GET : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "get"
    end

    self.get_matcher(routes, ART::RequestContext.new method: "HEAD").match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_method_not_allowed_aggregates_allowed_methods : Nil
    routes = self.build_collection do
      add "foo1", ART::Route.new "/foo", methods: "post"
      add "foo2", ART::Route.new "/foo", methods: {"PUT", "DELETE"}
    end

    ex = expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST", "PUT", "DELETE"]
  end

  def test_match_returns_matched_pattern : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    ex = expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/no-match"
    end

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "foo", "bar" => "baz"})
  end

  def test_match_defaults_are_merged : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}", {"def" => "test"}
    end

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "foo", "bar" => "baz", "def" => "test"})
  end

  def test_match_method_is_ignored_if_none_are_provided : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: {"GET", "HEAD"}
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})

    expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
    self.get_matcher(routes, ART::RequestContext.new method: "HEAD").match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_optional_variable_as_first_segment : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{bar}/foo", {"bar" => "bar"}, {"bar" => /foo|bar/}
    end

    matcher = self.get_matcher routes
    matcher.match("/bar/foo").should eq({"_route" => "bar", "bar" => "bar"})
    matcher.match("/foo/foo").should eq({"_route" => "bar", "bar" => "foo"})

    routes = self.build_collection do
      add "bar", ART::Route.new "/{bar}", {"bar" => "bar"}, {"bar" => /foo|bar/}
    end

    ART::RouteProvider.reset

    matcher = self.get_matcher routes
    matcher.match("/foo").should eq({"_route" => "bar", "bar" => "foo"})
    matcher.match("/").should eq({"_route" => "bar", "bar" => "bar"})
  end

  def test_match_only_optional_variable : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}/{bar}", {"bar" => "bar", "foo" => "foo"}
    end

    matcher = self.get_matcher routes
    matcher.match("/").should eq({"_route" => "bar", "bar" => "bar", "foo" => "foo"})
    matcher.match("/a").should eq({"_route" => "bar", "bar" => "bar", "foo" => "a"})
    matcher.match("/a/b").should eq({"_route" => "bar", "bar" => "b", "foo" => "a"})
  end

  def test_match_with_prefix : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}"
      add_prefix "/b"
      add_prefix "/a"
    end

    self.get_matcher(routes).match("/a/b/foo").should eq({"_route" => "foo", "foo" => "foo"})
  end

  def test_match_with_dynamic_prefix : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}"
      add_prefix "/b"
      add_prefix "/{_locale}"
    end

    self.get_matcher(routes).match("/de/b/foo").should eq({"_route" => "foo", "_locale" => "de", "foo" => "foo"})
  end

  def test_match_special_route_name : Nil
    routes = self.build_collection do
      add "$péß^a|", ART::Route.new "/bar"
    end

    self.get_matcher(routes).match("/bar").should eq({"_route" => "$péß^a|"})
  end

  def test_match_important_variables : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{!_format}", {"_format" => "xml"}
    end

    self.get_matcher(routes).match("/index.xml").should eq({"_route" => "index", "_format" => "xml"})
  end

  def test_match_short_path_does_not_match_important_variable : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{!_format}", {"_format" => "xml"}
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/index"
    end
  end

  def test_match_short_path_matches_non_important_variable : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{_format}", {"_format" => "xml"}
    end

    self.get_matcher(routes).match("/index.xml").should eq({"_route" => "index", "_format" => "xml"})
  end

  def test_match_trailing_encoded_new_line_is_not_overlooked : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo%0a"
    end
  end

  def test_match_non_alphanum : Nil
    chars = "!\"$%éà &'()*+,./:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ\\[]^_`abcdefghijklmnopqrstuvwxyz{|}~-"

    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/bar", requirements: {"foo" => /#{Regex.escape chars}/}
    end

    matcher = self.get_matcher routes
    matcher.match("/#{URI.encode_path_segment chars}/bar").should eq({"_route" => "foo", "foo" => chars})
    matcher.match(%(/#{chars.tr "%", "%25"}/bar)).should eq({"_route" => "foo", "foo" => chars})
  end

  def test_match_with_dot_in_requirements : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/bar", requirements: {"foo" => /.+/}
    end

    self.get_matcher(routes).match("/#{URI.encode_path_segment "\n"}/bar").should eq({"_route" => "foo", "foo" => "\n"})
  end

  def test_match_regression : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}"
      add "bar", ART::Route.new "/foo/bar/{foo}"
    end

    self.get_matcher(routes).match("/foo/bar/bar").should eq({"_route" => "bar", "foo" => "bar"})

    routes = self.build_collection do
      add "foo", ART::Route.new "/{bar}"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/"
    end
  end

  def test_multiple_params : Nil
    routes = self.build_collection do
      add "foo1", ART::Route.new "/foo/{a}/{b}"
      add "foo2", ART::Route.new "/foo/{a}/test/test/{b}"
      add "foo3", ART::Route.new "/foo/{a}/{b}/{c}/{d}"
    end

    self.get_matcher(routes).match("/foo/test/test/test/bar").should eq({"_route" => "foo2", "a" => "test", "b" => "bar"})
  end

  def test_default_requirements_for_optional_variables : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}", {"page" => "index", "_format" => "html"}
    end

    self.get_matcher(routes).match("/my-page.xml").should eq({"_route" => "test", "page" => "my-page", "_format" => "xml"})
  end

  def test_match_overridden_route : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    routes2 = self.build_collection do
      add "foo", ART::Route.new "/foo1"
    end

    routes.add routes2

    self.get_matcher(routes).match("/foo1").should eq({"_route" => "foo"})

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_matching_is_eager : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{foo}-{bar}-", requirements: {"foo" => /.+/, "bar" => ".+"}
    end

    self.get_matcher(routes).match("/text1-text2-text3-text4-").should eq({"_route" => "test", "foo" => "text1-text2-text3", "bar" => "text4"})
  end

  def test_adjacent_variables : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{w}{x}{y}{z}.{_format}", {"z" => "default-z", "_format" => "html"}, {"y" => /y|Y/}
    end

    matcher = self.get_matcher routes

    matcher.match("/wwwwwxYZ.xml").should eq({"_route" => "test", "_format" => "xml", "w" => "wwwww", "x" => "x", "y" => "Y", "z" => "Z"})
    matcher.match("/wwwwwxyZZZ").should eq({"_route" => "test", "_format" => "html", "w" => "wwwww", "x" => "x", "y" => "y", "z" => "ZZZ"})
    matcher.match("/wwwwwxy").should eq({"_route" => "test", "_format" => "html", "w" => "wwwww", "x" => "x", "y" => "y", "z" => "default-z"})

    expect_raises ART::Exceptions::ResourceNotFound do
      matcher.match "/wxy.html"
    end
  end

  def test_optional_variable_with_no_real_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/get{what}", {"what" => "All"}
    end

    matcher = self.get_matcher routes

    matcher.match("/get").should eq({"_route" => "test", "what" => "All"})
    matcher.match("/getSites").should eq({"_route" => "test", "what" => "Sites"})
  end

  def test_required_variable_with_no_real_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/get{what}Suffix"
    end

    self.get_matcher(routes).match("/getSitesSuffix").should eq({"_route" => "test", "what" => "Sites"})
  end

  def test_default_requirement_of_variable : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}"
    end

    self.get_matcher(routes).match("/index.mobile.html").should eq({"_route" => "test", "page" => "index", "_format" => "mobile.html"})
  end

  def test_default_requirement_of_variable_disallows_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/index.sl/ash"
    end
  end

  def test_default_requirement_of_variable_disallows_next_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}", requirements: {"_format" => /html|xml/}
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/do.t.html"
    end
  end

  def test_missing_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_extra_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo/"
    end
  end

  def test_missing_trailing_slash_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end
  end

  def test_extra_trailing_slash_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo/"
    end
  end

  def test_scheme_requirement : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: "https"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_scheme_requirement_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: "https"
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end
  end

  def test_same_path_with_different_scheme : Nil
    routes = self.build_collection do
      add "https_route", ART::Route.new "/", schemes: "https"
      add "http_route", ART::Route.new "/", schemes: "http"
    end

    self.get_matcher(routes).match("/").should eq({"_route" => "http_route"})
  end

  def test_condition : Nil
    routes = self.build_collection do
      route = ART::Route.new "/foo"
      route.condition do |ctx|
        "POST" == ctx.method
      end

      add "foo", route
    end

    expect_raises ART::Exceptions::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_request_condition : Nil
    routes = self.build_collection do
      route = ART::Route.new "/foo/{bar}"
      route.condition do |ctx, request|
        request.path.starts_with? "/foo"
      end

      add "foo", route

      route = ART::Route.new "/foo/{bar}"
      route.condition do |ctx, request|
        "/foo/foo" == request.path
      end

      add "bar", route
    end

    self.get_matcher(routes).match("/foo/bar").should eq({"_route" => "foo", "bar" => "bar"})
  end

  def test_decode_once : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    self.get_matcher(routes).match("/foo/bar%2523").should eq({"_route" => "foo", "bar" => "bar%23"})
  end

  def test_cannot_rely_on_prefix : Nil
    routes = self.build_collection do
      sub_routes = self.build_collection do
        add "bar", ART::Route.new "/bar"
        add_prefix "/prefix"

        get("bar").path = "/new"
      end

      add sub_routes
    end

    self.get_matcher(routes).match("/new").should eq({"_route" => "bar"})
  end

  def test_with_host : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}", host: "{locale}.example.com"
    end

    self.get_matcher(routes, ART::RequestContext.new host: "de.example.com").match("/foo/bar").should eq({"_route" => "foo", "foo" => "bar", "locale" => "de"})
  end

  def test_with_host_on_collection : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}"
      add "bar", ART::Route.new "/bar/{foo}", host: "{locale}.example.com"
      set_host "{locale}.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "en.example.com"
    matcher.match("/foo/bar").should eq({"_route" => "foo", "foo" => "bar", "locale" => "en"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "en.example.com"
    matcher.match("/bar/bar").should eq({"_route" => "bar", "foo" => "bar", "locale" => "en"})
  end

  def test_variation_in_trailing_slash_with_host : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", host: "foo.example.com"
      add "bar", ART::Route.new "/foo", host: "bar.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_variation_in_trailing_slash_with_host_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/foo", host: "bar.example.com"
      add "foo", ART::Route.new "/foo/", host: "foo.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_variation_in_trailing_slash_with_host_and_variable : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/", host: "foo.example.com"
      add "bar", ART::Route.new "/{foo}", host: "bar.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_variation_in_trailing_slash_with_host_and_variable_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}", host: "bar.example.com"
      add "foo", ART::Route.new "/{foo}/", host: "foo.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_variation_in_trailing_slash_with_host_and_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", methods: "POST"
      add "bar", ART::Route.new "/foo", methods: "GET"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_variation_in_trailing_slash_with_host_and_method_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/foo", methods: "GET"
      add "foo", ART::Route.new "/foo/", methods: "POST"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_variable_variation_in_trailing_slash_with_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/", methods: "POST"
      add "bar", ART::Route.new "/{foo}", methods: "GET"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    # pp ART::RouteProvider
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_variable_variation_in_trailing_slash_with_method_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}", methods: "GET"
      add "foo", ART::Route.new "/{foo}/", methods: "POST"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  private def build_collection(&) : ART::RouteCollection
    routes = ART::RouteCollection.new

    with routes yield

    routes
  end

  private def get_matcher(routes : ART::RouteCollection, context : ART::RequestContext = ART::RequestContext.new) : ART::Matcher::URLMatcher
    ART.compile routes
    ART::Matcher::URLMatcher.new context
  end
end
