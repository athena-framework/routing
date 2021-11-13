# Interface for URL generation types.
#
# Implementors must define a `#generate` method that accepts the route name, any params, and what type of URL should be generated and return the URL string.
module Athena::Routing::Generator::Interface
  include Athena::Routing::RequestContextAwareInterface

  abstract def generate(route : String, params : Hash(String, _) = Hash(String, String).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
end
