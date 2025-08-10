import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service/message_processor.dart';
import 'package:noexc/services/semantic_content_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/choice.dart';
import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageProcessor Semantic Content Integration', () {
    late MessageProcessor processor;
    late SemanticContentService semanticService;

    setUp(() {
      setupQuietTesting();
      semanticService = SemanticContentService.instance;
      semanticService.clearCache();
      processor = MessageProcessor();
    });

    group('Bot Message Processing', () {
      test('should process message with contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Original fallback text',
          type: MessageType.bot,
          contentKey: 'bot.acknowledge.completion.positive',
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        expect(
          processed.contentKey,
          equals('bot.acknowledge.completion.positive'),
        );
        // Content should be resolved (not original fallback)
        expect(processed.text, isNot(equals('Original fallback text')));
        expect(processed.text.isNotEmpty, isTrue);
      });

      test('should handle message without contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Regular message text',
          type: MessageType.bot,
          contentKey: null,
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        expect(processed.text, equals('Regular message text'));
        expect(processed.contentKey, isNull);
      });

      test('should handle empty contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Regular message text',
          type: MessageType.bot,
          contentKey: '',
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        expect(processed.text, equals('Regular message text'));
        expect(processed.contentKey, equals(''));
      });

      test(
        'should preserve other message fields when processing contentKey',
        () async {
          final message = ChatMessage(
            id: 42,
            text: 'Original text',
            type: MessageType.bot,
            delay: 2000,
            nextMessageId: 43,
            contentKey: 'bot.inform.welcome.casual',
          );

          final sequence = ChatSequence(
            sequenceId: 'test_seq',
            name: 'Test Sequence',
            description: 'Test sequence for semantic content',
            messages: [message],
          );

          final processed = await processor.processMessageTemplate(
            message,
            sequence,
          );

          expect(processed.id, equals(42));
          expect(processed.type, equals(MessageType.bot));
          expect(processed.delay, equals(2000));
          expect(processed.nextMessageId, equals(43));
          expect(processed.contentKey, equals('bot.inform.welcome.casual'));
        },
      );
    });

    group('Choice Message Processing', () {
      test('should process choice message with contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: '', // Choice messages have empty text
          type: MessageType.choice,
          contentKey: 'bot.request.task_status.gentle',
          choices: [
            Choice(
              text: 'Completed',
              contentKey: 'user.choose.task_status.completed',
            ),
            Choice(
              text: 'Failed',
              contentKey: 'user.choose.task_status.failed',
            ),
          ],
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        expect(processed.contentKey, equals('bot.request.task_status.gentle'));
        expect(processed.choices!.length, equals(2));
        expect(
          processed.choices![0].contentKey,
          equals('user.choose.task_status.completed'),
        );
        expect(
          processed.choices![1].contentKey,
          equals('user.choose.task_status.failed'),
        );

        // Choice text should be resolved via semantic content
        expect(processed.choices![0].text, isNot(equals('Completed')));
        expect(processed.choices![1].text, isNot(equals('Failed')));
      });

      test('should handle choices without contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: '',
          type: MessageType.choice,
          choices: [Choice(text: 'Option 1'), Choice(text: 'Option 2')],
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        expect(processed.choices![0].text, equals('Option 1'));
        expect(processed.choices![1].text, equals('Option 2'));
        expect(processed.choices![0].contentKey, isNull);
        expect(processed.choices![1].contentKey, isNull);
      });

      test(
        'should handle mixed choices (some with contentKey, some without)',
        () async {
          final message = ChatMessage(
            id: 1,
            text: '',
            type: MessageType.choice,
            choices: [
              Choice(
                text: 'Completed',
                contentKey: 'user.choose.task_status.completed',
              ),
              Choice(text: 'Custom option'), // No contentKey
            ],
          );

          final sequence = ChatSequence(
            sequenceId: 'test_seq',
            name: 'Test Sequence',
            description: 'Test sequence for semantic content',
            messages: [message],
          );

          final processed = await processor.processMessageTemplate(
            message,
            sequence,
          );

          // First choice should be resolved
          expect(processed.choices![0].text, isNot(equals('Completed')));
          expect(
            processed.choices![0].contentKey,
            equals('user.choose.task_status.completed'),
          );

          // Second choice should remain unchanged
          expect(processed.choices![1].text, equals('Custom option'));
          expect(processed.choices![1].contentKey, isNull);
        },
      );
    });

    group('Multi-text Message Processing', () {
      test('should process multi-text message with contentKey', () async {
        final message = ChatMessage(
          id: 1,
          text: 'First part ||| Second part ||| Third part',
          type: MessageType.bot,
          contentKey: 'bot.inform.multi_welcome.casual',
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        // Multi-text messages should be processed as-is in MessageProcessor
        // ContentKey handling happens at display time
        expect(processed.contentKey, equals('bot.inform.multi_welcome.casual'));
        expect(processed.hasMultipleTexts, isTrue);
      });
    });

    group('Legacy Compatibility', () {
      test(
        'should maintain backward compatibility with legacy variant system',
        () async {
          final message = ChatMessage(
            id: 1,
            text: 'Legacy message text',
            type: MessageType.bot,
            contentKey: null, // No contentKey - should use legacy system
          );

          final sequence = ChatSequence(
            sequenceId: 'test_seq',
            name: 'Test Sequence',
            description: 'Test sequence for semantic content',
            messages: [message],
          );

          final processed = await processor.processMessageTemplate(
            message,
            sequence,
          );

          // Should process through legacy variant system
          expect(processed.text, isNotNull);
          expect(processed.contentKey, isNull);
        },
      );

      test(
        'should prioritize semantic content over legacy variants when contentKey present',
        () async {
          final message = ChatMessage(
            id: 1,
            text: 'Legacy fallback text',
            type: MessageType.bot,
            contentKey: 'bot.acknowledge.completion.positive',
          );

          final sequence = ChatSequence(
            sequenceId: 'test_seq',
            name: 'Test Sequence',
            description: 'Test sequence for semantic content',
            messages: [message],
          );

          final processed = await processor.processMessageTemplate(
            message,
            sequence,
          );

          // Should use semantic content, not legacy system
          expect(processed.text, isNot(equals('Legacy fallback text')));
          expect(
            processed.contentKey,
            equals('bot.acknowledge.completion.positive'),
          );
        },
      );
    });

    group('Template Processing Integration', () {
      test(
        'should apply template processing after semantic content resolution',
        () async {
          final message = ChatMessage(
            id: 1,
            text: 'Fallback with {user.name|friend}',
            type: MessageType.bot,
            contentKey: 'bot.acknowledge.completion.positive',
          );

          final sequence = ChatSequence(
            sequenceId: 'test_seq',
            name: 'Test Sequence',
            description: 'Test sequence for semantic content',
            messages: [message],
          );

          final processed = await processor.processMessageTemplate(
            message,
            sequence,
          );

          // Text should be resolved via semantic content AND templates processed
          expect(
            processed.text,
            isNot(equals('Fallback with {user.name|friend}')),
          );
          expect(processed.text.isNotEmpty, isTrue);
        },
      );
    });

    group('Error Handling', () {
      test('should handle malformed semantic keys gracefully', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Fallback text',
          type: MessageType.bot,
          contentKey: 'invalid.key', // Invalid semantic key
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        final processed = await processor.processMessageTemplate(
          message,
          sequence,
        );

        // Should fallback to original text
        expect(processed.text, equals('Fallback text'));
        expect(processed.contentKey, equals('invalid.key'));
      });

      test('should handle null sequence gracefully', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Test message',
          type: MessageType.bot,
          contentKey: 'bot.inform.test',
        );

        final processed = await processor.processMessageTemplate(message, null);

        // Should not crash and should handle gracefully
        expect(processed.text, isNotNull);
        expect(processed.contentKey, equals('bot.inform.test'));
      });
    });

    group('Performance and Caching', () {
      test('should cache content resolution for repeated requests', () async {
        final message = ChatMessage(
          id: 1,
          text: 'Fallback text',
          type: MessageType.bot,
          contentKey: 'bot.acknowledge.completion.positive',
        );

        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test sequence for semantic content',
          messages: [message],
        );

        // Process same message multiple times
        final processed1 = await processor.processMessageTemplate(
          message,
          sequence,
        );
        final processed2 = await processor.processMessageTemplate(
          message,
          sequence,
        );

        // Results should be consistent (cached)
        expect(processed1.text, equals(processed2.text));
      });
    });
  });
}
