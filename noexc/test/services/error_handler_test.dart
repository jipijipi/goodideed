import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/error_handler.dart';

void main() {
  group('ChatErrorHandler', () {
    group('Error Type Handling', () {
      test('should handle sequence load errors correctly', () {
        final error = FormatException('Invalid JSON');
        final exception = ChatErrorHandler.handleSequenceLoadError('test_sequence', error);
        
        expect(exception, isA<ChatSequenceException>());
        expect(exception.toString(), contains('test_sequence'));
        expect((exception as ChatSequenceException).type, ChatErrorType.invalidFormat);
      });
      
      test('should handle asset not found errors', () {
        final error = Exception('Unable to load asset');
        final exception = ChatErrorHandler.handleSequenceLoadError('missing_sequence', error);
        
        expect(exception, isA<ChatSequenceException>());
        expect((exception as ChatSequenceException).type, ChatErrorType.assetNotFound);
      });
      
      test('should handle message processing errors', () {
        final error = Exception('Processing failed');
        final exception = ChatErrorHandler.handleMessageProcessingError(123, error);
        
        expect(exception, isA<ChatMessageException>());
        expect((exception as ChatMessageException).messageId, 123);
        expect(exception.type, ChatErrorType.processingError);
      });
      
      test('should handle template errors', () {
        final error = Exception('Template parsing failed');
        final exception = ChatErrorHandler.handleTemplateError('{invalid', error);
        
        expect(exception, isA<ChatTemplateException>());
        expect((exception as ChatTemplateException).template, '{invalid');
        expect(exception.type, ChatErrorType.templateError);
      });
      
      test('should handle condition errors', () {
        final error = Exception('Condition evaluation failed');
        final exception = ChatErrorHandler.handleConditionError('user.age > invalid', error);
        
        expect(exception, isA<ChatConditionException>());
        expect((exception as ChatConditionException).condition, 'user.age > invalid');
        expect(exception.type, ChatErrorType.conditionError);
      });
      
      test('should handle flow errors', () {
        final error = Exception('Flow navigation failed');
        final exception = ChatErrorHandler.handleFlowError('Invalid route', error);
        
        expect(exception, isA<ChatFlowException>());
        expect((exception as ChatFlowException).description, 'Invalid route');
        expect(exception.type, ChatErrorType.flowError);
      });
      
      test('should handle asset validation errors', () {
        final error = Exception('Asset validation failed');
        final exception = ChatErrorHandler.handleAssetValidationError('sequence.json', error);
        
        expect(exception, isA<ChatAssetException>());
        expect((exception as ChatAssetException).asset, 'sequence.json');
        expect(exception.type, ChatErrorType.assetValidation);
      });
    });
    
    group('Fallback Messages', () {
      test('should provide user-friendly messages for all error types', () {
        final errorTypes = ChatErrorType.values;
        
        for (final errorType in errorTypes) {
          final message = ChatErrorHandler.createFallbackMessage(errorType);
          
          expect(message, isNotEmpty);
          expect(message, isNot(contains('Exception')));
          expect(message, isNot(contains('Error')));
          expect(message, isNot(contains('null')));
          
          // Should be user-friendly
          expect(message, anyOf([
            contains('Sorry'),
            contains('I\'m having trouble'),
            contains('I encountered'),
            contains('There seems to be'),
            contains('I couldn\'t'),
            contains('I lost track'),
            contains('There\'s an issue'),
          ]));
        }
      });
      
      test('should provide specific messages for common error types', () {
        expect(
          ChatErrorHandler.createFallbackMessage(ChatErrorType.assetNotFound),
          contains('conversation content'),
        );
        
        expect(
          ChatErrorHandler.createFallbackMessage(ChatErrorType.templateError),
          contains('personalizing'),
        );
        
        expect(
          ChatErrorHandler.createFallbackMessage(ChatErrorType.conditionError),
          contains('conversation path'),
        );
        
        expect(
          ChatErrorHandler.createFallbackMessage(ChatErrorType.flowError),
          contains('conversation flow'),
        );
      });
    });
    
    group('Exception Types', () {
      test('ChatSequenceException should include sequence ID', () {
        final exception = ChatSequenceException(
          'Test error',
          type: ChatErrorType.loadError,
          sequenceId: 'test_sequence',
        );
        
        expect(exception.toString(), contains('test_sequence'));
        expect(exception.sequenceId, 'test_sequence');
        expect(exception.userMessage, isNotEmpty);
      });
      
      test('ChatMessageException should include message ID', () {
        final exception = ChatMessageException(
          'Test error',
          type: ChatErrorType.processingError,
          messageId: 123,
        );
        
        expect(exception.toString(), contains('123'));
        expect(exception.messageId, 123);
        expect(exception.userMessage, isNotEmpty);
      });
      
      test('ChatTemplateException should include template', () {
        final exception = ChatTemplateException(
          'Test error',
          type: ChatErrorType.templateError,
          template: '{user.name}',
        );
        
        expect(exception.toString(), contains('{user.name}'));
        expect(exception.template, '{user.name}');
        expect(exception.userMessage, isNotEmpty);
      });
      
      test('ChatConditionException should include condition', () {
        final exception = ChatConditionException(
          'Test error',
          type: ChatErrorType.conditionError,
          condition: 'user.age > 18',
        );
        
        expect(exception.toString(), contains('user.age > 18'));
        expect(exception.condition, 'user.age > 18');
        expect(exception.userMessage, isNotEmpty);
      });
      
      test('ChatFlowException should include description', () {
        final exception = ChatFlowException(
          'Test error',
          type: ChatErrorType.flowError,
          description: 'Invalid route taken',
        );
        
        expect(exception.toString(), contains('Invalid route taken'));
        expect(exception.description, 'Invalid route taken');
        expect(exception.userMessage, isNotEmpty);
      });
      
      test('ChatAssetException should include asset', () {
        final exception = ChatAssetException(
          'Test error',
          type: ChatErrorType.assetValidation,
          asset: 'sequence.json',
        );
        
        expect(exception.toString(), contains('sequence.json'));
        expect(exception.asset, 'sequence.json');
        expect(exception.userMessage, isNotEmpty);
      });
    });
  });
}