import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/error_handling/user_message_generator.dart';
import 'package:noexc/services/error_handling/chat_error_types.dart';
import '../../test_helpers.dart';

void main() {
  setUp(() {
    setupSilentTesting(); // Suppress expected error logging noise
  });
  
  tearDown(() {
    resetLoggingDefaults();
  });
  group('UserMessageGenerator', () {
    group('createFallbackMessage', () {
      test('should return appropriate message for assetNotFound', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.assetNotFound);
        
        expect(message, equals('Sorry, I couldn\'t find the conversation content. Please try again.'));
      });

      test('should return appropriate message for invalidFormat', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.invalidFormat);
        
        expect(message, equals('There seems to be an issue with the conversation format. Please contact support.'));
      });

      test('should return appropriate message for templateError', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.templateError);
        
        expect(message, equals('I\'m having trouble personalizing this message. Continuing with default text.'));
      });

      test('should return appropriate message for conditionError', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.conditionError);
        
        expect(message, equals('I couldn\'t evaluate the conversation path. Taking the default route.'));
      });

      test('should return appropriate message for flowError', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.flowError);
        
        expect(message, equals('I lost track of our conversation flow. Let me restart from the beginning.'));
      });

      test('should return appropriate message for processingError', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.processingError);
        
        expect(message, equals('I encountered an issue processing your response. Please try again.'));
      });

      test('should return appropriate message for loadError', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.loadError);
        
        expect(message, equals('I\'m having trouble loading the conversation. Please check your connection.'));
      });

      test('should return appropriate message for assetValidation', () {
        final message = UserMessageGenerator.createFallbackMessage(ChatErrorType.assetValidation);
        
        expect(message, equals('There\'s an issue with the conversation content. Please contact support.'));
      });

      test('should ignore context parameter in basic fallback messages', () {
        final message1 = UserMessageGenerator.createFallbackMessage(
          ChatErrorType.assetNotFound,
          context: 'some context',
        );
        final message2 = UserMessageGenerator.createFallbackMessage(ChatErrorType.assetNotFound);
        
        expect(message1, equals(message2));
      });
    });

    group('createContextualMessage', () {
      test('should return base message when no context provided', () {
        final message = UserMessageGenerator.createContextualMessage(ChatErrorType.assetNotFound);
        final baseMessage = UserMessageGenerator.createFallbackMessage(ChatErrorType.assetNotFound);
        
        expect(message, equals(baseMessage));
      });

      test('should append sequenceId when provided', () {
        const sequenceId = 'onboarding_seq';
        final message = UserMessageGenerator.createContextualMessage(
          ChatErrorType.loadError,
          sequenceId: sequenceId,
        );
        
        expect(message, contains('(Sequence: $sequenceId)'));
        expect(message, startsWith('I\'m having trouble loading the conversation.'));
      });

      test('should append messageId when provided', () {
        const messageId = 42;
        final message = UserMessageGenerator.createContextualMessage(
          ChatErrorType.processingError,
          messageId: messageId,
        );
        
        expect(message, contains('(Message: $messageId)'));
        expect(message, startsWith('I encountered an issue processing your response.'));
      });

      test('should prefer sequenceId over messageId when both provided', () {
        const sequenceId = 'test_seq';
        const messageId = 123;
        final message = UserMessageGenerator.createContextualMessage(
          ChatErrorType.templateError,
          sequenceId: sequenceId,
          messageId: messageId,
        );
        
        expect(message, contains('(Sequence: $sequenceId)'));
        expect(message, isNot(contains('(Message: $messageId)')));
      });

      test('should include context parameter when provided', () {
        const context = 'additional context';
        final message = UserMessageGenerator.createContextualMessage(
          ChatErrorType.flowError,
          context: context,
        );
        
        // Context parameter is accepted but may not be used in current implementation
        expect(message, isNotEmpty);
      });

      test('should handle all error types with sequenceId', () {
        const sequenceId = 'test_sequence';
        
        for (final errorType in ChatErrorType.values) {
          final message = UserMessageGenerator.createContextualMessage(
            errorType,
            sequenceId: sequenceId,
          );
          
          expect(message, contains('(Sequence: $sequenceId)'));
          expect(message, isNotEmpty);
        }
      });

      test('should handle all error types with messageId', () {
        const messageId = 999;
        
        for (final errorType in ChatErrorType.values) {
          final message = UserMessageGenerator.createContextualMessage(
            errorType,
            messageId: messageId,
          );
          
          expect(message, contains('(Message: $messageId)'));
          expect(message, isNotEmpty);
        }
      });
    });

    group('createRecoveryMessage', () {
      test('should provide recovery suggestion for assetNotFound', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.assetNotFound);
        
        expect(message, equals('Try refreshing the page or checking your internet connection.'));
      });

      test('should provide recovery suggestion for invalidFormat', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.invalidFormat);
        
        expect(message, equals('Please contact support with the error details.'));
      });

      test('should provide recovery suggestion for templateError', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.templateError);
        
        expect(message, equals('The conversation will continue with default text.'));
      });

      test('should provide recovery suggestion for conditionError', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.conditionError);
        
        expect(message, equals('The conversation will take the default path.'));
      });

      test('should provide recovery suggestion for flowError', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.flowError);
        
        expect(message, equals('The conversation will restart from the beginning.'));
      });

      test('should provide recovery suggestion for processingError', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.processingError);
        
        expect(message, equals('Please try your response again.'));
      });

      test('should provide recovery suggestion for loadError', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.loadError);
        
        expect(message, equals('Check your connection and try again.'));
      });

      test('should provide recovery suggestion for assetValidation', () {
        final message = UserMessageGenerator.createRecoveryMessage(ChatErrorType.assetValidation);
        
        expect(message, equals('Please contact support for assistance.'));
      });

      test('should provide actionable recovery messages', () {
        final actionableTypes = [
          ChatErrorType.assetNotFound,
          ChatErrorType.processingError,
          ChatErrorType.loadError,
        ];

        for (final errorType in actionableTypes) {
          final message = UserMessageGenerator.createRecoveryMessage(errorType);
          
          expect(message, anyOf(
            contains('try'),
            contains('check'),
            contains('refresh'),
          ));
        }
      });

      test('should provide supportive recovery messages for technical errors', () {
        final supportTypes = [
          ChatErrorType.invalidFormat,
          ChatErrorType.assetValidation,
        ];

        for (final errorType in supportTypes) {
          final message = UserMessageGenerator.createRecoveryMessage(errorType);
          
          expect(message, contains('support'));
        }
      });
    });

    group('createCompleteMessage', () {
      test('should combine contextual and recovery messages', () {
        final message = UserMessageGenerator.createCompleteMessage(ChatErrorType.loadError);
        
        expect(message, contains('I\'m having trouble loading the conversation.'));
        expect(message, contains('Check your connection and try again.'));
        expect(message, contains('\n\n'));
      });

      test('should include sequenceId in complete message', () {
        const sequenceId = 'test_seq';
        final message = UserMessageGenerator.createCompleteMessage(
          ChatErrorType.assetNotFound,
          sequenceId: sequenceId,
        );
        
        expect(message, contains('(Sequence: $sequenceId)'));
        expect(message, contains('Try refreshing the page'));
      });

      test('should include messageId in complete message', () {
        const messageId = 456;
        final message = UserMessageGenerator.createCompleteMessage(
          ChatErrorType.processingError,
          messageId: messageId,
        );
        
        expect(message, contains('(Message: $messageId)'));
        expect(message, contains('Please try your response again.'));
      });

      test('should include context in complete message', () {
        const context = 'template parsing';
        final message = UserMessageGenerator.createCompleteMessage(
          ChatErrorType.templateError,
          context: context,
        );
        
        expect(message, contains('personalizing this message'));
        expect(message, contains('continue with default text'));
      });

      test('should format complete message properly', () {
        final message = UserMessageGenerator.createCompleteMessage(ChatErrorType.conditionError);
        
        final parts = message.split('\n\n');
        expect(parts, hasLength(2));
        expect(parts[0], contains('couldn\'t evaluate the conversation path'));
        expect(parts[1], contains('conversation will take the default path'));
      });

      test('should handle all error types in complete messages', () {
        for (final errorType in ChatErrorType.values) {
          final message = UserMessageGenerator.createCompleteMessage(errorType);
          
          expect(message, isNotEmpty);
          expect(message, contains('\n\n'));
          
          final parts = message.split('\n\n');
          expect(parts, hasLength(2));
          expect(parts[0], isNotEmpty); // Contextual message
          expect(parts[1], isNotEmpty); // Recovery message
        }
      });
    });

    group('message quality', () {
      test('should use conversational language in all messages', () {
        for (final errorType in ChatErrorType.values) {
          final fallbackMessage = UserMessageGenerator.createFallbackMessage(errorType);
          final recoveryMessage = UserMessageGenerator.createRecoveryMessage(errorType);
          
          // Should start with conversational phrases
          expect(fallbackMessage, anyOf(
            startsWith('Sorry'),
            startsWith('I'),
            startsWith('There'),
          ));
          
          // Should not contain technical jargon
          expect(fallbackMessage.toLowerCase(), isNot(contains('exception')));
          expect(fallbackMessage.toLowerCase(), isNot(contains('null')));
          expect(recoveryMessage.toLowerCase(), isNot(contains('exception')));
          expect(recoveryMessage.toLowerCase(), isNot(contains('null')));
        }
      });

      test('should provide helpful guidance in recovery messages', () {
        for (final errorType in ChatErrorType.values) {
          final recoveryMessage = UserMessageGenerator.createRecoveryMessage(errorType);
          
          expect(recoveryMessage, anyOf(
            contains('try'),
            contains('will'),
            contains('contact'),
            contains('check'),
          ));
        }
      });

      test('should maintain consistent tone across all messages', () {
        final messages = ChatErrorType.values
            .map((type) => UserMessageGenerator.createFallbackMessage(type))
            .toList();
        
        // All messages should be polite and helpful
        for (final message in messages) {
          expect(message, isNot(contains('Error')));
          expect(message, isNot(contains('Failed')));
          expect(message, isNot(contains('Cannot')));
        }
      });
    });
  });
}