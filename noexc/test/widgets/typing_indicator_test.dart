import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/widgets/chat_screen/message_bubble.dart';
import 'package:noexc/models/chat_message.dart';

import '../test_helpers.dart';

void main() {
  setUp(() {
    setupQuietTesting();
  });

  testWidgets('shows typing indicator bubble for bot placeholder messages', (tester) async {
    final placeholder = ChatMessage(id: 1, text: '\u200B', sender: 'bot');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(message: placeholder),
        ),
      ),
    );

    // Should render the typing indicator instead of an empty bubble
    expect(find.byKey(const ValueKey('typing_indicator_bubble')), findsOneWidget);
  });
}

