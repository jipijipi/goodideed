import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('Enhanced ChatService', () {
    late ChatService chatService;
    late UserDataService userDataService;
    late TextTemplatingService templatingService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      templatingService = TextTemplatingService(userDataService);
      chatService = ChatService(
        userDataService: userDataService,
        templatingService: templatingService,
      );
    });

    test('should process text templates in messages', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      final message = ChatMessage(
        id: 1,
        text: 'Hello, {user.name}! Welcome back.',
        delay: 1000,
        sender: 'bot',
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(message);

      // Assert
      expect(processedMessage.text, equals('Hello, John Doe! Welcome back.'));
      expect(processedMessage.id, equals(message.id));
      expect(processedMessage.sender, equals(message.sender));
    });

    test('should store user input when storeKey is provided', () async {
      // Arrange
      const userInput = 'Alice Smith';
      const storeKey = StorageKeys.userName;
      final textInputMessage = ChatMessage(
        id: 23,
        text: '', // Text input messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.textInput,
        storeKey: storeKey,
        nextMessageId: 24,
      );

      // Act
      await chatService.handleUserTextInput(textInputMessage, userInput);

      // Assert
      final storedValue = await userDataService.getValue<String>(storeKey);
      expect(storedValue, equals(userInput));
    });

    test('should not store user input when storeKey is null', () async {
      // Arrange
      const userInput = 'Some input';
      final textInputMessage = ChatMessage(
        id: 23,
        text: '', // Text input messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.textInput,
        nextMessageId: 24,
        // storeKey is null
      );

      // Act
      await chatService.handleUserTextInput(textInputMessage, userInput);

      // Assert - no data should be stored
      final allData = await userDataService.getAllData();
      expect(allData.isEmpty, isTrue);
    });

    test('should store user choice when storeKey is provided', () async {
      // Arrange
      const choiceText = 'App features';
      const storeKey = 'user.interest';
      final choice = Choice(
        text: choiceText,
        nextMessageId: 4,
      );
      final choiceMessage = ChatMessage(
        id: 3,
        text: '', // Choice messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.choice,
        storeKey: storeKey,
      );

      // Act
      await chatService.handleUserChoice(choiceMessage, choice);

      // Assert
      final storedValue = await userDataService.getValue<String>(storeKey);
      expect(storedValue, equals(choiceText));
    });

    test('should process templates in message list', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      await userDataService.storeValue('user.age', 25);
      
      final messages = [
        ChatMessage(
          id: 1,
          text: 'Hello, {user.name}!',
          delay: 1000,
          sender: 'bot',
        ),
        ChatMessage(
          id: 2,
          text: 'You are {user.age} years old.',
          delay: 1500,
          sender: 'bot',
        ),
        ChatMessage(
          id: 3,
          text: 'Welcome to our app!',
          delay: 2000,
          sender: 'bot',
        ),
      ];

      // Act
      final processedMessages = await chatService.processMessageTemplates(messages);

      // Assert
      expect(processedMessages.length, equals(3));
      expect(processedMessages[0].text, equals('Hello, John Doe!'));
      expect(processedMessages[1].text, equals('You are 25 years old.'));
      expect(processedMessages[2].text, equals('Welcome to our app!'));
    });

    test('should handle empty message list', () async {
      // Arrange
      final messages = <ChatMessage>[];

      // Act
      final processedMessages = await chatService.processMessageTemplates(messages);

      // Assert
      expect(processedMessages, isEmpty);
    });

    test('should preserve message properties when processing templates', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John');
      final originalMessage = ChatMessage(
        id: 1,
        text: '', // Choice messages have no text content
        delay: 1500,
        sender: 'bot',
        type: MessageType.choice,
        storeKey: 'some.key',
        nextMessageId: 2,
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(originalMessage);

      // Assert
      expect(processedMessage.text, equals('')); // Choice messages have no text content
      expect(processedMessage.id, equals(originalMessage.id));
      expect(processedMessage.delay, equals(originalMessage.delay));
      expect(processedMessage.sender, equals(originalMessage.sender));
      expect(processedMessage.isChoice, equals(originalMessage.isChoice));
      expect(processedMessage.isTextInput, equals(originalMessage.isTextInput));
      expect(processedMessage.storeKey, equals(originalMessage.storeKey));
      expect(processedMessage.nextMessageId, equals(originalMessage.nextMessageId));
    });

    test('should process templates with fallback values', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'Alice');
      // user.status is not stored, should use fallback
      final message = ChatMessage(
        id: 1,
        text: 'Hello, {user.name|Guest}! Your status is {user.status|Active}.',
        delay: 1000,
        sender: 'bot',
      );

      // Act
      final processedMessage = await chatService.processMessageTemplate(message);

      // Assert
      expect(processedMessage.text, equals('Hello, Alice! Your status is Active.'));
    });

    test('should process message list with fallback values', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'Bob');
      
      final messages = [
        ChatMessage(
          id: 1,
          text: 'Welcome back, {user.name|Guest}!',
          delay: 1000,
          sender: 'bot',
        ),
        ChatMessage(
          id: 2,
          text: 'Your theme is {user.theme|default}.',
          delay: 1500,
          sender: 'bot',
        ),
      ];

      // Act
      final processedMessages = await chatService.processMessageTemplates(messages);

      // Assert
      expect(processedMessages.length, equals(2));
      expect(processedMessages[0].text, equals('Welcome back, Bob!'));
      expect(processedMessages[1].text, equals('Your theme is default.'));
    });
  });
}