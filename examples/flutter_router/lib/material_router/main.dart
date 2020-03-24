// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'profile/profile.dart';


// Matches this App that uses vanilla API.
//
// void main(){
//   runApp(
//     WidgetsApp(
//       initialRoute: '/profile/privacy',
//       routes: const <String, WidgetBuilder>{
//         '': buildHomePage,
//         'dashbaord': buildDashboard,
//         'profile': buildProfileMainPage,
//         'profile/setting': buildProfileSetting,
//         'profile/privacy': buildProfilePrivacy,
//       },
//       onUnknownRoute: (RouteSettings settings) => MaterialPageRoute<dynamic>(builder: (_) => const Placeholder()),
//     )
//   );
// }


void main(){
  runApp(
    WidgetsApp.router(
      initialRoute: '/profile/privacy',
      routeNameParser: MobileRouteNameParser(
        parserDefinition: ParserDefinition<WidgetBuilder>(
          routing: <Pattern, ParsedResult<WidgetBuilder>>{
            'profile': createProfileParseDefinition(), // Matches '/profile'
            'dashbaord': ParsedResult<WidgetBuilder>(buildDashboard), // Matches '/dashboard'
            '': ParsedResult<WidgetBuilder>(buildHomePage), // Matches '/'
          },
        )
      ),
      routerDelegate: MaterialRouterDelegate(
        onUnknownRoute: (BuildContext context, String routeName) => const Placeholder(),
      ),
    )
  );
}

Widget buildDashboard(BuildContext context) {
  return const Placeholder();
}

Widget buildHomePage(BuildContext context) {
  return const Placeholder();
}
