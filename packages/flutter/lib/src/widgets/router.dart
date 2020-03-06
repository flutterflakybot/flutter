// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'framework.dart';
import 'navigator.dart';

/// A widget that creates a [Router] and manages [Router] events.
///
/// This widget also updates the [RouterData] when a sub route name has changed.
class RouterConfiguration extends StatefulWidget {
  /// Creates a router configuration.
  RouterConfiguration({Key key, this.pageKey, this.transitionDelegate, this.parser}): super(key: key);
  final LocalKey pageKey;
  /// the Routeable that owns this page.
  final RouteNameParser parser;
  final TransitionDelegate<dynamic> transitionDelegate;
  @override
  RouterConfigurationState createState() => RouterConfigurationState();
}

class RouterConfigurationState extends State<RouterConfiguration> {

  void _onRouteNameUpdate(String routeName) {
    final RouterData data = Router.routerDataOf(context);
    data._childData = widget.parser.parse(routeName);
    setState(() {/* the next build will grab the parsed result */});
  }

  @override
  Widget build(BuildContext context) {
    final RouterData data = Router.routerDataOf(context)._childData;
    assert(data != null);
    return Router(key: widget.pageKey, data: data, transitionDelegate: widget.transitionDelegate, onRouteNameUpdate: _onRouteNameUpdate);
  }
}
/// A widget that takes [TransitionDelegate] and [RouterData] to build a
/// [Navigator] with configuration.
class Router extends InheritedWidget {
  /// Creates a router.
  Router({Key key, this.data, this.onRouteNameUpdate, TransitionDelegate<dynamic> transitionDelegate}) :super(
    key: key,
    child: _Router(
      data: data,
      transitionDelegate: transitionDelegate,
    ),
  );

  /// Parsed router data.
  final RouterData data;

  /// A callback that will be called when the router want to update the route
  /// name.
  final Function onRouteNameUpdate;

  /// Gets the router data.
  static RouterData routerDataOf(BuildContext context) {
    assert(context != null);
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

  static void updateRouteNameOf(
    BuildContext context, {
    Key key,
    @required String routeName
  }) {
    InheritedElement element = context.getElementForInheritedWidgetOfExactType<Router>();
    if (key != null) {
      while (element.widget.key != key) {
        element = element.getElementForInheritedWidgetOfExactType<Router>();
      }
    }
    assert(element != null);
    final Router router = element.widget as Router;
    router.onRouteNameUpdate(routeName);
  }

  @override
  bool updateShouldNotify(Router oldWidget) => data != oldWidget.data;
}

/// Parsed route data.
class RouterData {
  /// Creates a parsed route data.
  RouterData({this.pages, RouterData childData}): _childData = childData;
  /// The pages list after parsed.
  final List<Page<dynamic>> pages;
  RouterData _childData;
}

class _Router extends StatelessWidget {
  const _Router({
    this.data,
    this.transitionDelegate,
  }) : super();
  final RouterData data;
  final TransitionDelegate<dynamic> transitionDelegate;

  @override
  Widget build(BuildContext context) {
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
      transitionDelegate: transitionDelegate,

    );
  }
}

typedef RoutableWidgetBuilder<T> = Widget Function(Routable<T> routable, BuildContext context);
typedef CustomPageBuilder = Page<dynamic> Function(String routeName);
/// Routable
abstract class Routable<T> extends Page<T> {
  /// Creates a Routable widget.
  const Routable({LocalKey key, this.transitionDelegate}) : super(key: key);

  RouteNameParser get parser;
  final TransitionDelegate<dynamic> transitionDelegate;
  /// builds child routing content.
  ///
  /// It creates a Router which uses [RouteData] parsed from [parser].
  Widget buildChildRoutingContent(BuildContext context) {
    return RouterConfiguration(pageKey: key, parser: parser, transitionDelegate: transitionDelegate);
  }
}


/// A route Name parser that is responsible for parsing route names into
/// [RouterData]s.
abstract class RouteNameParser {
  /// Initializes a route name parser.
  const RouteNameParser();
  /// Parses a given route name into a [RouterData].
  RouterData parse(String routeName);

  /// Restores the route name from list of pages.
  String restoreRouteName(RouterData data);
}

/// A web version of [RouteNameParser].
///
/// This method uses an input map to find the matches for a given route name.
class WebRouteNameParser extends RouteNameParser{
  /// Creates a web route name parser with input map.
  WebRouteNameParser({this.map, this.onUnknownRouteName});

  /// A pattern map to match a route name into a page builder.
  final Map<String, CustomPageBuilder> map;

  /// A fallback builder if the route name can not be parsed. The [Page] return
  /// from this parser must
  final CustomPageBuilder onUnknownRouteName;

  RouterData _lastProducedRouterData;
  String _lastRouteNamePiece;

  @override
  String restoreRouteName(RouterData data) {
    assert(data == _lastProducedRouterData);
    assert(_lastProducedRouterData.pages.length == 1);
    final Page<dynamic> lastPage = data.pages.last;
    String result = _lastRouteNamePiece;
    if (lastPage is Routable) {
      result += lastPage.parser.restoreRouteName(data._childData);
    }
    return result;
  }

  RouterData _getRouterDataForUnknownRoute(String routeName) {
    if (onUnknownRouteName == null) {
      return null;
    }
    final Page<dynamic> page = onUnknownRouteName(routeName);
    assert(page is! Routable);
    return RouterData(pages: <Page<dynamic>>[page]);
  }

  @override
  RouterData parse(String routeName) {
    // TODO: do a regex matching instead of direct matching.
    final String matchedPattern = map.keys.firstWhere(
      (String pattern) => routeName.startsWith(pattern),
      orElse: () => null,
    );

    if (matchedPattern == null) {
      return _getRouterDataForUnknownRoute(routeName);
    }

    final Page<dynamic> page = map[matchedPattern](matchedPattern);

    final RouterData result = RouterData(pages: <Page<dynamic>>[page]);

    if (page is Routable) {
      result._childData = page.parser.parse(routeName.replaceAll(matchedPattern, ''));
      if (result._childData == null) {
        // There is a parsing error that the sub parsers cannot resolve. This
        // should fallback to onUnknownRouteName in this parser.
        return _getRouterDataForUnknownRoute(routeName);
      }
    }
    // The entire route name is parsed successfully.
    _lastRouteNamePiece = matchedPattern;
    _lastProducedRouterData = result;
    return result;
  }
}