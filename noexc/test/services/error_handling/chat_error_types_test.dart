import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/error_handling/chat_error_types.dart';

void main() {
  group('ChatErrorType', () {
    test('should have all expected error types', () {
      const expectedTypes = [
        ChatErrorType.assetNotFound,
        ChatErrorType.invalidFormat,
        ChatErrorType.templateError,
        ChatErrorType.conditionError,
        ChatErrorType.flowError,
        ChatErrorType.processingError,
        ChatErrorType.loadError,
        ChatErrorType.assetValidation,
      ];

      for (final type in expectedTypes) {
        expect(ChatErrorType.values.contains(type), isTrue);
      }
    });

    test('should have correct number of error types', () {
      expect(ChatErrorType.values.length, equals(8));
    });
  });

  group('ChatException', () {
    test('should create exception with message and type', () {
      const message = 'Test error message';
      const type = ChatErrorType.assetNotFound;
      
      final exception = TestChatException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
    });

    test('should generate correct toString representation', () {
      const message = 'Test error message';
      const type = ChatErrorType.templateError;
      
      final exception = TestChatException(message, type: type);
      
      expect(exception.toString(), equals('ChatException: $message'));
    });

    group('userMessage property', () {
      test('should return user-friendly message for assetNotFound', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.assetNotFound);
        
        expect(exception.userMessage, equals('Sorry, I couldn\'t find the conversation content. Please try again.'));
      });

      test('should return user-friendly message for invalidFormat', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.invalidFormat);
        
        expect(exception.userMessage, equals('There seems to be an issue with the conversation format. Please contact support.'));
      });

      test('should return user-friendly message for templateError', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.templateError);
        
        expect(exception.userMessage, equals('I\'m having trouble personalizing this message. Continuing with default text.'));
      });

      test('should return user-friendly message for conditionError', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.conditionError);
        
        expect(exception.userMessage, equals('I couldn\'t evaluate the conversation path. Taking the default route.'));
      });

      test('should return user-friendly message for flowError', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.flowError);
        
        expect(exception.userMessage, equals('I lost track of our conversation flow. Let me restart from the beginning.'));
      });

      test('should return user-friendly message for processingError', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.processingError);
        
        expect(exception.userMessage, equals('I encountered an issue processing your response. Please try again.'));
      });

      test('should return user-friendly message for loadError', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.loadError);
        
        expect(exception.userMessage, equals('I\'m having trouble loading the conversation. Please check your connection.'));
      });

      test('should return user-friendly message for assetValidation', () {
        final exception = TestChatException('Technical error', type: ChatErrorType.assetValidation);
        
        expect(exception.userMessage, equals('There\'s an issue with the conversation content. Please contact support.'));
      });
    });

    group('_createFallbackMessage static method', () {
      test('should create appropriate fallback messages for all error types', () {
        final testCases = {
          ChatErrorType.assetNotFound: 'Sorry, I couldn\'t find the conversation content. Please try again.',
          ChatErrorType.invalidFormat: 'There seems to be an issue with the conversation format. Please contact support.',
          ChatErrorType.templateError: 'I\'m having trouble personalizing this message. Continuing with default text.',
          ChatErrorType.conditionError: 'I couldn\'t evaluate the conversation path. Taking the default route.',
          ChatErrorType.flowError: 'I lost track of our conversation flow. Let me restart from the beginning.',
          ChatErrorType.processingError: 'I encountered an issue processing your response. Please try again.',
          ChatErrorType.loadError: 'I\'m having trouble loading the conversation. Please check your connection.',
          ChatErrorType.assetValidation: 'There\'s an issue with the conversation content. Please contact support.',
        };

        for (final entry in testCases.entries) {
          final exception = TestChatException('Technical error', type: entry.key);
          expect(exception.userMessage, equals(entry.value));
        }
      });

      test('should return consistent messages for same error type', () {
        final exception1 = TestChatException('Error 1', type: ChatErrorType.templateError);
        final exception2 = TestChatException('Error 2', type: ChatErrorType.templateError);
        
        expect(exception1.userMessage, equals(exception2.userMessage));
      });
    });

    group('error message characteristics', () {
      test('should have user-friendly language in all messages', () {
        for (final errorType in ChatErrorType.values) {
          final exception = TestChatException('Technical error', type: errorType);
          final userMessage = exception.userMessage;
          
          // Should not contain technical jargon
          expect(userMessage.toLowerCase(), isNot(contains('exception')));
          expect(userMessage.toLowerCase(), isNot(contains('null')));
          expect(userMessage.toLowerCase(), isNot(contains('error')));
          
          // Should be conversational
          expect(userMessage, anyOf(
            startsWith('Sorry'),
            startsWith('I'),
            startsWith('There'),
          ));
        }
      });

      test('should provide actionable guidance where appropriate', () {
        final actionableTypes = [
          ChatErrorType.assetNotFound,
          ChatErrorType.processingError,
          ChatErrorType.loadError,
        ];

        for (final errorType in actionableTypes) {
          final exception = TestChatException('Technical error', type: errorType);
          final userMessage = exception.userMessage;
          
          expect(userMessage, anyOf(
            contains('try again'),
            contains('check'),
            contains('contact'),
          ));
        }
      });

      test('should indicate continuation for recoverable errors', () {
        final recoverableTypes = [
          ChatErrorType.templateError,
          ChatErrorType.conditionError,
        ];

        for (final errorType in recoverableTypes) {
          final exception = TestChatException('Technical error', type: errorType);
          final userMessage = exception.userMessage;
          
          expect(userMessage, anyOf(
            contains('Continuing'),
            contains('Taking'),
          ));
        }
      });
    });
  });
}

/// Test implementation of ChatException for testing purposes
class TestChatException extends ChatException {
  const TestChatException(super.message, {required super.type});
}
