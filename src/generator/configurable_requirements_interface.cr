module Athena::Routing::Generator::ConfigurableRequirementsInterface
  abstract def strict_requirements=(enabled : Bool?)
  abstract def strict_requirements? : Bool?
end
