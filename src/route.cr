# TODO: How to store a reference to the "Controller"
# in quotes because it technically doesn't need to be an ART::Controller.
class Athena::Routing::Route
  getter path : String
  getter method : String

  getter requirements : Hash(String, Regex)? = nil
  getter defaults : Hash(String, String?) = Hash(String, String?).new

  getter condition : Proc(HTTP::Request, Bool)? = nil

  # TODO: Can we repalce this with `#name`?
  getter condition_key : String? = nil

  # TODO: Don't think we actually know these:
  getter host : String? = nil
  getter schemas : Set(String)? = nil

  @compiled_route : ART::CompiledRoute? = nil

  def initialize(@path : String, @method : String)
    # TODO: Support inline requirements/defaults?
  end

  def compile : CompiledRoute
    @compiled_route ||= ART::RouteCompiler.compile self
  end

  # TODO: Add methods to set things.

  def has_default?(name : String) : Bool
    !!@defaults.try &.has_key?(name)
  end
end
