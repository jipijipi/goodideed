import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('should create ChatMessage from JSON with sender', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello World',
        'delay': 1000,
        'sender': 'bot',
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, 1);
      expect(message.text, 'Hello World');
      expect(message.delay, 1000);
      expect(message.sender, 'bot');
    });

    test('should create ChatMessage from JSON without sender (defaults to bot)', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello World',
        'delay': 1000,
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, 1);
      expect(message.text, 'Hello World');
      expect(message.delay, 1000);
      expect(message.sender, 'bot');
    });

    test('should convert ChatMessage to JSON with sender', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: 'Hello World',
        delay: 1000,
        sender: 'user',
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['text'], 'Hello World');
      expect(json['delay'], 1000);
      expect(json['sender'], 'user');
    });

    test('should identify bot messages correctly', () {
      // Arrange
      final botMessage = ChatMessage(
        id: 1,
        text: 'Hello from bot',
        delay: 1000,
        sender: 'bot',
      );

      // Act & Assert
      expect(botMessage.isFromBot, true);
      expect(botMessage.isFromUser, false);
    });

    test('should identify user messages correctly', () {
      // Arrange
      final userMessage = ChatMessage(
        id: 1,
        text: 'Hello from user',
        delay: 1000,
        sender: 'user',
      );

      // Act & Assert
      expect(userMessage.isFromBot, false);
      expect(userMessage.isFromUser, true);
    });
  });
}