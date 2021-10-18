class Athena::Routing::RouteProvider; end

"return [\n
    false, // $matchHost\n
    [ // $staticRoutes\n
        '/' => [[['_route' => 'app_index'], null, null, null, false, false, null]],\n
    ],\n
    [ // $regexpList\n
        0 => '{^(?'\n
                .'|/add/([^/]++)/([^/]++)(*:29)'\n
            .')/?$}sDu',\n
    ],\n
    [ // $dynamicRoutes\n
        29 => [\n
            [['_route' => 'app_add'], ['val1', 'val2'], null, null, false, true, null],\n
            [null, null, null, null, false, false, 0],\n
        ],\n
    ],\n
    null, // $checkCondition\n
];\n"

# :nodoc:
class Athena::Routing::RouteProvider::StaticPrefixCollection
  # :nodoc:
  #
  # name, regex pattern, variables, route, trailing slash?, trailing var?
  record StaticPrefixTreeRoute, name : String, pattern : String, variables : Set(String), route : ART::Route, has_trailing_slash : Bool, has_trailing_var : Bool

  # :nodoc:
  record StaticTreeNamedRoute, name : String, route : ART::Route

  private alias RouteInfo = Array(StaticTreeNamedRoute | StaticPrefixTreeRoute | self)

  getter prefix : String
  getter items : RouteInfo = RouteInfo.new

  protected setter items : RouteInfo

  @static_prefixes = Array(String).new
  @prefixes = Array(String).new

  def initialize(@prefix : String = "/"); end

  def add_route(prefix : String, route : StaticTreeNamedRoute | StaticPrefixTreeRoute | self) : Nil
    prefix, static_prefix = self.common_prefix prefix, prefix

    idx = @items.size - 1

    while 0 <= idx
      common_prefix, common_static_prefix = self.common_prefix prefix, @prefix

      idx -= 1
    end

    @static_prefixes << static_prefix
    @prefixes << prefix
    @items << route
  end

  def populate_collection(routes : ART::RouteCollection) : ART::RouteCollection
    @items.each do |item|
      case item
      in ART::RouteProvider::StaticPrefixCollection then item.populate_collection routes
      in StaticTreeNamedRoute                       then routes.add item.name, item.route
      in StaticPrefixTreeRoute
        # Skip
      end
    end

    routes
  end

  private def common_prefix(prefix : String, other_prefix : String) : Tuple(String, String)
    base_length = @prefix.size
    end_size = Math.min(prefix.size, other_prefix.size)
    static_length = nil

    idx = base_length

    while idx < end_size && prefix[idx] == other_prefix[idx]
      if '(' == prefix[idx]
        static_length = static_length || idx
        jdx = 1 + idx
        n = 1

        should_break = while jdx < end_size && 0 < n
          break true if prefix[jdx] != other_prefix[jdx]

          if '(' == prefix[jdx]
            n += 1
          elsif ')' == prefix[jdx]
            n -= 1
          elsif '\\' == prefix[jdx] && ((jdx += 1) == end_size || prefix[jdx] != other_prefix[jdx])
            jdx -= 1
            break false
          end

          jdx += 1
        end

        break if should_break
        break if 0 < n
        break if ('?' == (prefix[jdx]? || "") || '?' == (other_prefix[jdx]? || "")) && ((prefix[jdx]? || "") != (other_prefix[jdx]? || ""))

        sub_pattern = prefix[idx, jdx - idx]

        break if prefix != other_prefix && !sub_pattern.matches?(/^\(\[[^\]]++\]\+\+\)$/) && !"".matches?(/(?<!#{sub_pattern})/)

        idx = jdx - 1
      elsif '\\' == prefix[idx] && ((idx += 1) == end_size || prefix[idx] != other_prefix[idx])
        idx -= 1
        break
      end

      idx += 1
    end

    {prefix[0, idx], prefix[0, static_length || idx]}
  end
end
