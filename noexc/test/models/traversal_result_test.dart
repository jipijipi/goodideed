import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/traversal_result.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('TraversalResult', () {
    final mockMessage = ChatMessage(id: 1, text: 'Test message');
    final mockMessages = [mockMessage];

    group('constructor', () {
      test('should create instance with required parameters', () {
        final result = TraversalResult(
          messages: mockMessages,
          stopReason: TraversalStopReason.endOfSequence,
        );

        expect(result.messages, equals(mockMessages));
        expect(result.stopReason, equals(TraversalStopReason.endOfSequence));
        expect(result.nextMessageId, isNull);
        expect(result.targetSequenceId, isNull);
        expect(result.errorMessage, isNull);
      });

      test('should create instance with all parameters', () {
        final result = TraversalResult(
          messages: mockMessages,
          stopReason: TraversalStopReason.sequenceTransition,
          nextMessageId: 5,
          targetSequenceId: 'test_seq',
          errorMessage: 'Test error',
        );

        expect(result.messages, equals(mockMessages));
        expect(result.stopReason, equals(TraversalStopReason.sequenceTransition));
        expect(result.nextMessageId, equals(5));
        expect(result.targetSequenceId, equals('test_seq'));
        expect(result.errorMessage, equals('Test error'));
      });
    });

    group('factory constructors', () {
      test('success factory should create successful result', () {
        final result = TraversalResult.success(
          messages: mockMessages,
          stopReason: TraversalStopReason.interactiveMessage,
          nextMessageId: 3,
        );

        expect(result.messages, equals(mockMessages));
        expect(result.stopReason, equals(TraversalStopReason.interactiveMessage));
        expect(result.nextMessageId, equals(3));
        expect(result.isSuccess, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('error factory should create error result', () {
        final result = TraversalResult.error(
          errorMessage: 'Something went wrong',
          messages: mockMessages,
        );

        expect(result.messages, equals(mockMessages));
        expect(result.stopReason, equals(TraversalStopReason.error));
        expect(result.errorMessage, equals('Something went wrong'));
        expect(result.isSuccess, isFalse);
      });

      test('error factory should use empty messages if not provided', () {
        final result = TraversalResult.error(
          errorMessage: 'Something went wrong',
        );

        expect(result.messages, isEmpty);
        expect(result.stopReason, equals(TraversalStopReason.error));
        expect(result.errorMessage, equals('Something went wrong'));
        expect(result.isSuccess, isFalse);
      });
    });

    group('computed properties', () {
      test('isSuccess should return true for non-error results', () {
        final successfulResults = [
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.endOfSequence),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.interactiveMessage),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.sequenceTransition),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.maxDepthReached),
        ];

        for (final result in successfulResults) {
          expect(result.isSuccess, isTrue, reason: 'Expected ${result.stopReason} to be successful');
        }
      });

      test('isSuccess should return false for error results', () {
        final errorResult = TraversalResult.error(errorMessage: 'Test error');
        expect(errorResult.isSuccess, isFalse);
      });

      test('requiresSequenceTransition should return true only for sequence transition', () {
        final transitionResult = TraversalResult.success(
          messages: mockMessages,
          stopReason: TraversalStopReason.sequenceTransition,
        );
        expect(transitionResult.requiresSequenceTransition, isTrue);

        final otherResults = [
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.endOfSequence),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.interactiveMessage),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.maxDepthReached),
          TraversalResult.error(errorMessage: 'Test error'),
        ];

        for (final result in otherResults) {
          expect(result.requiresSequenceTransition, isFalse,
              reason: 'Expected ${result.stopReason} to not require sequence transition');
        }
      });

      test('hasUserInteraction should return true only for interactive message', () {
        final interactiveResult = TraversalResult.success(
          messages: mockMessages,
          stopReason: TraversalStopReason.interactiveMessage,
        );
        expect(interactiveResult.hasUserInteraction, isTrue);

        final otherResults = [
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.endOfSequence),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.sequenceTransition),
          TraversalResult.success(messages: mockMessages, stopReason: TraversalStopReason.maxDepthReached),
          TraversalResult.error(errorMessage: 'Test error'),
        ];

        for (final result in otherResults) {
          expect(result.hasUserInteraction, isFalse,
              reason: 'Expected ${result.stopReason} to not have user interaction');
        }
      });
    });

    group('toString', () {
      test('should return descriptive string representation', () {
        final result = TraversalResult.success(
          messages: mockMessages,
          stopReason: TraversalStopReason.sequenceTransition,
          nextMessageId: 5,
          targetSequenceId: 'test_seq',
        );

        final string = result.toString();
        expect(string, contains('TraversalResult'));
        expect(string, contains('messages: 1'));
        expect(string, contains('stopReason: TraversalStopReason.sequenceTransition'));
        expect(string, contains('nextMessageId: 5'));
        expect(string, contains('targetSequenceId: test_seq'));
      });
    });
  });
}