// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'navigator.dart';

class RouterData {

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
    this.routeNameProvider,
    this.routeNameParser,
    this.routerDelegate,
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

