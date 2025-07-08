import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('ChatSequence', () {
    test('should create ChatSequence from JSON', () {
      final json = {
        'sequenceId': 'test',
        'name': 'Test Sequence',
        'description': 'A test sequence',
        'messages': [
          {
            'id': 1,
            'text': 'Hello',
            'sender': 'bot'
          }
        ]
      };

      final sequence = ChatSequence.fromJson(json);

      expect(sequence.sequenceId, 'test');
      expect(sequence.name, 'Test Sequence');
      expect(sequence.description, 'A test sequence');
      expect(sequence.messages.length, 1);
      expect(sequence.messages.first.text, 'Hello');
    });

    test('should convert ChatSequence to JSON', () {
      final message = ChatMessage(id: 1, text: 'Hello', sender: 'bot');
      final sequence = ChatSequence(
        sequenceId: 'test',
        name: 'Test Sequence',
        description: 'A test sequence',
        messages: [message],
      );

      final json = sequence.toJson();

      expect(json['sequenceId'], 'test');
      expect(json['name'], 'Test Sequence');
      expect(json['description'], 'A test sequence');
      expect(json['messages'], isA<List>());
      expect(json['messages'].length, 1);
    });

    test('should get message by ID', () {
      final message1 = ChatMessage(id: 1, text: 'Hello', sender: 'bot');
      final message2 = ChatMessage(id: 2, text: 'World', sender: 'bot');
      final sequence = ChatSequence(
        sequenceId: 'test',
        name: 'Test Sequence',
        description: 'A test sequence',
        messages: [message1, message2],
      );

      final foundMessage = sequence.getMessageById(2);
      expect(foundMessage?.text, 'World');

      final notFound = sequence.getMessageById(99);
      expect(notFound, isNull);
    });

    test('should check if message exists', () {
      final message = ChatMessage(id: 1, text: 'Hello', sender: 'bot');
      final sequence = ChatSequence(
        sequenceId: 'test',
        name: 'Test Sequence',
        description: 'A test sequence',
        messages: [message],
      );

      expect(sequence.hasMessage(1), isTrue);
      expect(sequence.hasMessage(99), isFalse);
    });

    test('should return message IDs', () {
      final message1 = ChatMessage(id: 1, text: 'Hello', sender: 'bot');
      final message2 = ChatMessage(id: 5, text: 'World', sender: 'bot');
      final sequence = ChatSequence(
        sequenceId: 'test',
        name: 'Test Sequence',
        description: 'A test sequence',
        messages: [message1, message2],
      );

      final ids = sequence.messageIds;
      expect(ids, [1, 5]);
    });
  });
}