import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukhla_splitw/main.dart';

void main() {
  testWidgets('MUKHLA app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MukhlaApp());

    // Verify that splash screen shows MUKHLA text
    expect(find.text('MUKHLA'), findsOneWidget);
    expect(find.text('Kharche Pai Charcha 🔥'), findsOneWidget);
  });
}