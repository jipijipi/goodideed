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
      expect(messages.first.text, 'Welcome to our app! I\'m here to help you get started.');
    });

    test('should return messages in correct order', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages.length, 15); // Updated for onboarding sequence
      expect(messages[0].id, 1);
      expect(messages[1].id, 2);
      expect(messages[2].id, 3);
    });

    test('should load messages with correct senders', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      expect(messages[0].sender, 'bot');   // "Welcome to our app! I'm here to help you get started."
      expect(messages[1].sender, 'bot');   // "Let's begin by getting to know you better. What's your name?"
      expect(messages[2].sender, 'bot');   // "Nice to meet you, {user.name|there}! What brings you to our app today?"
    });

    test('should not duplicate messages when switching sequences', () async {
      // Arrange
      final userDataService = UserDataService();
      final templatingService = TextTemplatingService(userDataService);
      final chatService = ChatService(
        userDataService: userDataService,
        templatingService: templatingService,
      );
      
      // Track sequence switches to simulate the duplication scenario
      List<String> switchedSequences = [];
      chatService.setSequenceSwitchCallback((sequenceId, startMessageId) async {
        switchedSequences.add(sequenceId);
      });
      
      // Act - Load welcome sequence which routes to onboarding
      final messages = await chatService.getInitialMessages(sequenceId: 'welcome_seq');
      
      // Assert - Should not contain duplicate messages
      final messageTexts = messages.map((m) => m.text).toList();
      final uniqueTexts = messageTexts.toSet().toList();
      
      expect(messageTexts.length, equals(uniqueTexts.length), 
        reason: 'Found duplicate messages: $messageTexts');
      
      // Should not have "Hi" appearing twice
      final hiCount = messageTexts.where((text) => text == 'Hi').length;
      expect(hiCount, lessThanOrEqualTo(1), 
        reason: 'Message "Hi" appears $hiCount times, should appear at most once');
    });

    test('should load choice messages correctly', () async {
      // Act
      final messages = await chatService.loadChatScript();

      // Assert
      final choiceMessage = messages.firstWhere((msg) => msg.isChoice);
      expect(choiceMessage.isChoice, true);
      expect(choiceMessage.choices, isNotNull);
      expect(choiceMessage.choices!.length, 3);
      expect(choiceMessage.choices![0].text, 'Exploring features');
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
      expect(message.text, 'Welcome to our app! I\'m here to help you get started.');
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
      final messages = await chatService.getMessagesAfterChoice(3);

      // Assert
      expect(messages, isNotNull);
      expect(messages, isA<List<ChatMessage>>());
    });

    test('should handle text input messages in conversation flow', () async {
      // Arrange
      await chatService.loadChatScript();

      // Act
      final messages = await chatService.getMessagesAfterTextInput(100, 'John Doe');

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
        text: '', // Text input messages have no text content
        type: MessageType.textInput,
        placeholderText: 'Enter your custom name here...',
        storeKey: 'user.name',
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(originalMessage);

      // Assert
      expect(processedMessage.placeholderText, 'Enter your custom name here...');
      expect(processedMessage.isTextInput, true);
      expect(processedMessage.storeKey, 'user.name');
      expect(processedMessage.text, ''); // Text input messages have no text content
    });

    test('should preserve default placeholderText when processing templates', () async {
      // Arrange
      final chatService = ChatService(); // No templating service

      final originalMessage = ChatMessage(
        id: 1,
        text: '', // Text input messages have no text content
        type: MessageType.textInput,
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