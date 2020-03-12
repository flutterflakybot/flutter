// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';


class _ProfileMainPage extends Page<void> {
  @override
  Route<void> createRoute(BuildContext context) {
    // TODO: implement createRoute
    throw UnimplementedError();
  }
}

class _ProfilePrivacyPage extends Page<void> {
  @override
  Route<void> createRoute(BuildContext context) {
    // TODO: implement createRoute
    throw UnimplementedError();
  }
}

class _ProfileSettingPage extends Page<void> {
  @override
  Route<void> createRoute(BuildContext context) {
    // TODO: implement createRoute
    throw UnimplementedError();
  }
}

ParserDefinition createProfileParseDefinition() {
  return ParserDefinition(
    routing: <Pattern, ParsedResult>{
      'setting': ParsedResult(() => _ProfileSettingPage()), //  Matches '/profile/setting'
      'privacy': ParsedResult(() => _ProfilePrivacyPage()), //  Matches '/profile/privacy'
    },
    page: () => _ProfileMainPage(), //  Matches '/profile'
  );
}