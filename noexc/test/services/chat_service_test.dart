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
      expect(messages.length, 8);
      expect(messages[0].id, 1);
      expect(messages[1].id, 2);
      expect(messages[2].id, 3);
      expect(messages[3].id, 4);
      expect(messages[4].id, 5);
      expect(messages[5].id, 6);
      expect(messages[6].id, 7);
      expect(messages[7].id, 8);
    });

    test('should load messages with correct senders', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages[0].sender, 'bot');
      expect(messages[1].sender, 'user');
      expect(messages[2].sender, 'bot');
      expect(messages[3].sender, 'user');
      expect(messages[4].sender, 'bot');
      expect(messages[5].sender, 'user');
      expect(messages[6].sender, 'bot');
      expect(messages[7].sender, 'user');
    });

    test('should alternate between bot and user messages', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      for (int i = 0; i < messages.length; i++) {
        if (i % 2 == 0) {
          expect(messages[i].isFromBot, true, reason: 'Message at index $i should be from bot');
        } else {
          expect(messages[i].isFromUser, true, reason: 'Message at index $i should be from user');
        }
      }
    });
  });
}