

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'framework.dart';
import 'navigator.dart';

/// A router widget that takes delegate and parsed route data to configure and
/// build a navigator.
class Router extends InheritedWidget {
  /// Creates a router.
  Router({Key key, this.data, TransitionDelegate<dynamic> transitionDelegate}) :super(
    key: key,
    child: _Router(
      transitionDelegate: transitionDelegate,
    ),
  );

  /// Parsed router data.
  final RouterData data;

  /// Gets the router data.
  static RouterData of(BuildContext context, { bool nullOk = false }) {
    assert(context != null);
    assert(nullOk != null);
    final Router query = context.dependOnInheritedWidgetOfExactType<Router>();
    if (query != null)
      return query.data;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('Router.of() called with a context that does not contain a Router.'),
      ErrorDescription(
        'No Router ancestor could be found starting from the context that was passed '
          'to Router.of().'
      ),
      context.describeElement('The context used was')
    ]);
  }
  @override
  bool updateShouldNotify(Router oldWidget) => data != oldWidget.data;
}

/// Parsed route data.
class RouterData {
  /// Creates a parsed route data.
  RouterData({this.pages, RouterData childData}): _childData = childData;
  /// The pages list after parsed.
  final List<Page> pages;
  final RouterData _childData;
}

class _Router extends StatefulWidget {
  const _Router({
    this.transitionDelegate,
  }) : super();

  final TransitionDelegate<dynamic> transitionDelegate;

  @override
  _RouterState createState() => _RouterState();
}

class _RouterState extends State<_Router> {

  @override
  Widget build(BuildContext context) {
    final RouterData data = Router.of(context);
    return Navigator(
      pages: data.pages,
      onPopPage: (Route<dynamic> route, dynamic result) {
        assert(route.settings == data.pages.last);
        assert(
          data._childData == null,
          'Pop should only be triggered at the leaf router.'
        );
        data.pages.removeLast();
        // TODO(chunhtai): we also need to notify route name has changed.
        return route.didPop(result);
      },
      transitionDelegate: widget.transitionDelegate,

    );
  }
}

typedef RoutableWidgetBuilder<T> = Widget Function(Routable<T> routable, BuildContext context);
typedef PageBuilder = Page<dynamic> Function(String routeName);
/// Routable
abstract class Routable<T> extends Page<T> {
  /// Creates a Routable widget.
  const Routable({this.parser, this.transitionDelegate});
  final RouteNameParser parser;
  final TransitionDelegate<dynamic> transitionDelegate;
  /// builds child routable.
  Router buildChildRouter(BuildContext context) {
    final RouterData data = Router.of(context)._childData;
    assert(data != null);
    return Router(data: data, transitionDelegate: transitionDelegate);
  }
}

class HomePage extends Page<void> {
  /// Material Routable
  const HomePage({
    String name,
  }) : super(name: name);

  @override
  Route<void> createRoute(BuildContext context) {
    return MaterialPageRoute<void>(
      settings: this,
      builder: (BuildContext context) {
        return Scaffold(
          body: Text(name),
        );
      }
    );
  }
}



/// Material Routable
class ProfilePageRoutable extends Routable<void> {
  /// Material Routable
  const ProfilePageRoutable({
    RouteNameParser parser,
    TransitionDelegate<dynamic> transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
  }) : super(parser: parser, transitionDelegate: transitionDelegate);

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute<void>(
      settings: this,
      builder: (BuildContext context) {
        return Scaffold(
          body: buildChildRouter(context),
        );
      }
    );
  }
}


/// A Route Name parser that is responsible for parsing route names into
/// [RouterData]s.
abstract class RouteNameParser {
  /// Initializes a route name parser.
  const RouteNameParser();
  /// Parses a given route name into a [RouterData].
  RouterData parse(String routeName);
}

class WebRouteNameParser extends RouteNameParser{
  const WebRouteNameParser({this.map});

  final Map<String, PageBuilder> map;
  @override
  RouterData parse(String routeName) {
    return RouterData();
  }
}

/// MaterialApp with router
class WithRouter extends StatelessWidget {
  /// MaterialApp with router
  const WithRouter({RouteNameParser parser}):super();
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

RouteNameParser createParser(Map<String, RouteNameParser> map) {
  return const WebRouteNameParser();
}

void main(){
  runApp(
    WithRouter(
      parser: WebRouteNameParser(
        map: <String, PageBuilder>{
          '/': (String routeName) => HomePage(name: routeName),
          '/:id/profile': (String routeName) => ProfilePageRoutable(
            parser: WebRouteNameParser(
              map: <String, PageBuilder>{
                '': (String routeName) => ProfileMainPage(),
                'privacy': (String routeName) => ProfilePrivacyPage(),
              }
            )
          ),
        }
      )
    )
  );
}


//{
//  '/': Routable(
//    parser: {
//      'a': Routable(
//
//      )
//    },
//    builder: ()
//  )
//}