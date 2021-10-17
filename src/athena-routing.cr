# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

module Athena::Routing
  VERSION = "0.1.0"
end

# return [
#     false, // $matchHost
#     [ // $staticRoutes
#         '/app' => [[['_route' => 'app_app_index', '_controller' => 'App\\Controller\\AppController::index'], null, null, null, false, false, null]],
#         '/article' => [[['_route' => 'app_app_getarticles', '_controller' => 'App\\Controller\\AppController::getArticles'], null, null, null, false, false, null]],
#     ],
#     [ // $regexpList
#         0 => '{^(?'
#                 .'|/a(?'
#                     .'|dd/([^/]++)/([^/]++)(*:32)'
#                     .'|rticle/([^/]++)(*:54)'
#                 .')'
#             .')/?$}sDu',
#     ],
#     [ // $dynamicRoutes
#         32 => [[['_route' => 'app_app_add', '_controller' => 'App\\Controller\\AppController::add'], ['val1', 'val2'], null, null, false, true, null]],
#         54 => [
#             [['_route' => 'app_app_getarticle', '_controller' => 'App\\Controller\\AppController::getArticle'], ['id'], null, null, false, true, null],
#             [null, null, null, null, false, false, 0],
#         ],
#     ],
#     null, // $checkCondition
# ];

route = Athena::Routing::Route.new "/add/{val1}/{val2}", "GET"

# pp Athena::Routing::RouteCompiler.compile

collection = ART::RouteCollection.new

collection.add "my_route", route

pp collection
