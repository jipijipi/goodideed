import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service/message_processor.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';

void main() {
  group('MessageProcessor Simple Integration', () {
    late MessageProcessor processor;
    
    setUp(() {
      processor = MessageProcessor();
    });
    
    test('should preserve contentKey field in processed message', () async {
      final message = ChatMessage(
        id: 1,
        text: 'Test message',
        type: MessageType.bot,
        contentKey: 'bot.test.message',
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Should preserve contentKey
      expect(processed.contentKey, equals('bot.test.message'));
      expect(processed.id, equals(1));
      expect(processed.type, equals(MessageType.bot));
    });
    
    test('should handle null contentKey', () async {
      final message = ChatMessage(
        id: 1,
        text: 'Test message',
        type: MessageType.bot,
        contentKey: null,
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',  
        description: 'Test sequence',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      expect(processed.contentKey, isNull);
      expect(processed.text, equals('Test message'));
    });
    
    test('should preserve all message fields', () async {
      final message = ChatMessage(
        id: 42,
        text: 'Original text',
        type: MessageType.bot,
        delay: 2000,
        nextMessageId: 43,
        sequenceId: 'next_seq',
        storeKey: 'test.key',
        contentKey: 'bot.test.content',
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      expect(processed.id, equals(42));
      expect(processed.type, equals(MessageType.bot));
      expect(processed.delay, equals(2000));
      expect(processed.nextMessageId, equals(43));
      expect(processed.sequenceId, equals('next_seq'));
      expect(processed.storeKey, equals('test.key'));
      expect(processed.contentKey, equals('bot.test.content'));
    });
  });
}