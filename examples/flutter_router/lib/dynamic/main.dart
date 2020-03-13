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


      routeNameParser: DynamicRouteNameParser(
        parserDefinition: DynamicParserDefinition(
          key: const ValueKey<String>('root'),
          routing: <Pattern, Result>{
            'profile': createProfileParseDefinition('some_profile_flag'),
            'user/:id': createProfileParseDefinition('some_user_flag'),
            'dashbaord': Result('some_dashbaord_flag'), // Matches '/dashbaord'
          }, // Matches '/'
        )
      ),

      // /dashboard -> {'root': 'some_dashbaord_flag'}
      // /profile/privacy -> {'root': 'some_profile_flag', 'profile': 'some_privacy_flag'}
      // /user/privacy -> {'root': 'some_user_flag', 'profile': 'some_privacy_flag'}


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