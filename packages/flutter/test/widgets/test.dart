import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Does Text', (WidgetTester tester) async {
    await tester.pumpWidget(const Text('tight'));
    await tester.pumpWidget(const SizedBox(child: Text('loose')));
  });
}