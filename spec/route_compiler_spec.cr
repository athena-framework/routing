require "./spec_helper"

struct RouteCompilerTest < ASPEC::TestCase
  @[DataProvider("compiler_provider")]
  @[Focus]
  def test_compile(route : ART::Route, prefix : String, regex : Regex, variables : Set(String), tokens : Array(ART::RouteCompiler::Token)) : Nil
    compiled_route = route.compile
    compiled_route.static_prefix.should eq prefix
    compiled_route.regex.should eq regex
    compiled_route.variables.should eq variables
    compiled_route.tokens.should eq tokens
  end

  def compiler_provider : Hash
    {
      "static" => {
        ART::Route.new("/foo"),
        "/foo",
        /^\/foo$/,
        Set(String).new,
        [
          ART::RouteCompiler::Token.new(:text, "/foo"),
        ],
      },
      "single variable" => {
        ART::Route.new("/foo/{bar}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)$/,
        Set{"bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),

        ],
      },
      "variable with default value" => {
        ART::Route.new("/foo/{bar}", {"bar" => "bar"}),
        "/foo",
        /^\/foo(?:\/(?P<bar>[^\/]++))?$/,
        Set{"bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),

        ],
      },
      "several variable" => {
        ART::Route.new("/foo/{bar}/{foobar}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)\/(?P<foobar>[^\/]++)$/,
        Set{"bar", "foobar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),

        ],
      },
      "several variables with defaults" => {
        ART::Route.new("/foo/{bar}/{foobar}", {"bar" => "bar", "foobar" => ""}),
        "/foo",
        /^\/foo(?:\/(?P<bar>[^\/]++)(?:\/(?P<foobar>[^\/]++))?)?$/,
        Set{"bar", "foobar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),

        ],
      },
      "several variables with some having defaults" => {
        ART::Route.new("/foo/{bar}/{foobar}", {"bar" => "bar"}),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)\/(?P<foobar>[^\/]++)$/,
        Set{"bar", "foobar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),

        ],
      },
      "optional variable as the first segment with default" => {
        ART::Route.new("/{bar}", {"bar" => "bar"}),
        "",
        /^\/(?P<bar>[^\/]++)?$/,
        Set{"bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
        ],
      },
      "optional variable as the first segment with requirement" => {
        ART::Route.new("/{bar}", {"bar" => "bar"}, {"bar" => /(foo|bar)/}),
        "",
        /^\/(?P<bar>(?:foo|bar))?$/,
        Set{"bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /(?:foo|bar)/, "bar"),
        ],
      },
      "only optional variables with defaults" => {
        ART::Route.new("/{foo}/{bar}", {"foo" => "foo", "bar" => "bar"}),
        "",
        /^\/(?P<foo>[^\/]++)?(?:\/(?P<bar>[^\/]++))?$/,
        Set{"foo", "bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/]++/, "foo"),
        ],
      },
      "variable in last position" => {
        ART::Route.new("/foo-{bar}"),
        "/foo-",
        /^\/foo\-(?P<bar>[^\/]++)$/,
        Set{"bar"},
        [
          ART::RouteCompiler::Token.new(:variable, "-", /[^\/]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),
        ],
      },
      "nested placeholders" => {
        ART::Route.new("/{static{var}static}"),
        "/{static",
        /^\/\{static(?P<var>[^\/]+)static\}$/,
        Set{"var"},
        [
          ART::RouteCompiler::Token.new(:text, "static}"),
          ART::RouteCompiler::Token.new(:variable, "", /[^\/]+/, "var"),
          ART::RouteCompiler::Token.new(:text, "/{static"),
        ],
      },
      "separator between variables" => {
        ART::Route.new("/{w}{x}{y}{z}.{_format}", {"z" => "default-z", "_format" => "html"}, {"y" => /(y|Y)/}),
        "",
        /^\/(?P<w>[^\/\.]+)(?P<x>[^\/\.]+)(?P<y>(?:y|Y))(?:(?P<z>[^\/\.]++)(?:\.(?P<_format>[^\/]++))?)?$/,
        Set{"w", "x", "y", "z", "_format"},
        [
          ART::RouteCompiler::Token.new(:variable, ".", /[^\/]++/, "_format"),
          ART::RouteCompiler::Token.new(:variable, "", /[^\/\.]++/, "z"),
          ART::RouteCompiler::Token.new(:variable, "", /(?:y|Y)/, "y"),
          ART::RouteCompiler::Token.new(:variable, "", /[^\/\.]+/, "x"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/\.]+/, "w"),
        ],
      },
      "with format" => {
        ART::Route.new("/foo/{bar}.{_format}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/\.]++)\.(?P<_format>[^\/]++)$/,
        Set{"bar", "_format"},
        [
          ART::RouteCompiler::Token.new(:variable, ".", /[^\/]++/, "_format"),
          ART::RouteCompiler::Token.new(:variable, "/", /[^\/\.]++/, "bar"),
          ART::RouteCompiler::Token.new(:text, "/foo"),
        ],
      },
    }
  end
end
