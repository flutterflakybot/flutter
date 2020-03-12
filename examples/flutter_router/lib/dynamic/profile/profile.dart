// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


DynamicParserDefinition createProfileParseDefinition(dynamic result) {
  return DynamicParserDefinition(
    key: const ValueKey<String>('profile'),
    result: result,
    routing: <Pattern, Result>{
      'setting': Result('some_setting_flag'), //  Matches '/profile/setting'
      'privacy': Result('some_privacy_flag'), //  Matches '/profile/privacy'
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
          if (flag == 'setting') {
            return const Text('setting');
          }
          if (flag == 'privacy') {
            return const Text('privacy');
          }
          throw Error();
        },
      )
    ]);
  }
}