import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/semantic_content_service.dart';
import 'package:noexc/services/chat_service/message_processor.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('Semantic Content System End-to-End', () {
    late MessageProcessor processor;
    late SemanticContentService contentService;
    
    setUp(() {
      processor = MessageProcessor();
      contentService = SemanticContentService.instance;
    });
    
    test('should process message with semantic contentKey through MessageProcessor', () async {
      // Create a message with semantic contentKey
      final message = ChatMessage(
        id: 1,
        text: 'Original welcome message',
        type: MessageType.bot,
        contentKey: 'bot.introduce.character.casual',
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for semantic content',
        messages: [message],
      );
      
      // Process the message through MessageProcessor
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Verify the contentKey is preserved
      expect(processed.contentKey, equals('bot.introduce.character.casual'));
      expect(processed.id, equals(1));
      expect(processed.type, equals(MessageType.bot));
      
      // The text should either be the original or a variant from the content file
      expect(processed.text.isNotEmpty, isTrue);
    });
    
    test('should work with multi-text messages containing |||', () async {
      final message = ChatMessage(
        id: 2,
        text: 'Part 1|||Part 2|||Part 3',
        type: MessageType.bot,
        contentKey: 'bot.inform.multi_welcome.casual',
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for semantic content',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Should preserve contentKey and handle multi-text
      expect(processed.contentKey, equals('bot.inform.multi_welcome.casual'));
      expect(processed.text.contains('|||'), isTrue);
    });
    
    test('should handle choice messages with contentKey', () async {
      final message = ChatMessage(
        id: 3,
        text: '',
        type: MessageType.choice,
        contentKey: 'user.choose.greeting.friendly',
        choices: [
          Choice.fromJson({
            'text': 'Hi there!',
            'contentKey': 'user.greet.character.friendly',
            'nextMessageId': 4,
          }),
          Choice.fromJson({
            'text': 'Hello...',
            'contentKey': 'user.greet.character.skeptical',
            'nextMessageId': 5,
          }),
        ],
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for semantic content',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Should preserve contentKey for both message and choices
      expect(processed.contentKey, equals('user.choose.greeting.friendly'));
      expect(processed.choices?.length, equals(2));
      expect(processed.choices![0].contentKey, equals('user.greet.character.friendly'));
      expect(processed.choices![1].contentKey, equals('user.greet.character.skeptical'));
    });
    
    test('should fall back to original text when no content file exists', () async {
      final message = ChatMessage(
        id: 4,
        text: 'Fallback message',
        type: MessageType.bot,
        contentKey: 'bot.nonexistent.key.missing',
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for semantic content',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Should preserve contentKey and fall back to original text
      expect(processed.contentKey, equals('bot.nonexistent.key.missing'));
      expect(processed.text, equals('Fallback message'));
    });
    
    test('should work seamlessly with legacy messages without contentKey', () async {
      final message = ChatMessage(
        id: 5,
        text: 'Legacy message without contentKey',
        type: MessageType.bot,
        contentKey: null,
      );
      
      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for semantic content',
        messages: [message],
      );
      
      final processed = await processor.processMessageTemplate(message, sequence);
      
      // Should preserve null contentKey and original text
      expect(processed.contentKey, isNull);
      expect(processed.text, equals('Legacy message without contentKey'));
    });
  });
}