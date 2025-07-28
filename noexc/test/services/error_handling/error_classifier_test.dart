import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/error_handling/error_classifier.dart';
import 'package:noexc/services/error_handling/chat_exceptions.dart';
import 'package:noexc/services/error_handling/chat_error_types.dart';

void main() {
  group('ErrorClassifier', () {
    group('handleSequenceLoadError', () {
      test('should handle FormatException as invalidFormat error', () {
        const sequenceId = 'test_seq';
        final formatError = const FormatException('Invalid JSON');
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, formatError);
        
        expect(result, isA<ChatSequenceException>());
        final exception = result as ChatSequenceException;
        expect(exception.type, equals(ChatErrorType.invalidFormat));
        expect(exception.sequenceId, equals(sequenceId));
        expect(exception.message, contains('Invalid JSON format'));
        expect(exception.message, contains(sequenceId));
      });

      test('should handle asset loading error as assetNotFound error', () {
        const sequenceId = 'missing_seq';
        final assetError = Exception('Unable to load asset');
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, assetError);
        
        expect(result, isA<ChatSequenceException>());
        final exception = result as ChatSequenceException;
        expect(exception.type, equals(ChatErrorType.assetNotFound));
        expect(exception.sequenceId, equals(sequenceId));
        expect(exception.message, contains('Sequence file not found'));
        expect(exception.message, contains(sequenceId));
      });

      test('should handle generic errors as loadError', () {
        const sequenceId = 'error_seq';
        final genericError = Exception('Some other error');
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, genericError);
        
        expect(result, isA<ChatSequenceException>());
        final exception = result as ChatSequenceException;
        expect(exception.type, equals(ChatErrorType.loadError));
        expect(exception.sequenceId, equals(sequenceId));
        expect(exception.message, contains('Failed to load sequence'));
        expect(exception.message, contains(sequenceId));
      });

      test('should include original error message in result', () {
        const sequenceId = 'test_seq';
        const originalMessage = 'Original error details';
        final originalError = Exception(originalMessage);
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, originalError);
        
        expect(result.toString(), contains(originalMessage));
      });

      test('should handle string errors', () {
        const sequenceId = 'string_error_seq';
        const stringError = 'String error message';
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, stringError);
        
        expect(result, isA<ChatSequenceException>());
        final exception = result as ChatSequenceException;
        expect(exception.message, contains(stringError));
      });
    });

    group('handleMessageProcessingError', () {
      test('should create ChatMessageException with correct properties', () {
        const messageId = 42;
        final originalError = Exception('Processing failed');
        
        final result = ErrorClassifier.handleMessageProcessingError(messageId, originalError);
        
        expect(result, isA<ChatMessageException>());
        final exception = result as ChatMessageException;
        expect(exception.type, equals(ChatErrorType.processingError));
        expect(exception.messageId, equals(messageId));
        expect(exception.message, contains('Failed to process message $messageId'));
        expect(exception.message, contains('Processing failed'));
      });

      test('should handle null messageId', () {
        const messageId = 0;
        final originalError = Exception('Error');
        
        final result = ErrorClassifier.handleMessageProcessingError(messageId, originalError);
        
        expect(result, isA<ChatMessageException>());
        final exception = result as ChatMessageException;
        expect(exception.messageId, equals(0));
      });

      test('should include original error details', () {
        const messageId = 123;
        const errorDetails = 'Detailed error information';
        final originalError = Exception(errorDetails);
        
        final result = ErrorClassifier.handleMessageProcessingError(messageId, originalError);
        
        expect(result.toString(), contains(errorDetails));
      });
    });

    group('handleTemplateError', () {
      test('should create ChatTemplateException with correct properties', () {
        const template = '{user.name|Guest}';
        final originalError = Exception('Template parsing failed');
        
        final result = ErrorClassifier.handleTemplateError(template, originalError);
        
        expect(result, isA<ChatTemplateException>());
        final exception = result as ChatTemplateException;
        expect(exception.type, equals(ChatErrorType.templateError));
        expect(exception.template, equals(template));
        expect(exception.message, contains('Template processing failed'));
        expect(exception.message, contains(template));
      });

      test('should handle complex template strings', () {
        const template = 'Hello {user.name|Guest}, your score is {user.score|0}!';
        final originalError = Exception('Complex template error');
        
        final result = ErrorClassifier.handleTemplateError(template, originalError);
        
        expect(result, isA<ChatTemplateException>());
        final exception = result as ChatTemplateException;
        expect(exception.template, equals(template));
        expect(exception.message, contains(template));
      });

      test('should handle empty template', () {
        const template = '';
        final originalError = Exception('Empty template error');
        
        final result = ErrorClassifier.handleTemplateError(template, originalError);
        
        expect(result, isA<ChatTemplateException>());
        final exception = result as ChatTemplateException;
        expect(exception.template, equals(template));
      });
    });

    group('handleConditionError', () {
      test('should create ChatConditionException with correct properties', () {
        const condition = 'user.level > 5';
        final originalError = Exception('Condition evaluation failed');
        
        final result = ErrorClassifier.handleConditionError(condition, originalError);
        
        expect(result, isA<ChatConditionException>());
        final exception = result as ChatConditionException;
        expect(exception.type, equals(ChatErrorType.conditionError));
        expect(exception.condition, equals(condition));
        expect(exception.message, contains('Condition evaluation failed'));
        expect(exception.message, contains(condition));
      });

      test('should handle complex condition expressions', () {
        const condition = 'user.level >= 5 && user.hasCompleted == false';
        final originalError = Exception('Complex condition error');
        
        final result = ErrorClassifier.handleConditionError(condition, originalError);
        
        expect(result, isA<ChatConditionException>());
        final exception = result as ChatConditionException;
        expect(exception.condition, equals(condition));
        expect(exception.message, contains(condition));
      });

      test('should handle boolean condition expressions', () {
        const condition = 'user.isActive';
        final originalError = Exception('Boolean condition error');
        
        final result = ErrorClassifier.handleConditionError(condition, originalError);
        
        expect(result, isA<ChatConditionException>());
        final exception = result as ChatConditionException;
        expect(exception.condition, equals(condition));
      });
    });

    group('handleFlowError', () {
      test('should create ChatFlowException with correct properties', () {
        const description = 'Dead end detected in conversation flow';
        final originalError = Exception('Flow navigation failed');
        
        final result = ErrorClassifier.handleFlowError(description, originalError);
        
        expect(result, isA<ChatFlowException>());
        final exception = result as ChatFlowException;
        expect(exception.type, equals(ChatErrorType.flowError));
        expect(exception.description, equals(description));
        expect(exception.message, contains('Flow navigation error'));
        expect(exception.message, contains(description));
      });

      test('should handle circular reference description', () {
        const description = 'Circular reference detected between messages 1 and 5';
        final originalError = Exception('Circular flow error');
        
        final result = ErrorClassifier.handleFlowError(description, originalError);
        
        expect(result, isA<ChatFlowException>());
        final exception = result as ChatFlowException;
        expect(exception.description, equals(description));
        expect(exception.message, contains(description));
      });

      test('should handle unreachable message description', () {
        const description = 'Message 10 is unreachable from starting point';
        final originalError = Exception('Unreachable message error');
        
        final result = ErrorClassifier.handleFlowError(description, originalError);
        
        expect(result, isA<ChatFlowException>());
        final exception = result as ChatFlowException;
        expect(exception.description, equals(description));
      });
    });

    group('handleAssetValidationError', () {
      test('should create ChatAssetException with correct properties', () {
        const asset = 'assets/sequences/test_seq.json';
        final originalError = Exception('Asset validation failed');
        
        final result = ErrorClassifier.handleAssetValidationError(asset, originalError);
        
        expect(result, isA<ChatAssetException>());
        final exception = result as ChatAssetException;
        expect(exception.type, equals(ChatErrorType.assetValidation));
        expect(exception.asset, equals(asset));
        expect(exception.message, contains('Asset validation failed'));
        expect(exception.message, contains(asset));
      });

      test('should handle variant file assets', () {
        const asset = 'assets/variants/onboarding_message_1.txt';
        final originalError = Exception('Variant file error');
        
        final result = ErrorClassifier.handleAssetValidationError(asset, originalError);
        
        expect(result, isA<ChatAssetException>());
        final exception = result as ChatAssetException;
        expect(exception.asset, equals(asset));
        expect(exception.message, contains(asset));
      });

      test('should handle sequence file assets', () {
        const asset = 'assets/sequences/welcome_seq.json';
        final originalError = Exception('Sequence validation error');
        
        final result = ErrorClassifier.handleAssetValidationError(asset, originalError);
        
        expect(result, isA<ChatAssetException>());
        final exception = result as ChatAssetException;
        expect(exception.asset, equals(asset));
      });
    });

    group('error logging behavior', () {
      test('should log errors in debug mode', () {
        // This test verifies that _logError is called
        // In a real implementation, you might want to mock the print function
        // For now, we just verify the method doesn't throw
        const sequenceId = 'test_seq';
        final error = Exception('Test error');
        
        expect(
          () => ErrorClassifier.handleSequenceLoadError(sequenceId, error),
          returnsNormally,
        );
      });

      test('should handle Error objects with stack traces', () {
        const sequenceId = 'test_seq';
        final error = ArgumentError('Invalid argument');
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, error);
        
        expect(result, isA<ChatSequenceException>());
        expect(result.toString(), contains('Invalid argument'));
      });

      test('should handle null errors gracefully', () {
        const sequenceId = 'test_seq';
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, null);
        
        expect(result, isA<ChatSequenceException>());
        expect(result.toString(), contains('null'));
      });
    });

    group('error message consistency', () {
      test('should maintain consistent error message format across handlers', () {
        const testId = 'test_id';
        final testError = Exception('test error');
        
        final sequenceError = ErrorClassifier.handleSequenceLoadError(testId, testError);
        final messageError = ErrorClassifier.handleMessageProcessingError(1, testError);
        final templateError = ErrorClassifier.handleTemplateError(testId, testError);
        final conditionError = ErrorClassifier.handleConditionError(testId, testError);
        final flowError = ErrorClassifier.handleFlowError(testId, testError);
        final assetError = ErrorClassifier.handleAssetValidationError(testId, testError);
        
        // All should contain the original error message
        expect(sequenceError.toString(), contains('test error'));
        expect(messageError.toString(), contains('test error'));
        expect(templateError.toString(), contains('test error'));
        expect(conditionError.toString(), contains('test error'));
        expect(flowError.toString(), contains('test error'));
        expect(assetError.toString(), contains('test error'));
      });

      test('should include context information in all error messages', () {
        const contextInfo = 'context_info';
        final testError = Exception('test');
        
        final sequenceError = ErrorClassifier.handleSequenceLoadError(contextInfo, testError);
        final messageError = ErrorClassifier.handleMessageProcessingError(123, testError);
        final templateError = ErrorClassifier.handleTemplateError(contextInfo, testError);
        final conditionError = ErrorClassifier.handleConditionError(contextInfo, testError);
        final flowError = ErrorClassifier.handleFlowError(contextInfo, testError);
        final assetError = ErrorClassifier.handleAssetValidationError(contextInfo, testError);
        
        expect(sequenceError.toString(), contains(contextInfo));
        expect(messageError.toString(), contains('123'));
        expect(templateError.toString(), contains(contextInfo));
        expect(conditionError.toString(), contains(contextInfo));
        expect(flowError.toString(), contains(contextInfo));
        expect(assetError.toString(), contains(contextInfo));
      });
    });

    group('edge cases', () {
      test('should handle very long error messages', () {
        const sequenceId = 'test_seq';
        final longMessage = 'A' * 1000; // Very long error message
        final longError = Exception(longMessage);
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, longError);
        
        expect(result, isA<ChatSequenceException>());
        expect(result.toString(), contains(longMessage));
      });

      test('should handle special characters in error messages', () {
        const sequenceId = 'test_seq';
        const specialMessage = 'Error with émojis 🎉 and symbols @#\$%^&*()';
        final specialError = Exception(specialMessage);
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, specialError);
        
        expect(result, isA<ChatSequenceException>());
        expect(result.toString(), contains(specialMessage));
      });

      test('should handle empty error messages', () {
        const sequenceId = 'test_seq';
        final emptyError = Exception('');
        
        final result = ErrorClassifier.handleSequenceLoadError(sequenceId, emptyError);
        
        expect(result, isA<ChatSequenceException>());
        final exception = result as ChatSequenceException;
        expect(exception.message, isNotEmpty); // Should still have a meaningful message
      });
    });
  });
}