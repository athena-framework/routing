class Athena::Routing::RouteCollection
  include Enumerable({String, Athena::Routing::Route})
  include Iterable({String, Athena::Routing::Route})

  @routes = Hash(String, ART::Route).new
  protected getter priorities = Hash(String, Int32).new

  def add(collection : self) : Nil
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

  def add_prefix(name : String, defaults : Hash(String, String)? = nil, requirements : Hash(String, Regex)? = nil) : Nil
    prefix = name.strip.rstrip '/'
    return if prefix.empty?

    @routes.each_value do |route|
      route.path = "/#{prefix}#{route.path}"
      # TODO: Apply defaults/requirements to each route
    end
  end

  # TODO: Add methods to allow adding values to all routes
  # such as requirements, defaults, host, etc.

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
    # TODO: Sort the routes based on priority

    @routes
  end

  # Returns the `ART::Action` with the provided *name*.
  #
  # Raises a `KeyError` if a route with the provided *name* does not exist.
  def get(name : String) : ART::Route
    self.routes.fetch(name) { raise KeyError.new "Unknown route: '#{name}'." }
  end

  # Returns the `ART::Action` with the provided *name*, or `nil` if it does not exist.
  def get?(name : String) : ART::Route?
    self.routes[name]?
  end

  def size : Int
    self.routes.size
  end

  private def delete(name : String) : Nil
    @routes.delete name
    @priorities.delete name
  end
end
