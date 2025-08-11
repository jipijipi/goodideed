import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/main.dart';
import 'package:noexc/widgets/chat_screen/chat_message_list.dart';
import 'package:noexc/services/service_locator.dart';
import 'package:noexc/widgets/chat_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    setupTestingWithMocks(); // Add platform mocks for notification service
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads chat screen', (WidgetTester tester) async {
    // Initialize ServiceLocator before testing
    ServiceLocator.reset();
    await ServiceLocator.instance.initialize();

    // Test ChatScreen directly to avoid Google Fonts theme loading issues
    await tester.pumpWidget(
      MaterialApp(
        home: const ChatScreen(),
      ),
    );

    // Initially should show loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for initialization and animations to settle
    await tester.pumpAndSettle();

    // Verify that the chat screen loads after initialization
    expect(find.byType(ChatMessageList), findsOneWidget);
    expect(find.byType(AnimatedList), findsOneWidget);
  });
}
