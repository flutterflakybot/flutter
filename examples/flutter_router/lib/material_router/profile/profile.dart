// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


ParserDefinition<WidgetBuilder> createProfileParseDefinition() {
  return ParserDefinition<WidgetBuilder>(
    result: buildProfileMainPage, // Matches '/profile'
    routing: <Pattern, ParsedResult<WidgetBuilder>>{
      'setting': ParsedResult<WidgetBuilder>(buildProfileSetting), //  Matches '/profile/setting'
      'privacy': ParsedResult<WidgetBuilder>(buildProfilePrivacy), //  Matches '/profile/privacy'
    },
  );
}


Widget buildProfileMainPage(BuildContext context) {
  return const Placeholder();
}

Widget buildProfileSetting(BuildContext context) {
  return const Placeholder();
}

Widget buildProfilePrivacy(BuildContext context) {
  return const Placeholder();
}