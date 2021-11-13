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

  def test_generate_overridden_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, default_locale: "hr")
      .generate(name, {"_locale" => "en"}, :absolute_url).should eq "http://localhost/base/bar"
  end

  def test_generate_overridden_via_request_context_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, context: ART::RequestContext.new(base_url: "/base").set_parameter("_locale", "en"), default_locale: "hr")
      .generate(name, reference_type: :absolute_url).should eq "http://localhost/base/bar"
  end

  def test_generate_no_routes : Nil
    generator = self.generator self.routes ART::Route.new "/test"

    expect_raises ART::Exceptions::RouteNotFound do
      generator.generate("foo", reference_type: :absolute_url)
    end
  end

  def test_generate_missing_required_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}"

    expect_raises ART::Exceptions::MissingRequiredParameters, %(Cannot generate URL for route 'test'. Missing required parameters: 'foo'.) do
      generator.generate("test", reference_type: :absolute_url)
    end
  end

  def test_generate_invalid_optional_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}

    expect_raises ART::Exceptions::InvalidParameter, "Parameter 'foo' for route 'test' must match '(?-imsx:\\d+)' (got 'bar') to generate the corresponding URL." do
      generator.generate("test", {"foo" => "bar"}, :absolute_url)
    end
  end

  def test_generate_invalid_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", requirements: {"foo" => /1|2/}

    expect_raises ART::Exceptions::InvalidParameter, "Parameter 'foo' for route 'test' must match '(?-imsx:1|2)' (got '0') to generate the corresponding URL." do
      generator.generate("test", {"foo" => "0"}, :absolute_url)
    end
  end

  def test_generate_invalid_optional_param_non_strict : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}
    generator.strict_requirements = false

    generator.generate("test", {"foo" => "bar"}, :absolute_url).should eq ""
  end

  def test_generate_invalid_param_disabled_checks : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}
    generator.strict_requirements = nil

    generator.generate("test", {"foo" => "bar"}).should eq "/base/test/bar"
  end

  def test_generate_invalid_required_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", requirements: {"foo" => /1|2/}

    expect_raises ART::Exceptions::InvalidParameter do
      generator.generate("test", {"foo" => "0"}, :absolute_url)
    end
  end

  def test_generate_host_same_as_context_absolute_url : Nil
    self
      .generator(self.routes(ART::Route.new("/{name}", host: "{locale}.example.com")), context: ART::RequestContext.new(base_url: "/base", host: "fr.example.com"))
      .generate("test", {"name" => "George", "locale" => "fr"}, reference_type: :absolute_url).should eq "http://fr.example.com/base/George"
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
