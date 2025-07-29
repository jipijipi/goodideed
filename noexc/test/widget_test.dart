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

    // Initially should show loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Wait for initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that the chat screen loads after initialization
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
