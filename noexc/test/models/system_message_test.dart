import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('System Message', () {
    test('should parse system message type from JSON', () {
      final json = {
        'id': 1,
        'type': 'system',
        'text': '[ System: Connection established ]',
        'nextMessageId': 2,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.type, MessageType.system);
      expect(message.text, '[ System: Connection established ]');
      expect(message.id, 1);
      expect(message.nextMessageId, 2);
    });

    test('should preserve text content for system messages', () {
      final json = {
        'id': 1,
        'type': 'system',
        'text': 'This text should be preserved',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.type, MessageType.system);
      expect(message.text, 'This text should be preserved');
      expect(message.text.isNotEmpty, true);
    });

    test('should default to bot type when system is misspelled', () {
      final json = {
        'id': 1,
        'type': 'systm', // Misspelled
        'text': 'This should default to bot',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.type, MessageType.bot);
      expect(message.text, 'This should default to bot');
    });
  });
}