# Represents the type of URLs that are able to be generated via an `ART::Generator::Interface`.
enum Athena::Routing::Generator::ReferenceType
  # Includes an absolute URL including protocol, hostname, and path: `https://api.example.com/add/10/5`.
  #
  # By default the `Host` header of the request is used as the hostname, with the scheme being `https`.
  # This can be customized via the `ATH::Parameters#base_uri` parameter.
  #
  # NOTE: If the `base_uri` parameter is not set, and there is no `Host` header, the generated URL will fallback on `ABSOLUTE_PATH`.
  ABSOLUTE_URL

  # The default type, includes an absolute path from the root to the generated route: `/add/10/5`.
  ABSOLUTE_PATH

  # TODO: Implement this.
  RELATIVE_PATH

  # Similar to `ABSOLUTE_URL`, but reuses the current protocol: `//api.example.com/add/10/5`.
  NETWORK_PATH
end
