// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'framework.dart';
import 'navigator.dart';

typedef CustomPageBuilder = Page<dynamic> Function();
typedef RoutableBuilder = Widget Function(BuildContext, dynamic);
/// An abstract class for parsed Router data that will be used in [WidgetApp]
abstract class RouterData {
  /// A getter that is used by [WidgetApp] to get the latest route name.
  ///
  /// This will be used for sending route update notification to platform after
  /// certain routing event, such as android back bottom.
  String get currentRouteName;
}

/// Route name parser class that parse string route name into a data <T>
abstract class RouteNameParser<T> {
  /// Parse the route name into a data <T>.
  T parse(String routeName);
}

/// An abstract class to provide an API for configuring and updating the
/// [Navigator].
abstract class RouterDelegate<T> {
  /// creates a router delegate
  const RouterDelegate();
  /// A callback that will be called when [Router.backBottomDispatcher] wants to
  /// pop the route.
  void popRoute();

  /// A method is called shortly after the Router has been built for the first
  /// time with the initial route information obtained from the
  /// [Router.routeNameProvider]. The route name will be parsed by
  /// [Router.routeNameParser] before passing into this method.
  ///
  /// By default, this method directly called [setNewRoutePath].
  void setInitialRoutePath(T routeData) {
    setNewRoutePath(routeData);
  }

  /// A method is called when [Router.routeNameProvider] provides a new route
  /// name, The route name will be parsed by [Router.routeNameParser] before
  /// passing into this method.
  ///
  /// The [build] will be called shortly after this method was called, and it
  /// should returns [Widget] with most up to date configuration.
  void setNewRoutePath(T routeData);

  /// A builder to builds the Widget contains a [Navigator].
  ///
  /// This build method will be called whenever [Router] asks for a new
  /// [Navigator] to be built.
  Widget build(BuildContext context);
}

/// A widget that takes [TransitionDelegate] and [RouterData] to build a
/// [Navigator] with configuration.
class Router<T> extends StatefulWidget {
  /// Creates a router.
  const Router({
    Key key,
    this.routeNameParser,
    this.routerDelegate,
    this.routeNameProvider,
    this.backButtonDispatcher,
  }) : super(key: key);

  /// Parsed router data.
  final ValueListenable<String> routeNameProvider;

  /// A parser that parse the route name into a data <T> for [routerDelegate].
  final RouteNameParser<T> routeNameParser;

  /// A delegate to builds and configure the navigator.
  final RouterDelegate<T> routerDelegate;

  /// A [Listenable] that notifies the [Router] to pop the top most route.
  final Listenable backButtonDispatcher;

  @override
  _RouterState<T> createState() => _RouterState<T>();
}

class _RouterState<T> extends State<Router<T>> {

  @override
  void initState() {
    super.initState();
    widget.routeNameProvider?.addListener(_onRouteNameUpdate);
    widget.backButtonDispatcher.addListener(_onPopRoute);
    _setNewRouteName(isInitialRoute: true);
  }

  void _onPopRoute() {
    widget.routerDelegate.popRoute();
    setState(() {
      // widget.routerDelegate should have the latest route data. Pumps a frame
      // to rebuild the navigator.
    });
  }

  void _setNewRouteName({bool isInitialRoute = false}) {
    final T routeData = widget.routeNameParser.parse(widget.routeNameProvider.value);
    if (isInitialRoute) {
      widget.routerDelegate.setInitialRoutePath(routeData);
    } else {
      widget.routerDelegate.setNewRoutePath(routeData);
    }
  }

  void _onRouteNameUpdate({bool isInitialRoute = false}){
    _setNewRouteName();
    setState(() {
      // widget.routerDelegate should have the latest route data. Pumps a frame
      // to rebuild the navigator.
    });
  }

  @override
  void didUpdateWidget(Router<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool providerHasChanged = oldWidget.routeNameProvider != widget.routeNameProvider;
    if (providerHasChanged) {
      oldWidget.routeNameProvider?.removeListener(_onRouteNameUpdate);
      widget.routeNameProvider?.removeListener(_onRouteNameUpdate);
    }

    if (widget.backButtonDispatcher != oldWidget.backButtonDispatcher) {
      oldWidget.backButtonDispatcher?.removeListener(_onPopRoute);
      widget.backButtonDispatcher?.addListener(_onPopRoute);
    }

    if (
      providerHasChanged ||
      widget.routeNameParser != oldWidget.routeNameParser ||
      widget.routerDelegate != oldWidget.routerDelegate
    ) {
      _setNewRouteName();
    }

  }
  @override
  Widget build(BuildContext context) {
    return widget.routerDelegate.build(context);
  }
}

class _DefaultRouteData extends RouterData {
  _DefaultRouteData({
    this.pages,
  });

  @override
  String get currentRouteName {
    return pages.last.name;
  }

  final List<Page<dynamic>> pages;
}

/// An error where the [RouteNameParser] cannot parse the given route
/// Name.
class InvalidRouteNameError extends Error {/* TODO(chunhtai): fill in something */}

/// Parsed Result for [DefaultRouteNameParser]
class ParsedResult {
  /// Creates a parsed result with input data.
  ParsedResult(this.data);

  /// The parsed data.
  final CustomPageBuilder data;
}

/// A definition that outlines how to parse the route name.
class ParserDefinition extends ParsedResult{
  /// Creates a parser definition that contains the sub routing information.
  ///
  /// Use [page] to provide a default page when there is no more sub route.
  ParserDefinition({this.routing, CustomPageBuilder page}): super(page);

  /// The routing table
  final Map<Pattern, ParsedResult> routing;

  CustomPageBuilder _parse(String routeName) {
    assert(routeName != null);
    if (routeName.startsWith('/'))
      routeName = routeName.substring(1); // strip leading '/'
    if (routeName == '')
      return data;
    for (final Pattern pattern in routing.keys) {
      final String subRoute = _subRouteFromPattern(pattern, routeName);
      if (subRoute != null) {
        // We have a match, proceed to next parser.
        final ParsedResult result = routing[pattern];
        if (subRoute == '') {
          if (result.data == null)
            throw InvalidRouteNameError();
          return result.data;
        }
        // We have sub route.
        if (result is ParserDefinition) {
          return result._parse(subRoute);
        }
      }
    }
    // We failed to find a pattern match.
    throw InvalidRouteNameError();
  }

  String _subRouteFromPattern(Pattern pattern, String routeName) {
    final int match = routeName.indexOf(pattern);
    if (match != 0){
      return routeName.replaceFirst(pattern, '');
    }
  }
}

/// Default parser that way of parsing
///
/// See also:
///
///  * [DefaultRouterDelegate], which consumes the parsed result.
class DefaultRouteNameParser extends RouteNameParser<_DefaultRouteData> {
  /// Creates a default parser
  DefaultRouteNameParser({
    this.parserDefinition,
    this.enableRouteStack,
  }) : super();

  /// A definition that will be used for parsing the route name.
  final ParserDefinition parserDefinition;

  /// Whether the the parser will parse the route name into a stack of routes.
  ///
  /// If this is false, the parser will only produce one route per route name.
  /// This is typically used in web where there is no concept of routes stack.
  final bool enableRouteStack;

  @override
  _DefaultRouteData parse(String routeName) {
    assert(routeName != null);
    List<Page<dynamic>> result;
    if (enableRouteStack) {
      if (routeName.startsWith('/') && routeName.length > 1)
        routeName = routeName.substring(1); // strip leading '/'
      final List<String> routeParts = routeName.split('/');
      if (routeParts.isNotEmpty) {
        String routeName = '';
        for (final String part in routeParts) {
          routeName += '/$part';
          result.add(parserDefinition._parse(routeName)());
        }
      }
    } else {
      result.add(parserDefinition._parse(routeName)());
    }
    return _DefaultRouteData(pages: result);
  }
}

/// A default router delegate that configures the navigator based on the parsed
/// result from the [DefaultRouteNameParser].
///
/// See also:
///
///  * [DefaultRouteNameParser], which parses the route name for this delegate
class DefaultRouterDelegate extends RouterDelegate<_DefaultRouteData> {
  /// Creates a default route delegate.
  DefaultRouterDelegate({this.transitionDelegate = const DefaultTransitionDelegate<dynamic>()});

  _DefaultRouteData _routerData;

  /// The transition delegate that will be used in the configured [Navigator].
  TransitionDelegate<dynamic> transitionDelegate;

  @override
  void popRoute() {
    assert(_routerData != null);
    _routerData.pages.removeLast();
  }

  @override
  void setNewRoutePath(_DefaultRouteData routeData) {
    _routerData = routeData;
  }

  @override
  Widget build(BuildContext context) {
    Navigator(
      pages: _routerData.pages,
      transitionDelegate: transitionDelegate,
    );
  }
}

/// Parsed Result for [DefaultRouteNameParser]
class Result {
  /// Creates a parsed result with input data.
  Result(this.data);

  /// The parsed data.
  final dynamic data;
}

/// A definition that outlines how to parse the route name.
class DynamicParserDefinition extends Result{
  /// Creates a parser definition that contains the sub routing information.
  ///
  /// Use [page] to provide a default page when there is no more sub route.
  DynamicParserDefinition({this.key, this.routing, dynamic result}): super(result);

  final LocalKey key;
  /// The routing table
  final Map<Pattern, Result> routing;

  Map<LocalKey, dynamic> _parse(String routeName) {
    assert(routeName != null);
    if (routeName.startsWith('/'))
      routeName = routeName.substring(1); // strip leading '/'
    if (routeName == '')
      return <LocalKey, dynamic>{};
    for (final Pattern pattern in routing.keys) {
      final String subRoute = _subRouteFromPattern(pattern, routeName);
      if (subRoute != null) {
        // We have a match, proceed to next parser.
        final Result result = routing[pattern];

        if (subRoute == '') {
          if (result.data == null)
            throw InvalidRouteNameError();
          return <LocalKey, dynamic>{key: result.data};
        }
        // We have sub route.
        if (result is DynamicParserDefinition) {
          return result._parse(subRoute)..putIfAbsent(key, () => result.data);
        }
      }
    }
    // We failed to find a pattern match.
    throw InvalidRouteNameError();
  }

  String _subRouteFromPattern(Pattern pattern, String routeName) {
    final int match = routeName.indexOf(pattern);
    if (match != 0){
      return routeName.replaceFirst(pattern, '');
    }
  }
}

class _DefaultDynamicRouteData extends RouterData {
  _DefaultDynamicRouteData({
    this.maps,
  });

  @override
  String get currentRouteName {
    // TODO(chunhtai): implement this method
  }

  final List<Map<LocalKey, dynamic>> maps;
}
/// Dynamic route name parser
class DynamicRouteNameParser extends RouteNameParser<_DefaultDynamicRouteData> {
  /// Creates a dynamic parser.
  DynamicRouteNameParser({
    this.parserDefinition,
    this.enableRouteStack,
  }) : super();

  /// A definition that will be used for parsing the route name.
  final DynamicParserDefinition parserDefinition;

  /// Whether the the parser will parse the route name into a stack of routes.
  ///
  /// If this is false, the parser will only produce one route per route name.
  /// This is typically used in web where there is no concept of routes stack.
  final bool enableRouteStack;

  @override
  _DefaultDynamicRouteData parse(String routeName) {
    assert(routeName != null);
    List<Map<LocalKey, dynamic>> result;
    if (enableRouteStack) {
      if (routeName.startsWith('/') && routeName.length > 1)
        routeName = routeName.substring(1); // strip leading '/'
      final List<String> routeParts = routeName.split('/');
      if (routeParts.isNotEmpty) {
        String routeName = '';
        for (final String part in routeParts) {
          routeName += '/$part';
          result.add(parserDefinition._parse(routeName));
        }
      }
    } else {
      result.add(parserDefinition._parse(routeName));
    }
    return _DefaultDynamicRouteData(maps: result);
  }
}

/// A default router delegate that configures the navigator based on the parsed
/// result from the [DynamicRouteNameParser].
///
/// See also:
///
///  * [DynamicRouteNameParser], which parses the route name for this delegate
class DynamicRouterDelegate extends RouterDelegate<_DefaultDynamicRouteData> {
  /// Creates a default route delegate.
  DynamicRouterDelegate({this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(), this.builder});

  _DefaultDynamicRouteData _routerData;

  final WidgetBuilder builder;

  /// The transition delegate that will be used in the configured [Navigator].
  TransitionDelegate<dynamic> transitionDelegate;

  @override
  void popRoute() {
    assert(_routerData != null);
    _routerData.maps.removeLast();
  }

  @override
  void setNewRoutePath(_DefaultDynamicRouteData routeData) {
    _routerData = routeData;
  }

  @override
  Widget build(BuildContext context) {
    Navigator(
      pages: const <Page<dynamic>>[],
      transitionDelegate: transitionDelegate,
    );
  }
}

/// A Routable Widget that takes a builder and parser key to build the widget.
class Routable extends StatelessWidget {
  /// Creates a builder widget.
  Routable({Key key, this.parserKey, this.builder}): super(key: key);

  /// the key to the corresponding builder.
  final LocalKey parserKey;

  /// A builder to build a widget for the corresponding routing data.
  final RoutableBuilder builder;
  @override
  Widget build(BuildContext context) {
    // TODO(chunhtai): implement this.
    return builder(context, null);
  }
}