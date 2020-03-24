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


      routeNameParser: MobileRouteNameParser(
        parserDefinition: ParserDefinition<String>(
          key: const ValueKey<String>('root'),
          routing: <Pattern, ParsedResult<String>>{
            'profile': createProfileParseDefinition('some_profile_flag'), // Matches '/profile'
            'dashbaord': ParsedResult<String>('some_dashboard_flag'), // Matches '/dashboard'
            '': ParsedResult<String>('some_home_flag'), // Matches '/'
          },
        )
      ),

      // /                -> {'root': 'some_home_flag'}
      // /dashboard       -> {'root': 'some_dashboard_flag'}
      // /profile/privacy -> {'root': 'some_profile_flag', 'profile': 'some_privacy_flag'}
      // /profile/setting -> {'root': 'some_user_flag', 'profile': 'some_setting_flag'}


      routerDelegate: WidgetsRouterDelegate(
        builder: (BuildContext context, RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => Scaffold(
              appBar: AppBar(
                // This will paint empty widget if the route name does not contain `profile` at all.
                title: RouteFragmentBuilder(
                  parserKey: const ValueKey<String>('profile'),
                  builder: (BuildContext context, dynamic flag) {
                    if (flag == 'some_setting_flag')
                      return LogOutbutton();
                    return Container();
                  }
                )
              ),
              body: RouteFragmentBuilder(
                parserKey: const ValueKey<String>('root'),
                builder: (BuildContext context, dynamic flag) {
                  if (flag == 'some_profile_flag')
                    return ProfileContent();
                  if (flag == 'some_dashbaord_flag')
                    return DashBoard();
                  throw '?';
                },
              )
            )
          );
        },
        onUnknownRoute: (BuildContext context, RouteSettings settings, String routeName) =>
          MaterialPageRoute<dynamic>(
            builder: (_) => const Placeholder(),
          ),
      ),
    )
  );
}

class DashBoard extends Placeholder{}

class LogOutbutton extends Placeholder{}