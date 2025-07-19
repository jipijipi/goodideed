import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/error_handling/chat_exceptions.dart';
import 'package:noexc/services/error_handling/chat_error_types.dart';

void main() {
  group('ChatSequenceException', () {
    test('should create exception with message, type, and sequenceId', () {
      const message = 'Sequence loading failed';
      const type = ChatErrorType.loadError;
      const sequenceId = 'test_sequence';
      
      final exception = ChatSequenceException(
        message,
        type: type,
        sequenceId: sequenceId,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.sequenceId, equals(sequenceId));
    });

    test('should create exception without sequenceId', () {
      const message = 'Sequence error';
      const type = ChatErrorType.assetNotFound;
      
      final exception = ChatSequenceException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.sequenceId, isNull);
    });

    test('should generate correct toString with sequenceId', () {
      const message = 'Test error';
      const sequenceId = 'onboarding_seq';
      
      final exception = ChatSequenceException(
        message,
        type: ChatErrorType.loadError,
        sequenceId: sequenceId,
      );
      
      expect(exception.toString(), equals('ChatSequenceException: $message (Sequence: $sequenceId)'));
    });

    test('should generate correct toString without sequenceId', () {
      const message = 'Test error';
      
      final exception = ChatSequenceException(
        message,
        type: ChatErrorType.loadError,
      );
      
      expect(exception.toString(), equals('ChatSequenceException: $message (Sequence: null)'));
    });

    test('should inherit userMessage from ChatException', () {
      final exception = ChatSequenceException(
        'Technical error',
        type: ChatErrorType.assetNotFound,
        sequenceId: 'test_seq',
      );
      
      expect(exception.userMessage, equals('Sorry, I couldn\'t find the conversation content. Please try again.'));
    });
  });

  group('ChatMessageException', () {
    test('should create exception with message, type, and messageId', () {
      const message = 'Message processing failed';
      const type = ChatErrorType.processingError;
      const messageId = 42;
      
      final exception = ChatMessageException(
        message,
        type: type,
        messageId: messageId,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.messageId, equals(messageId));
    });

    test('should create exception without messageId', () {
      const message = 'Message error';
      const type = ChatErrorType.flowError;
      
      final exception = ChatMessageException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.messageId, isNull);
    });

    test('should generate correct toString with messageId', () {
      const message = 'Test error';
      const messageId = 123;
      
      final exception = ChatMessageException(
        message,
        type: ChatErrorType.processingError,
        messageId: messageId,
      );
      
      expect(exception.toString(), equals('ChatMessageException: $message (Message ID: $messageId)'));
    });

    test('should generate correct toString without messageId', () {
      const message = 'Test error';
      
      final exception = ChatMessageException(
        message,
        type: ChatErrorType.processingError,
      );
      
      expect(exception.toString(), equals('ChatMessageException: $message (Message ID: null)'));
    });
  });

  group('ChatTemplateException', () {
    test('should create exception with message, type, and template', () {
      const message = 'Template processing failed';
      const type = ChatErrorType.templateError;
      const template = '{user.name|Guest}';
      
      final exception = ChatTemplateException(
        message,
        type: type,
        template: template,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.template, equals(template));
    });

    test('should create exception without template', () {
      const message = 'Template error';
      const type = ChatErrorType.templateError;
      
      final exception = ChatTemplateException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.template, isNull);
    });

    test('should generate correct toString with template', () {
      const message = 'Test error';
      const template = '{user.score|0}';
      
      final exception = ChatTemplateException(
        message,
        type: ChatErrorType.templateError,
        template: template,
      );
      
      expect(exception.toString(), equals('ChatTemplateException: $message (Template: $template)'));
    });

    test('should handle complex template strings', () {
      const message = 'Complex template error';
      const template = 'Hello {user.name|Guest}, your score is {user.score|0}!';
      
      final exception = ChatTemplateException(
        message,
        type: ChatErrorType.templateError,
        template: template,
      );
      
      expect(exception.template, equals(template));
      expect(exception.toString(), contains(template));
    });
  });

  group('ChatConditionException', () {
    test('should create exception with message, type, and condition', () {
      const message = 'Condition evaluation failed';
      const type = ChatErrorType.conditionError;
      const condition = 'user.level > 5';
      
      final exception = ChatConditionException(
        message,
        type: type,
        condition: condition,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.condition, equals(condition));
    });

    test('should create exception without condition', () {
      const message = 'Condition error';
      const type = ChatErrorType.conditionError;
      
      final exception = ChatConditionException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.condition, isNull);
    });

    test('should generate correct toString with condition', () {
      const message = 'Test error';
      const condition = 'user.hasTask == true';
      
      final exception = ChatConditionException(
        message,
        type: ChatErrorType.conditionError,
        condition: condition,
      );
      
      expect(exception.toString(), equals('ChatConditionException: $message (Condition: $condition)'));
    });

    test('should handle complex condition expressions', () {
      const message = 'Complex condition error';
      const condition = 'user.level >= 5 && user.hasCompleted == false';
      
      final exception = ChatConditionException(
        message,
        type: ChatErrorType.conditionError,
        condition: condition,
      );
      
      expect(exception.condition, equals(condition));
      expect(exception.toString(), contains(condition));
    });
  });

  group('ChatFlowException', () {
    test('should create exception with message, type, and description', () {
      const message = 'Flow navigation failed';
      const type = ChatErrorType.flowError;
      const description = 'Dead end detected in conversation flow';
      
      final exception = ChatFlowException(
        message,
        type: type,
        description: description,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.description, equals(description));
    });

    test('should create exception without description', () {
      const message = 'Flow error';
      const type = ChatErrorType.flowError;
      
      final exception = ChatFlowException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.description, isNull);
    });

    test('should generate correct toString with description', () {
      const message = 'Test error';
      const description = 'Circular reference detected';
      
      final exception = ChatFlowException(
        message,
        type: ChatErrorType.flowError,
        description: description,
      );
      
      expect(exception.toString(), equals('ChatFlowException: $message (Description: $description)'));
    });
  });

  group('ChatAssetException', () {
    test('should create exception with message, type, and asset', () {
      const message = 'Asset validation failed';
      const type = ChatErrorType.assetValidation;
      const asset = 'assets/sequences/test_seq.json';
      
      final exception = ChatAssetException(
        message,
        type: type,
        asset: asset,
      );
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.asset, equals(asset));
    });

    test('should create exception without asset', () {
      const message = 'Asset error';
      const type = ChatErrorType.assetValidation;
      
      final exception = ChatAssetException(message, type: type);
      
      expect(exception.message, equals(message));
      expect(exception.type, equals(type));
      expect(exception.asset, isNull);
    });

    test('should generate correct toString with asset', () {
      const message = 'Test error';
      const asset = 'assets/variants/test_message_1.txt';
      
      final exception = ChatAssetException(
        message,
        type: ChatErrorType.assetValidation,
        asset: asset,
      );
      
      expect(exception.toString(), equals('ChatAssetException: $message (Asset: $asset)'));
    });
  });

  group('exception inheritance', () {
    test('all exceptions should extend ChatException', () {
      final sequenceException = ChatSequenceException('test', type: ChatErrorType.loadError);
      final messageException = ChatMessageException('test', type: ChatErrorType.processingError);
      final templateException = ChatTemplateException('test', type: ChatErrorType.templateError);
      final conditionException = ChatConditionException('test', type: ChatErrorType.conditionError);
      final flowException = ChatFlowException('test', type: ChatErrorType.flowError);
      final assetException = ChatAssetException('test', type: ChatErrorType.assetValidation);
      
      expect(sequenceException, isA<ChatException>());
      expect(messageException, isA<ChatException>());
      expect(templateException, isA<ChatException>());
      expect(conditionException, isA<ChatException>());
      expect(flowException, isA<ChatException>());
      expect(assetException, isA<ChatException>());
    });

    test('all exceptions should implement Exception', () {
      final sequenceException = ChatSequenceException('test', type: ChatErrorType.loadError);
      final messageException = ChatMessageException('test', type: ChatErrorType.processingError);
      final templateException = ChatTemplateException('test', type: ChatErrorType.templateError);
      final conditionException = ChatConditionException('test', type: ChatErrorType.conditionError);
      final flowException = ChatFlowException('test', type: ChatErrorType.flowError);
      final assetException = ChatAssetException('test', type: ChatErrorType.assetValidation);
      
      expect(sequenceException, isA<Exception>());
      expect(messageException, isA<Exception>());
      expect(templateException, isA<Exception>());
      expect(conditionException, isA<Exception>());
      expect(flowException, isA<Exception>());
      expect(assetException, isA<Exception>());
    });

    test('all exceptions should have access to userMessage', () {
      final exceptions = [
        ChatSequenceException('test', type: ChatErrorType.loadError),
        ChatMessageException('test', type: ChatErrorType.processingError),
        ChatTemplateException('test', type: ChatErrorType.templateError),
        ChatConditionException('test', type: ChatErrorType.conditionError),
        ChatFlowException('test', type: ChatErrorType.flowError),
        ChatAssetException('test', type: ChatErrorType.assetValidation),
      ];
      
      for (final exception in exceptions) {
        expect(exception.userMessage, isNotEmpty);
        expect(exception.userMessage, isA<String>());
      }
    });
  });
}