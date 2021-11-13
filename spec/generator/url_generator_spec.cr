require "../spec_helper"

@[ASPEC::TestCase::Focus]
struct URLGeneratorTest < ASPEC::TestCase
  def tear_down : Nil
    ART::RouteProvider.reset
  end

  @[DataProvider("test_absolute_url_provider")]
  def test_generate(expected : String, route : ART::Route, reference_type : ART::Generator::ReferenceType, context : ART::RequestContext?, default_locale : String?) : Nil
    self
      .generator(self.routes(route), context: context, default_locale: default_locale)
      .generate("test", reference_type: reference_type).should eq expected
  end

  @[DataProvider("query_param_provider")]
  def test_generate_extra_params(expected : String, key : String, value) : Nil
    self
      .generator(self.routes ART::Route.new "/test")
      .generate("test", {key => value}, reference_type: :absolute_url).should eq "http://localhost/base/test#{expected}"
  end

  def test_absolute_url_provider : Hash
    {
      "default port" => {
        "http://localhost/base/test",
        ART::Route.new("/test"),
        ART::Generator::ReferenceType::ABSOLUTE_URL,
        nil,
        nil,
      },
      "secure default port" => {
        "https://localhost/base/test",
        ART::Route.new("/test"),
        ART::Generator::ReferenceType::ABSOLUTE_URL,
        ART::RequestContext.new(base_url: "/base", scheme: "https"),
        nil,
      },
      "non standard port" => {
        "http://localhost:8080/base/test",
        ART::Route.new("/test"),
        ART::Generator::ReferenceType::ABSOLUTE_URL,
        ART::RequestContext.new(base_url: "/base", http_port: 8080),
        nil,
      },
      "secure non standard port" => {
        "https://localhost:8080/base/test",
        ART::Route.new("/test"),
        ART::Generator::ReferenceType::ABSOLUTE_URL,
        ART::RequestContext.new(base_url: "/base", https_port: 8080, scheme: "https"),
        nil,
      },
    }
  end

  def query_param_provider : Hash
    {
      "nil value"    => {"", "foo", nil},
      "string value" => {"?foo=bar", "foo", "bar"},
    }
  end

  def test_generate_default_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, default_locale: "hr")
      .generate(name, reference_type: :absolute_url).should eq "http://localhost/base/foo"
  end

  private def generator(routes : ART::RouteCollection, *, context : ART::RequestContext? = nil, default_locale : String? = nil) : ART::Generator::URLGenerator
    context = context || ART::RequestContext.new "/base"

    ART::Generator::URLGenerator.new context, default_locale
  end

  private def routes(route : ART::Route) : ART::RouteCollection
    routes = ART::RouteCollection.new
    routes.add "test", route

    ART.compile routes

    routes
  end
end
