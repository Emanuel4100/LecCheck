// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/leccheck_root.dart';
import 'package:flutter_app/main.dart';

void main() {
  tearDown(() {
    LecCheckRoot.debugBootstrapOverride = null;
  });

  testWidgets('LecCheck login renders', (WidgetTester tester) async {
    LecCheckRoot.debugBootstrapOverride = () async => (root: null, user: null);
    await tester.pumpWidget(const LecCheckApp());
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Welcome to LecCheck').evaluate().isNotEmpty) break;
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Welcome to LecCheck'), findsOneWidget);
    expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
  });
}
