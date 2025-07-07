import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';

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
      expect(messages.length, 23); // Updated for new JSON structure with text input messages
      expect(messages[0].id, 1);
      expect(messages[1].id, 2);
      expect(messages[2].id, 3);
    });

    test('should load messages with correct senders', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages[0].sender, 'bot');   // "Hello! Welcome to the app!"
      expect(messages[1].sender, 'bot');   // "What would you like to learn about?"
      expect(messages[2].sender, 'user');  // Choice message
    });

    test('should load choice messages correctly', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      final choiceMessage = messages.firstWhere((msg) => msg.isChoice);
      expect(choiceMessage.isChoice, true);
      expect(choiceMessage.choices, isNotNull);
      expect(choiceMessage.choices!.length, 3);
      expect(choiceMessage.choices![0].text, 'App features');
      expect(choiceMessage.choices![0].nextMessageId, 10);
    });

    test('should build message map for quick lookup', () async {
      // Act
      await chatService.loadChatScript();

      // Assert
      expect(chatService.hasMessage(1), true);
      expect(chatService.hasMessage(2), true);
      expect(chatService.hasMessage(999), false);
    });

    test('should get message by id', () async {
      // Act
      await chatService.loadChatScript();

      // Assert
      final message = chatService.getMessageById(1);
      expect(message, isNotNull);
      expect(message!.id, 1);
      expect(message.text, 'Hello! Welcome to the app!');
    });

    test('should return null for non-existent message id', () async {
      // Act
      await chatService.loadChatScript();

      // Assert
      final message = chatService.getMessageById(999);
      expect(message, isNull);
    });

    test('should get initial messages until first choice', () async {
      // Arrange - This will use the current JSON which doesn't have choices yet
      // Act
      final initialMessages = await chatService.getInitialMessages();

      // Assert
      expect(initialMessages, isNotNull);
      expect(initialMessages.isNotEmpty, true);
    });

    test('should get messages after choice selection', () async {
      // Arrange
      await chatService.loadChatScript();

      // Act
      final messages = chatService.getMessagesAfterChoice(3);

      // Assert
      expect(messages, isNotNull);
      expect(messages, isA<List<ChatMessage>>());
    });

    test('should handle text input messages in conversation flow', () async {
      // Arrange
      await chatService.loadChatScript();

      // Act
      final messages = chatService.getMessagesAfterTextInput(100, 'John Doe');

      // Assert
      expect(messages, isNotNull);
      expect(messages, isA<List<ChatMessage>>());
    });

    test('should create user response message from text input', () {
      // Arrange
      const userInput = 'My name is Alice';
      const messageId = 999;

      // Act
      final userMessage = chatService.createUserResponseMessage(messageId, userInput);

      // Assert
      expect(userMessage.id, messageId);
      expect(userMessage.text, userInput);
      expect(userMessage.sender, 'user');
      expect(userMessage.isFromUser, true);
      expect(userMessage.delay, 0);
    });
  });

  group('processMessageTemplate', () {
    test('should preserve placeholderText when processing templates without templating service', () async {
      // Arrange
      final chatService = ChatService(); // No templating service

      final originalMessage = ChatMessage(
        id: 1,
        text: 'Hello there!',
        isTextInput: true,
        placeholderText: 'Enter your custom name here...',
        storeKey: 'user.name',
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(originalMessage);

      // Assert
      expect(processedMessage.placeholderText, 'Enter your custom name here...');
      expect(processedMessage.isTextInput, true);
      expect(processedMessage.storeKey, 'user.name');
      expect(processedMessage.text, 'Hello there!'); // Text unchanged without templating
    });

    test('should preserve default placeholderText when processing templates', () async {
      // Arrange
      final chatService = ChatService(); // No templating service

      final originalMessage = ChatMessage(
        id: 1,
        text: 'What is your name?',
        isTextInput: true,
        // Using default placeholderText
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(originalMessage);

      // Assert
      expect(processedMessage.placeholderText, 'Type your answer...');
      expect(processedMessage.isTextInput, true);
    });
  });
}