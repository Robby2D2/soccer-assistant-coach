// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soccer_assistant_coach/app.dart';

void main() {
  testWidgets('SoccerApp renders a MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoccerApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
    // Unmount to allow any streams/timers to cancel cleanly before test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
