// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


ParserDefinition<String> createProfileParseDefinition(String result) {
  return ParserDefinition<String>(
    key: const ValueKey<String>('profile'),
    result: result,
    routing: <Pattern, ParsedResult<String>>{
      'setting': ParsedResult<String>('some_setting_flag'), //  Matches '/profile/setting'
      'privacy': ParsedResult<String>('some_privacy_flag'), //  Matches '/profile/privacy'
    },
  );
}


class ProfileContent extends StatelessWidget {
  ProfileContent({Key key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      const Text('this is profile'),
      Routable(
        parserKey: const ValueKey<String>('profile'),
        builder: (BuildContext context, dynamic flag) {
          if (flag == 'some_setting_flag') {
            return const Text('setting');
          }
          if (flag == 'some_privacy_flag') {
            return const Text('privacy');
          }
          throw Error();
        },
      )
    ]);
  }
}