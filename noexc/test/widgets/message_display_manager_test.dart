import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/widgets/chat_screen/state_management/message_display_manager.dart';
import 'package:noexc/services/message_queue.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MessageDisplayManager', () {
    late MessageDisplayManager displayManager;
    late MessageQueue messageQueue;
    int notificationCount = 0;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      displayManager = MessageDisplayManager();
      messageQueue = MessageQueue();
      notificationCount = 0;
    });

    tearDown(() {
      displayManager.dispose();
      messageQueue.dispose();
    });

    test('should allow repeated messages in conversation loops', () async {
      // Arrange - Create messages with same ID and text (like a loop scenario)
      final messages = [
        ChatMessage(id: 1, text: 'Do you want to try again?', delay: 0),
        ChatMessage(id: 2, text: 'Great choice!', delay: 0),
        ChatMessage(id: 1, text: 'Do you want to try again?', delay: 0), // Same as first
      ];

      // Act
      await displayManager.displayMessages(messages, messageQueue, () {
        notificationCount++;
      });

      // Assert - All messages should be displayed, including the repeated one
      expect(displayManager.displayedMessages.length, equals(3));
      expect(displayManager.displayedMessages[0].text, equals('Do you want to try again?'));
      expect(displayManager.displayedMessages[1].text, equals('Great choice!'));
      expect(displayManager.displayedMessages[2].text, equals('Do you want to try again?'));
      expect(notificationCount, equals(3));
    });

    test('should filter out empty messages that are not interactive', () async {
      // Arrange - Mix of empty and valid messages
      final messages = [
        ChatMessage(id: 1, text: '', delay: 0), // Empty, should be filtered
        ChatMessage(id: 2, text: 'Valid message', delay: 0),
        ChatMessage(id: 3, text: '   ', delay: 0), // Whitespace only, should be filtered
        ChatMessage(id: 4, text: 'Another valid message', delay: 0),
      ];

      // Act
      await displayManager.displayMessages(messages, messageQueue, () {
        notificationCount++;
      });

      // Assert - Only non-empty messages should be displayed
      expect(displayManager.displayedMessages.length, equals(2));
      expect(displayManager.displayedMessages[0].text, equals('Valid message'));
      expect(displayManager.displayedMessages[1].text, equals('Another valid message'));
    });

    test('should allow empty interactive messages (choices and text inputs)', () async {
      // Arrange - Empty messages that are interactive
      final messages = [
        ChatMessage(id: 1, text: '', delay: 0, type: MessageType.choice, choices: []),
        ChatMessage(id: 2, text: '', delay: 0, type: MessageType.textInput), // TextInput must have empty text
        ChatMessage(id: 3, text: 'Regular message', delay: 0),
      ];

      // Act
      await displayManager.displayMessages(messages, messageQueue, () {
        notificationCount++;
      });

      // Assert - Interactive messages should be displayed even if empty
      expect(displayManager.displayedMessages.length, equals(3));
      expect(displayManager.displayedMessages[0].isChoice, isTrue);
      expect(displayManager.displayedMessages[1].isTextInput, isTrue);
      expect(displayManager.displayedMessages[2].text, equals('Regular message'));
    });

    test('should handle multiple identical messages in sequence', () async {
      // Arrange - Multiple identical messages (like asking same question multiple times)
      final messages = [
        ChatMessage(id: 1, text: 'Are you ready?', delay: 0),
        ChatMessage(id: 1, text: 'Are you ready?', delay: 0),
        ChatMessage(id: 1, text: 'Are you ready?', delay: 0),
      ];

      // Act
      await displayManager.displayMessages(messages, messageQueue, () {
        notificationCount++;
      });

      // Assert - All identical messages should be displayed
      expect(displayManager.displayedMessages.length, equals(3));
      expect(displayManager.displayedMessages.every((msg) => msg.text == 'Are you ready?'), isTrue);
      expect(notificationCount, equals(3));
    });
  });
}