require "../spec_helper"

struct URLMatcherTest < ASPEC::TestCase
  def tear_down : Nil
    ART::RouteProvider.reset
  end

  def test_no_method : Nil
    routes = ART::RouteCollection.new
    routes.add "foo", ART::Route.new "/foo"

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
  end

  def test_method_not_allowed : Nil
    routes = ART::RouteCollection.new
    routes.add "foo", ART::Route.new "/foo", methods: "post"

    ex = expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST"]
  end

  def test_method_not_allowed_root : Nil
    routes = ART::RouteCollection.new
    routes.add "foo", ART::Route.new "/", methods: "GET"

    ex = expect_raises ART::Exceptions::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST"]
  end

  private def get_matcher(routes : ART::RouteCollection) : ART::Matcher::URLMatcher
    ART.compile routes
    ART::Matcher::URLMatcher.new
  end
end
