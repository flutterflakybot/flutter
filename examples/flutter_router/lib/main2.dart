// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


void main(){
  runApp(
    WithRouter(
      parser: SomeParser<String>(
        key: ValueKey('main'),
        map: {
          '/': RouterData<String>('Home')
          '/profile': SomeParser<String>(
            key: ValueKey('profile'),
            map: {
              'privacy': RouterData<String>('Privacy'),
              'setting': RouterData<String>('Setting'),
            }
          )
        }
      ),
      widgetTemplate: Scaffold(
        body: Column(
          children: <Widget>[
            RouterBuilder(
              key: ValueKey('profile'),
              builder((Router data) {
                if (data == 'Privacy')
                  return Logout();
              })
            ),
            RouterBuilder(
              key: ValueKey('main'),
              builder:(RouterData data) {
                if(data == '/profile')
                  RouterBuilder(
                    key: ValueKey('profile'),
                    builder:(RouterData data) {
                      if(data == 'privacy')
                    }
                  )
              }
            )



          ]
        )
      )
    )
  );
}

class RouterDelegate extends Widget {

}


/// MaterialApp with router
class WithRouter extends StatelessWidget {
  /// MaterialApp with router
  const WithRouter({Parser<dynmic> parser, Widget widgetTemplate}):super();
  @override
  Widget build(BuildContext context) {
    return SomeInheritWidgetWithParsedRouteData(
      child: widgetTemplate
    )
  }
}

class SomeParser<T> extends RouterData<T> {
  SomeParser({Key key, T data, this.map}) : super(key: key, data: data);
  final Map<String, RouterData> map;

  @override
  String parse(String routeName) {
    final matched = map.firstWhere((String pattern) => routeName.startsWith(pattern));
    data = map[matched];
    final String subRouteName = routeName.replace(pattern, '');
    return subRouteName;
  }
}

abstract class Parser<T> extends RouterData<T> {
  Parser({T data, this key}): super(data: data);
  final Key key;
  String parse(String routeName);
}

class RouterData<T> {
  RouterData({this.data});
  T data;
}