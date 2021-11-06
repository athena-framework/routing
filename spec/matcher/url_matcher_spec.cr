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
