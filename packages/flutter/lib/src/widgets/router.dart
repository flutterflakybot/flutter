// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'framework.dart';
import 'navigator.dart';

typedef CustomPageBuilder = Page<dynamic> Function();
typedef FragmentBuilder = Widget Function(BuildContext, dynamic);
typedef UnknownRouteBuilder<T> = Route<T> Function(BuildContext, RouteSettings, String);
typedef UnknownWidgetBuilder = Widget Function(BuildContext, String);

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

  /// Retrieves the route name parser that matches type R.
  static R of<R extends RouteNameParser<dynamic>>(BuildContext context) {
    State<Router<dynamic>> walker = Router.of(context);

    while(walker.widget.routeNameParser is! R) {
      walker = Router.of(walker.context);
    }

    return walker.widget.routeNameParser as R;
  }
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

  void onUnknownRouteName(BuildContext context, String routeName);

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

  /// Find immediately [Router] ancestor of the context.
  static State<Router<dynamic>> of(BuildContext context) {
    return context.findAncestorStateOfType<_RouterState<dynamic>>();
  }

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


/// An error where the [RouteNameParser] cannot parse the given route
/// Name.
class InvalidRouteNameError extends Error {/* TODO(chunhtai): fill in something */}

/// Parsed Result for [DefaultRouteNameParser]
class ParsedResult<T> {
  /// Creates a parsed result with input data.
  ParsedResult(this.data);

  /// The parsed data.
  final T data;
}

/// A definition that outlines how to parse the route name.
class ParserDefinition<T> extends ParsedResult<T>{
  /// Creates a parser definition that contains the sub routing information.
  ///
  /// Use [page] to provide a default page when there is no more sub route.
  ParserDefinition({this.key, this.routing, T result}): super(result);

  /// The key corresponds to this parser.
  final LocalKey key;

  /// The routing table
  final Map<Pattern, ParsedResult<dynamic>> routing;

  LinkedHashMap<LocalKey, dynamic> _parse(String routeName) {
    assert(routeName != null);
    if (routeName.startsWith('/'))
      routeName = routeName.substring(1); // strip leading '/'
    if (routeName == '')
      return <LocalKey, dynamic>{} as LinkedHashMap<LocalKey, dynamic>;
    for (final Pattern pattern in routing.keys) {
      final String subRoute = _subRouteFromPattern(pattern, routeName);
      if (subRoute != null) {
        // We have a match, proceed to next parser.
        final ParsedResult<dynamic> result = routing[pattern];

        if (subRoute == '') {
          if (result.data == null)
            throw InvalidRouteNameError();
          return <LocalKey, dynamic>{key: result.data} as LinkedHashMap<LocalKey, dynamic>;
        }
        // We have sub route.
        if (result is ParserDefinition) {
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

class _ParsedRouteData extends RouterData {
  _ParsedRouteData({
    this.maps,
  });

  @override
  String get currentRouteName {
    // TODO(chunhtai): implement this method
  }

  final List<Map<LocalKey, dynamic>> maps;
}
/// flutter route name parser
class MobileRouteNameParser extends RouteNameParser<_ParsedRouteData> {
  /// Creates a dynamic parser.
  MobileRouteNameParser({
    this.parserDefinition,
    this.enableRouteStack,
  }) : super();

  /// A definition that will be used for parsing the route name.
  final ParserDefinition<dynamic> parserDefinition;

  /// Whether the the parser will parse the route name into a stack of routes.
  ///
  /// If this is false, the parser will only produce one route per route name.
  /// This is typically used in web where there is no concept of routes stack.
  final bool enableRouteStack;

  @override
  _ParsedRouteData parse(String routeName) {
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
    return _ParsedRouteData(maps: result);
  }
}


/// A default router delegate that configures the navigator based on the parsed
/// result from the [MobileRouteNameParser].
///
/// See also:
///
///  * [MobileRouteNameParser], which parses the route name for this delegate
class WidgetsRouterDelegate extends RouterDelegate<_ParsedRouteData> {
  /// Creates a default route delegate.
  WidgetsRouterDelegate({this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(), this.builder, this.onUnknownRoute});

  _ParsedRouteData _routerData;

  final RouteBuilder<dynamic> builder;
  final UnknownRouteBuilder<dynamic> onUnknownRoute;

  /// The transition delegate that will be used in the configured [Navigator].
  TransitionDelegate<dynamic> transitionDelegate;

  @override
  void popRoute() {
    assert(_routerData != null);
    _routerData.maps.removeLast();
  }

  @override
  void setNewRoutePath(_ParsedRouteData routeData) {
    _routerData = routeData;
  }

  @override
  Widget build(BuildContext context) {
    Navigator(
      pages: <Page<dynamic>>[
        PageBuilder<dynamic>(
          key: UniqueKey(),
          routeBuilder: builder,
        )
      ],
      transitionDelegate: transitionDelegate,
    );
  }
  @override
  Route<dynamic> onUnknownRouteName(BuildContext context, String routeName) {
    return onUnknownRoute(context, null, routeName);
  }
}

class MaterialRouterDelegate extends RouterDelegate<_ParsedRouteData> {
  MaterialRouterDelegate({this.onUnknownRoute});

  UnknownWidgetBuilder onUnknownRoute;
}

/// A RouteFragmentBuilder Widget that takes a builder and parser key to build the widget.
class RouteFragmentBuilder extends StatelessWidget {
  /// Creates a builder widget.
  RouteFragmentBuilder({Key key, this.parserKey, this.builder}): super(key: key);

  /// the key to the corresponding builder.
  final LocalKey parserKey;

  /// A builder to build a widget for the corresponding routing data.
  final FragmentBuilder builder;
  @override
  Widget build(BuildContext context) {
    // TODO(chunhtai): implement this.
    return builder(context, null);
  }
}