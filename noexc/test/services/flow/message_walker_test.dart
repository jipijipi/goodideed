import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/flow/message_walker.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/walk_result.dart';

import '../../test_helpers.dart';

/// Test implementation of MessageProvider
class TestMessageProvider implements MessageProvider {
  final Map<int, ChatMessage> _messages = {};

  void addMessage(ChatMessage message) {
    _messages[message.id] = message;
  }

  void clear() {
    _messages.clear();
  }

  @override
  bool hasMessage(int id) {
    return _messages.containsKey(id);
  }

  @override
  ChatMessage? getMessage(int id) {
    return _messages[id];
  }
}

void main() {
  group('MessageWalker', () {
    late MessageWalker walker;
    late TestMessageProvider provider;

    setUp(() {
      setupQuietTesting();
      walker = MessageWalker();
      provider = TestMessageProvider();
    });

    group('Basic Walking', () {
      test(
        'should return empty result when starting message does not exist',
        () {
          // Act
          final result = walker.walkFrom(1, provider);

          // Assert
          expect(result.messages, isEmpty);
          expect(result.stopReason, equals(WalkStopReason.endOfChain));
          expect(result.isValid, isTrue);
          expect(result.walkDepth, equals(1));
        },
      );

      test('should collect single message', () {
        // Arrange
        final message = ChatMessage(id: 1, text: 'Hello');
        provider.addMessage(message);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(1));
        expect(result.messages.first.id, equals(1));
        expect(result.stopReason, equals(WalkStopReason.endOfChain));
        expect(result.isValid, isTrue);
      });

      test('should follow nextMessageId chain', () {
        // Arrange
        final message1 = ChatMessage(id: 1, text: 'First', nextMessageId: 5);
        final message5 = ChatMessage(id: 5, text: 'Fifth');
        provider.addMessage(message1);
        provider.addMessage(message5);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2));
        expect(result.messages[0].id, equals(1));
        expect(result.messages[1].id, equals(5));
        expect(result.stopReason, equals(WalkStopReason.endOfChain));
      });

      test('should follow sequential IDs when nextMessageId not specified', () {
        // Arrange
        final message1 = ChatMessage(id: 1, text: 'First');
        final message2 = ChatMessage(id: 2, text: 'Second');
        provider.addMessage(message1);
        provider.addMessage(message2);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2));
        expect(result.messages[0].id, equals(1));
        expect(result.messages[1].id, equals(2));
      });
    });

    group('Stop Conditions', () {
      test('should stop at choice message', () {
        // Arrange
        final botMessage = ChatMessage(
          id: 1,
          text: 'Question',
          nextMessageId: 2,
        );
        final choiceMessage = ChatMessage(
          id: 2,
          text: '',
          type: MessageType.choice,
        );
        provider.addMessage(botMessage);
        provider.addMessage(choiceMessage);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2));
        expect(result.stopReason, equals(WalkStopReason.interactiveMessage));
        expect(result.requiresUserInteraction, isTrue);
        expect(result.stopMessageId, equals(2));
      });

      test('should stop at textInput message', () {
        // Arrange
        final botMessage = ChatMessage(
          id: 1,
          text: 'Enter name',
          nextMessageId: 2,
        );
        final inputMessage = ChatMessage(
          id: 2,
          text: '',
          type: MessageType.textInput,
        );
        provider.addMessage(botMessage);
        provider.addMessage(inputMessage);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2));
        expect(result.stopReason, equals(WalkStopReason.interactiveMessage));
        expect(result.requiresUserInteraction, isTrue);
        expect(result.stopMessageId, equals(2));
      });

      test('should stop at sequence boundary', () {
        // Arrange
        final message1 = ChatMessage(
          id: 1,
          text: 'Before transition',
          nextMessageId: 2,
        );
        final transitionMessage = ChatMessage(
          id: 2,
          text: 'Transitioning',
          sequenceId: 'next_seq',
        );
        provider.addMessage(message1);
        provider.addMessage(transitionMessage);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2));
        expect(result.stopReason, equals(WalkStopReason.sequenceBoundary));
        expect(result.requiresSequenceTransition, isTrue);
        expect(result.targetSequenceId, equals('next_seq'));
        expect(result.stopMessageId, equals(2));
      });
    });

    group('Special Messages', () {
      test('should stop at autoroute messages for route processing', () {
        // Arrange
        final botMessage = ChatMessage(
          id: 1,
          text: 'Before autoroute',
          nextMessageId: 2,
        );
        final autorouteMessage = ChatMessage(
          id: 2,
          text: '',
          type: MessageType.autoroute,
          nextMessageId: 3,
        );
        final afterMessage = ChatMessage(id: 3, text: 'After autoroute');
        provider.addMessage(botMessage);
        provider.addMessage(autorouteMessage);
        provider.addMessage(afterMessage);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(2)); // Only collects bot + autoroute
        expect(result.messages[0].id, equals(1));
        expect(result.messages[1].id, equals(2));
        expect(result.stopReason, equals(WalkStopReason.endOfChain));
        expect(result.stopMessageId, equals(2)); // Stops at autoroute message
      });

      test('should collect dataAction messages without stopping', () {
        // Arrange
        final botMessage = ChatMessage(
          id: 1,
          text: 'Before data action',
          nextMessageId: 2,
        );
        final dataMessage = ChatMessage(
          id: 2,
          text: '',
          type: MessageType.dataAction,
          nextMessageId: 3,
        );
        final afterMessage = ChatMessage(id: 3, text: 'After data action');
        provider.addMessage(botMessage);
        provider.addMessage(dataMessage);
        provider.addMessage(afterMessage);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(3));
        expect(result.messages[0].id, equals(1));
        expect(result.messages[1].id, equals(2));
        expect(result.messages[2].id, equals(3));
        expect(result.stopReason, equals(WalkStopReason.endOfChain));
      });
    });

    group('Safety Mechanisms', () {
      test('should prevent infinite loops with max depth', () {
        // Arrange - Create circular reference
        final message1 = ChatMessage(id: 1, text: 'First', nextMessageId: 2);
        final message2 = ChatMessage(id: 2, text: 'Second', nextMessageId: 1);
        provider.addMessage(message1);
        provider.addMessage(message2);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.stopReason, equals(WalkStopReason.maxDepthReached));
        expect(result.isValid, isFalse);
        expect(result.walkDepth, equals(50)); // Max depth reached
      });
    });

    group('Complex Scenarios', () {
      test('should handle mixed message types correctly', () {
        // Arrange - bot → data action → autoroute → choice
        final messages = [
          ChatMessage(id: 1, text: 'Start', nextMessageId: 2),
          ChatMessage(
            id: 2,
            text: '',
            type: MessageType.dataAction,
            nextMessageId: 3,
          ),
          ChatMessage(
            id: 3,
            text: '',
            type: MessageType.autoroute,
            nextMessageId: 4,
          ),
          ChatMessage(id: 4, text: '', type: MessageType.choice),
        ];

        for (final msg in messages) {
          provider.addMessage(msg);
        }

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(
          result.messages,
          hasLength(3),
        ); // Stops at autoroute, doesn't reach choice
        expect(result.stopReason, equals(WalkStopReason.endOfChain));
        expect(result.stopMessageId, equals(3)); // Stops at autoroute message
      });

      test('should handle sequence transition with content', () {
        // Arrange - message with both text and sequenceId
        final message = ChatMessage(
          id: 1,
          text: 'Moving to next sequence now',
          sequenceId: 'next_seq',
        );
        provider.addMessage(message);

        // Act
        final result = walker.walkFrom(1, provider);

        // Assert
        expect(result.messages, hasLength(1));
        expect(result.messages.first.text, contains('Moving to next'));
        expect(result.stopReason, equals(WalkStopReason.sequenceBoundary));
        expect(result.targetSequenceId, equals('next_seq'));
      });
    });
  });
}
