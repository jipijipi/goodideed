import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/widgets/chat_screen/message_bubble.dart';

void main() {
  group('SystemMessageBubble', () {

    testWidgets('should not display avatar for system messages', (
      WidgetTester tester,
    ) async {
      final systemMessage = ChatMessage(
        id: 1,
        text: '[ System: Test message ]',
        type: MessageType.system,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: systemMessage),
          ),
        ),
      );

      // Should not find any avatar (CircleAvatar)
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('should handle empty system message', (
      WidgetTester tester,
    ) async {
      final systemMessage = ChatMessage(
        id: 1,
        text: '',
        type: MessageType.system,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: systemMessage),
          ),
        ),
      );

      // Should still render the structure even with empty text
      expect(find.byType(Center), findsOneWidget);
    });
  });
}