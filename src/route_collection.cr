class Athena::Routing::RouteCollection
  include Enumerable({String, Athena::Routing::Route})
  include Iterable({String, Athena::Routing::Route})

  @routes = Hash(String, ART::Route).new
  protected getter priorities = Hash(String, Int32).new

  @sorted : Bool = false

  def_clone

  # TODO: Support route aliases?

  def add(collection : self) : Nil
    @sorted = false

    # Remove the routes first so they are added to the end of the routes hash.
    collection.each do |name, route|
      self.delete name

      @routes[name] = route

      if collection.priorities.has_key? name
        @priorities[name] = collection.priorities[name]
      end
    end
  end

  def add(name : String, route : ART::Route, priority : Int32 = 0) : Nil
    self.delete name

    @routes[name] = route

    @priorities[name] = priority unless priority.zero?
  end

  def add_defaults(defaults : Hash(String, _)) : Nil
    return if defaults.empty?

    @routes.each_value do |route|
      route.add_defaults defaults
    end
  end

  def add_prefix(prefix : String, defaults : Hash(String, _) = Hash(String, String?).new, requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new) : Nil
    prefix = prefix.strip.rstrip '/'
    return if prefix.empty?

    @routes.each_value do |route|
      route.path = "/#{prefix}#{route.path}"
      route.add_defaults defaults
      route.add_requirements requirements
    end
  end

  def add_name_prefix(prefix : String) : Nil
    prefixed_routes = Hash(String, ART::Route).new
    prefixed_priorities = Hash(String, Int32).new

    @routes.each do |name, route|
      prefixed_routes["#{prefix}#{name}"] = route

      if cannonical_route = route.default "_canonical_route"
        route.set_default "_canonical_route", "#{prefix}#{cannonical_route}"
      end

      if priority = @priorities[name]?
        prefixed_priorities["#{prefix}#{name}"] = priority
      end
    end

    # TODO: Support aliases?

    @routes = prefixed_routes
    @priorities = prefixed_priorities
  end

  def add_requirements(requirements : Hash(String, Regex | String)) : Nil
    return if requirements.empty?

    @routes.each_value do |route|
      route.add_requirements requirements
    end
  end

  def set_host(host : String, defaults : Hash(String, _) = Hash(String, String?).new, requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new) : Nil
    @routes.each_value do |route|
      route.host = host
      route.add_defaults defaults
      route.add_requirements requirements
    end
  end

  def schemes=(schemes : String | Enumerable(String)) : Nil
    @routes.each_value do |route|
      route.schemes = schemes
    end
  end

  def methods=(methods : String | Enumerable(String)) : Nil
    @routes.each_value do |route|
      route.methods = methods
    end
  end

  def remove(*names : String) : Nil
    names.each { |n| self.remove n }
  end

  def remove(name : String) : Nil
    self.delete name
  end

  # Yields the name and `ART::Route` object for each registered route.
  def each : Nil
    self.routes.each do |k, v|
      yield({k, v})
    end
  end

  # Returns an `Iterator` for each registered route.
  def each
    self.routes.each
  end

  # Returns the routes hash.
  def routes : Hash(String, ART::Route)
    if !@priorities.empty? && !@sorted
      insert_order = @routes.keys

      @routes
        .to_a
        .sort! do |(n1, r1), (n2, r2)|
          priority = (@priorities[n2]? || 0) <=> (@priorities[n1]? || 0)

          next priority unless priority.zero?

          insert_order.index(n1).not_nil! <=> insert_order.index(n2).not_nil!
        end
        .tap { @routes.clear }
        .each { |name, route| @routes[name] = route }

      @sorted = true
    end

    @routes
  end

  # Returns the `ART::Action` with the provided *name*.
  #
  # Raises a `ART::Exception::InvalidArgument` if a route with the provided *name* does not exist.
  def get(name : String) : ART::Route
    self.routes.fetch(name) { raise ART::Exception::InvalidArgument.new "Unknown route: '#{name}'." }
  end

  # :ditto:
  def [](name : String) : ART::Route
    self.get name
  end

  # Returns the `ART::Action` with the provided *name*, or `nil` if it does not exist.
  def get?(name : String) : ART::Route?
    self.routes[name]?
  end

  # :ditto:
  def []?(name : String) : ART::Route?
    self.get? name
  end

  def size : Int
    self.routes.size
  end

  private def delete(name : String) : Nil
    @routes.delete name
    @priorities.delete name
  end
end
