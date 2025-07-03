import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('ChatService', () {
    late ChatService chatService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      chatService = ChatService();
    });

    test('should load chat messages from JSON', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages, isA<List<ChatMessage>>());
      expect(messages.isNotEmpty, true);
      expect(messages.first.text, 'Hello! Welcome to the app!');
    });

    test('should return messages in correct order', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages.length, 4);
      expect(messages[0].id, 1);
      expect(messages[1].id, 2);
      expect(messages[2].id, 3);
      expect(messages[3].id, 4);
    });
  });
}