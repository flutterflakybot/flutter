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


      routeNameParser: FlutterRouteNameParser(
        parserDefinition: ParserDefinition<String>(
          key: const ValueKey<String>('root'),
          routing: <Pattern, ParsedResult<String>>{
            'profile': ParserDefinition<String>(
              key: const ValueKey<String>('profile'),
              result: 'some_profile_flag',
              routing: <Pattern, ParsedResult<String>>{
                'setting': ParsedResult<String>('some_setting_flag'), //  Matches '/profile/setting'
                'privacy': ParsedResult<String>('some_privacy_flag'), //  Matches '/profile/privacy'
              },
            ),
            'dashbaord': ParsedResult<String>('some_dashbaord_flag'), // Matches '/dashbaord'
          },
          result: 'some_home_flag'// Matches '/'
        )
      ),

      // / -> {'root': 'some_home_flag'}
      // /dashboard -> {'root': 'some_dashbaord_flag'}
      // /profile/privacy -> {'root': 'some_profile_flag', 'profile': 'some_privacy_flag'}
      // /profile/setting -> {'root': 'some_user_flag', 'profile': 'some_setting_flag'}


      routerDelegate: DynamicRouterDelegate(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Routable(
              parserKey: const ValueKey<String>('profile'),
              builder: (BuildContext context, dynamic flag) {
              if (flag == 'some_setting_flag')
              return LogOutbutton();
            }
          )),
            body: Routable(
              parserKey: const ValueKey<String>('root'),
              builder: (BuildContext context, dynamic flag) {
                if (flag == 'some_profile_flag')
                  return ProfileContent();
                if (flag == 'some_dashbaord_flag')
                  return DashBoard();
                throw '?';
              },
            )
          );
        }
      ),



      onUnknownRouteName: (BuildContext context) => const Placeholder(),
    )
  );
}

class DashBoard extends Placeholder{}

class LogOutbutton extends Placeholder{}


// think about exposing global route data, but be careful

// widgets with nested navigator and audit.

// adv use case:
//        1: route validation involving database call.