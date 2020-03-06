// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


void main(){
  runApp(
    MaterialApp.withRouter(
      parser: WebRouteNameParser(
        map: <String, CustomPageBuilder>{
          '/': (String routeName) => HomePage(name: routeName),
          '/:id/profile': (String routeName) => ProfilePageRoutable(),
        }
      )
    )
  );
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



/// Profile Page
class ProfilePageRoutable extends Routable<void> {
  /// Material Routable
  const ProfilePageRoutable({
    TransitionDelegate<dynamic> transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
  }) : super(transitionDelegate: transitionDelegate);

  @override
  RouteNameParser get parser => WebRouteNameParser(
    map: <String, CustomPageBuilder>{
      // /:id/profile
      '': (String routeName) => ProfileMainPage(),
      // /:id/profile/privacy
      'privacy': (String routeName) => ProfilePrivacyPage(),
    }
  );

  @override
  Route<void> createRoute(BuildContext context) {
    return MaterialPageRoute<void>(
      settings: this,
      builder: (BuildContext context) {
        // Only the Scaffold body will change based on sub route, The appBar and
        // Other will stay the same for all profile sub routes.
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Page'),
          ),
          body: buildChildRoutingContent(context),
        );
      }
    );
  }
}

class ProfileMainPage extends Page<void> {
  @override
  Route<void> createRoute(BuildContext context) {
    // TODO: implement createRoute
    throw UnimplementedError();
  }
}

class ProfilePrivacyPage extends Page<void> {
  @override
  Route<void> createRoute(BuildContext context) {
    // TODO: implement createRoute
    throw UnimplementedError();
  }
}