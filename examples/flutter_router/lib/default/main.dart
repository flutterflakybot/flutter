// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'profile/profile.dart';

void main(){
  runApp(
    WidgetsApp.router(
      initialRoute: '/profile/privacy',


      routeNameParser: DefaultRouteNameParser(
        parserDefinition: ParserDefinition(
          routing: <Pattern, ParsedResult>{
            'profile': createProfileParseDefinition(),
            'dashbaord': ParsedResult(() => const DashBoardPage()), // Matches '/dashbaord'
          },
          page: () => const HomePage(), // Matches '/'
        )
      ),


      routerDelegate: DefaultRouterDelegate(),



      onUnknownRouteName: (BuildContext context) => const Placeholder(),
    )
  );
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

class DashBoardPage extends Page<void> {
  /// Material Routable
  const DashBoardPage({
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