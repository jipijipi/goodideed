import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noexc/main.dart';

void main() {
  testWidgets('App loads chat screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the chat screen loads
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Clean up any pending timers
    await tester.pumpAndSettle();
  });
}
