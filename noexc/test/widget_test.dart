import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads chat screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the chat screen loads
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    
    // Just pump once to avoid timer issues
    await tester.pump();
  });
}
