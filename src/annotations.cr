# Contains all the `Athena::Routing` based annotations.
# See each annotation for more information.
#
# NOTE: These are primarily to define a common type/documentation to use in custom implementations.
# As of now, they are not leveraged internally, but a future iteration could provide a built in way to resolve them into an `ART::RouteCollection`.
module Athena::Routing::Annotations
  # Same as `ARTA::Route`, but only matches the `DELETE` method.
  annotation Delete; end

  # Same as `ARTA::Route`, but only matches the `GET` method.
  annotation Get; end

  # Same as `ARTA::Route`, but only matches the `HEAD` method.
  annotation Head; end

  # Same as `ARTA::Route`, but only matches the `LINK` method.
  annotation Link; end

  # Same as `ARTA::Route`, but only matches the `PATCH` method.
  annotation Patch; end

  # Same as `ARTA::Route`, but only matches the `POST` method.
  annotation Post; end
  annotation Prefix; end

  # Same as `ARTA::Route`, but only matches the `PUT` method.
  annotation Put; end

  # Annotation representation of an `ART::Route`.
  # Most commonly this will be applied to a method to define it as the controller for the related route.
  # But custom implementations may support alternate APIs.
  #
  # ## Configuration
  #
  # Various fields can be used within this annotation to control how the route is created.
  # All fields are optional unless otherwise noted.
  #
  # WARNING: However, not all fields may be supported by the underlying implementation.
  #
  # #### path
  #
  # **Type:** `String | Hash(String, String)` - **required**
  #
  # The path of the route.
  #
  # #### name
  #
  # **Type:** `String`
  #
  # The unique name of the route. If not provided, a unique name should be created automatically.
  #
  # #### requirements
  #
  # **Type:** `Hash(String, String | Regex)`
  #
  # A `Hash` of patterns that each parameter must match in order for the route to match.
  #
  # #### defaults
  #
  # **Type:** `Hash(String, _)`
  #
  # The values that should be applied to the route parameters if they were not supplied within the request.
  #
  # #### host
  #
  # **Type:** `String | Regex`
  #
  # The path of the route.

  # * name
  # * requirements
  # * defaults
  # * host
  # * methods
  # * schemes
  # * condition
  # * priority
  # * locale
  # * format
  # * stateless
  annotation Route; end

  # Same as `ARTA::Route`, but only matches the `UNLINK` method.
  annotation Unlink; end
end
