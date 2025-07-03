import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('should create ChatMessage from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello World',
        'timestamp': '10:00',
        'delay': 1000,
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, 1);
      expect(message.text, 'Hello World');
      expect(message.timestamp, '10:00');
      expect(message.delay, 1000);
    });

    test('should convert ChatMessage to JSON', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: 'Hello World',
        timestamp: '10:00',
        delay: 1000,
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['text'], 'Hello World');
      expect(json['timestamp'], '10:00');
      expect(json['delay'], 1000);
    });
  });
}