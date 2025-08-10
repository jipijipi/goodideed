import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/models/chat_message.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Clean Architecture Integration Tests', () {
    late ChatService chatService;

    setUp(() {
      setupQuietTesting();
      chatService = ChatService();
    });

    group('Basic Message Flow', () {
      test('should process messages without duplication', () async {
        // Load a sequence and get initial messages
        final initialMessages = await chatService.getInitialMessages(
          sequenceId: 'intro_seq',
        );

        // Verify we got expected message flow: message 1 → message 6 (multi-text) → message 7 (choice)
        expect(initialMessages, isNotEmpty);

        // Should have at least 3 messages: 1 from msg 1, 2 from msg 6 expansion, 1 from msg 7 choice
        expect(initialMessages.length, greaterThanOrEqualTo(3));

        // Check that we have the expected message IDs in sequence
        final messageIds = initialMessages.map((m) => m.id).toList();
        expect(messageIds, contains(1)); // First message
        expect(messageIds, contains(160)); // Second message (may be expanded)
        expect(messageIds, contains(161)); // Choice message

        // All messages should be displayable (no autoroute/dataAction in final result)
        final hasHiddenMessages = initialMessages.any(
          (m) =>
              m.type == MessageType.autoroute ||
              m.type == MessageType.dataAction,
        );
        expect(
          hasHiddenMessages,
          isFalse,
          reason:
              'Final messages should not contain autoroute or dataAction messages',
        );

        // Should end with a choice message (interactive)
        final lastMessage = initialMessages.last;
        expect(
          lastMessage.type == MessageType.choice,
          isTrue,
          reason:
              'Should end with the choice message that requires user interaction',
        );
      });

      test('should handle interactive messages correctly', () async {
        // Load intro sequence which has interactive elements
        final messages = await chatService.getInitialMessages(
          sequenceId: 'intro_seq',
        );

        // Should stop at the first interactive message (choice or textInput)
        final hasInteractiveMessage = messages.any(
          (m) =>
              m.type == MessageType.choice || m.type == MessageType.textInput,
        );
        expect(
          hasInteractiveMessage,
          isTrue,
          reason: 'Should include the interactive message that stops the flow',
        );

        // Messages before interactive should be included
        expect(messages, isNotEmpty);
      });
    });

    group('Sequence Transitions', () {
      test('should handle sequence transitions with content display', () async {
        // Load settask_seq which has a textInput → content message → sequence transition
        await chatService.loadSequence('settask_seq');

        // Simulate text input continuation (message 26 has both content and sequenceId)
        final continuationMessages = await chatService
            .getMessagesAfterTextInput(26, 'test task');

        // Should get the transitional message with content
        expect(continuationMessages, isNotEmpty);

        // The message should have the processed template content
        final hasProcessedContent = continuationMessages.any(
          (m) =>
              m.text.isNotEmpty &&
              !(m.type == MessageType.autoroute) &&
              !(m.type == MessageType.dataAction),
        );
        expect(
          hasProcessedContent,
          isTrue,
          reason:
              'Should display the transitional message content before sequence change',
        );
      });
    });

    group('Message Processing', () {
      test('should process templates correctly', () async {
        // Test with a sequence that has template variables
        await chatService.loadSequence('intro_seq');

        // Get messages - they should have templates processed
        final messages = await chatService.getMessagesAfterChoice(1);

        // Verify messages are processed (have actual content)
        expect(messages, isNotEmpty);
        for (final message in messages) {
          if (!(message.type == MessageType.choice) &&
              !(message.type == MessageType.textInput)) {
            expect(
              message.text.isNotEmpty,
              isTrue,
              reason: 'Non-interactive messages should have content',
            );
          }
        }
      });

      test('should expand multi-text messages', () async {
        // intro_seq has multi-text messages with |||
        final messages = await chatService.getInitialMessages(
          sequenceId: 'intro_seq',
        );

        // Check if we got expanded messages (more messages than raw sequence)
        expect(messages, isNotEmpty);

        // Verify no message contains ||| (they should be expanded)
        final hasUnexpandedText = messages.any((m) => m.text.contains('|||'));
        expect(
          hasUnexpandedText,
          isFalse,
          reason: 'Multi-text messages should be expanded',
        );
      });
    });

    group('Error Handling', () {
      test('should handle non-existent sequence gracefully', () async {
        // Try to load a sequence that doesn't exist
        expect(
          () => chatService.loadSequence('nonexistent_seq'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle non-existent message ID gracefully', () async {
        await chatService.loadSequence('intro_seq');

        // Try to get messages from non-existent ID
        final messages = await chatService.getMessagesAfterChoice(999);

        // Should return empty list, not crash
        expect(messages, isEmpty);
      });
    });

    group('State Management', () {
      test('should track current sequence correctly', () async {
        // Initially no sequence loaded
        expect(chatService.currentSequence, isNull);

        // Load a sequence
        await chatService.loadSequence('intro_seq');
        expect(chatService.currentSequence?.sequenceId, equals('intro_seq'));

        // Load different sequence
        await chatService.loadSequence('onboarding_seq');
        expect(
          chatService.currentSequence?.sequenceId,
          equals('onboarding_seq'),
        );
      });

      test('should handle message availability correctly', () async {
        await chatService.loadSequence('intro_seq');

        // Should have message 1
        expect(chatService.hasMessage(1), isTrue);
        expect(chatService.getMessageById(1), isNotNull);

        // Should not have random high ID
        expect(chatService.hasMessage(999), isFalse);
        expect(chatService.getMessageById(999), isNull);
      });
    });

    group('Backward Compatibility', () {
      test('should maintain existing API compatibility', () async {
        // All existing methods should still work
        expect(() => chatService.loadSequence('intro_seq'), returnsNormally);
        expect(() => chatService.getInitialMessages(), returnsNormally);
        expect(() => chatService.getMessagesAfterChoice(1), returnsNormally);
        expect(
          () => chatService.getMessagesAfterTextInput(1, 'test'),
          returnsNormally,
        );

        // State methods should work
        await chatService.loadSequence('intro_seq');
        expect(chatService.currentSequence, isNotNull);
        expect(chatService.hasMessage(1), isTrue);
        expect(chatService.getMessageById(1), isNotNull);
      });
    });
  });
}
