require "../spec_helper"

@[ASPEC::TestCase::Focus]
struct URLGeneratorTest < ASPEC::TestCase
  def tear_down : Nil
    ART::RouteProvider.reset
  end

  def test_generate_default_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")))
      .generate("test", reference_type: :absolute_url).should eq "http://localhost/base/test"
  end

  def test_generate_secure_default_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", scheme: "https"))
      .generate("test", reference_type: :absolute_url).should eq "https://localhost/base/test"
  end

  def test_generate_non_standard_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", http_port: 8080))
      .generate("test", reference_type: :absolute_url).should eq "http://localhost:8080/base/test"
  end

  def test_generate_secure_non_standard_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", scheme: "https", https_port: 8080))
      .generate("test", reference_type: :absolute_url).should eq "https://localhost:8080/base/test"
  end

  def test_generate_no_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/test")))
      .generate("test").should eq "/base/test"
  end

  def test_generate_with_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{foo}")))
      .generate("test", {"foo" => "bar"}).should eq "/base/test/bar"
  end

  def test_generate_nil_parameter : Nil
    self
      .generator(self.routes(ART::Route.new("/test.{format}", {"format" => nil})))
      .generate("test").should eq "/base/test"
  end

  def test_generate_nil_parameter_required : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}/bar", {"foo" => nil}

    expect_raises ART::Exceptions::InvalidParameter do
      generator.generate "test"
    end
  end

  def test_generate_not_passed_optional_parameter_in_between : Nil
    generator = self.generator self.routes ART::Route.new "/{slug}/{page}", {"slug" => "index", "page" => "0"}

    generator.generate("test", {"page" => 1}).should eq "/base/index/1"
    generator.generate("test").should eq "/base/"
  end

  @[DataProvider("query_param_provider")]
  def test_generate_extra_params(expected : String, key : String, value) : Nil
    self
      .generator(self.routes ART::Route.new "/test")
      .generate("test", {key => value}, reference_type: :absolute_url).should eq "http://localhost/base/test#{expected}"
  end

  def query_param_provider : Hash
    {
      "nil value"    => {"", "foo", nil},
      "string value" => {"?foo=bar", "foo", "bar"},
    }
  end

  def test_generate_extra_param_from_globals : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base").set_parameter("bar", "bar"))
      .generate("test", {"foo" => "bar"}).should eq "/base/test?foo=bar"
  end

  def test_generate_param_from_globals : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{foo}")), context: ART::RequestContext.new(base_url: "/base").set_parameter("foo", "bar"))
      .generate("test").should eq "/base/test/bar"
  end

  def test_generate_param_from_globals_overrides_defaults : Nil
    self
      .generator(self.routes(ART::Route.new("/{_locale}", {"_locale" => "en"})), context: ART::RequestContext.new(base_url: "/base").set_parameter("_locale", "de"))
      .generate("test").should eq "/base/de"
  end

  def test_generate_localized_routes_preserve_the_good_locale_in_url : Nil
    routes = ART::RouteCollection.new

    routes.add "foo.en", ART::Route.new "/{_locale}/fork", {"_locale" => "en", "_canonical_route" => "foo"}, {"_locale" => /en/}
    routes.add "foo.fr", ART::Route.new "/{_locale}/fourchette", {"_locale" => "fr", "_canonical_route" => "foo"}, {"_locale" => /fr/}
    routes.add "fun.en", ART::Route.new "/fun", {"_locale" => "en", "_canonical_route" => "fun"}, {"_locale" => /en/}
    routes.add "fun.fr", ART::Route.new "/amusant", {"_locale" => "fr", "_canonical_route" => "fun"}, {"_locale" => /fr/}

    ART.compile routes

    generator = self.generator routes
    generator.context.set_parameter "_locale", "fr"

    generator.generate("foo").should eq "/base/fr/fourchette"
    generator.generate("foo.en").should eq "/base/en/fork"
    generator.generate("foo", {"_locale" => "en"}).should eq "/base/en/fork"
    generator.generate("foo.fr", {"_locale" => "en"}).should eq "/base/fr/fourchette"

    generator.generate("fun").should eq "/base/amusant"
    generator.generate("fun.en").should eq "/base/fun"
    generator.generate("fun", {"_locale" => "en"}).should eq "/base/fun"
    generator.generate("fun.fr", {"_locale" => "en"}).should eq "/base/amusant"
  end

  def test_generate_invalid_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    generator = self.generator routes, default_locale: "fr"

    expect_raises ART::Exceptions::RouteNotFound do
      generator.generate name
    end
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

  def test_generate_required_param_empty_string : Nil
    generator = self.generator self.routes ART::Route.new "/{slug}", requirements: {"slug" => /.+/}

    expect_raises ART::Exceptions::InvalidParameter do
      generator.generate "test", {"slug" => ""}
    end
  end

  def test_generate_scheme_requirement_does_nothing_if_same_as_current_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "http")), context: ART::RequestContext.new base_url: "/base", scheme: "http")
      .generate("test").should eq "/base/"
  end

  def test_generate_scheme_requirement_does_nothing_if_same_as_current_scheme_secure : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "https")), context: ART::RequestContext.new base_url: "/base", scheme: "https")
      .generate("test").should eq "/base/"
  end

  def test_generate_scheme_requirement_forces_absolute_url : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "http")), context: ART::RequestContext.new base_url: "/base", scheme: "https")
      .generate("test").should eq "http://localhost/base/"
  end

  def test_generate_scheme_requirement_forces_absolute_url_secure : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "https")))
      .generate("test").should eq "https://localhost/base/"
  end

  def test_generate_scheme_requirement_creates_url_for_first_required_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: {"Ftp", "https"})))
      .generate("test").should eq "ftp://localhost/base/"
  end

  def test_generate_scheme_requirement_creates_url_for_first_required_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("//path-and-not-domain")), context: ART::RequestContext.new)
      .generate("test").should eq "/path-and-not-domain"
  end

  def test_generate_no_trailing_slash_for_multiple_optional_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/category/{slug1}/{slug2}/{slug3}", {"slug2" => nil, "slug3" => nil})))
      .generate("test", {"slug1" => "foo"}).should eq "/base/category/foo"
  end

  def test_generate_nil_for_optional_parameter_is_ignored : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{default}", {"default" => "0"})))
      .generate("test", {"default" => nil}).should eq "/base/test"
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
