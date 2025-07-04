import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';

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

    test('should create choice message from JSON', () {
      // Arrange
      final json = {
        'id': 2,
        'text': 'CHOICES',
        'delay': 1500,
        'sender': 'user',
        'isChoice': true,
        'choices': [
          {'text': 'Red', 'nextMessageId': 10},
          {'text': 'Blue', 'nextMessageId': 20},
        ],
        'nextMessageId': 30,
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, 2);
      expect(message.text, 'CHOICES');
      expect(message.isChoice, true);
      expect(message.choices, isNotNull);
      expect(message.choices!.length, 2);
      expect(message.choices![0].text, 'Red');
      expect(message.choices![0].nextMessageId, 10);
      expect(message.choices![1].text, 'Blue');
      expect(message.choices![1].nextMessageId, 20);
      expect(message.nextMessageId, 30);
    });

    test('should create regular message without choices', () {
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
      expect(message.isChoice, false);
      expect(message.choices, isNull);
      expect(message.nextMessageId, isNull);
    });

    test('should convert choice message to JSON', () {
      // Arrange
      final choices = [
        Choice(text: 'Option A', nextMessageId: 10),
        Choice(text: 'Option B', nextMessageId: 20),
      ];
      final message = ChatMessage(
        id: 2,
        text: 'CHOICES',
        delay: 1500,
        sender: 'user',
        isChoice: true,
        choices: choices,
        nextMessageId: 30,
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 2);
      expect(json['isChoice'], true);
      expect(json['choices'], isNotNull);
      expect(json['choices'].length, 2);
      expect(json['choices'][0]['text'], 'Option A');
      expect(json['choices'][0]['nextMessageId'], 10);
      expect(json['nextMessageId'], 30);
    });

    test('should identify choice messages correctly', () {
      // Arrange
      final choiceMessage = ChatMessage(
        id: 2,
        text: 'CHOICES',
        delay: 1500,
        sender: 'user',
        isChoice: true,
        choices: [Choice(text: 'Yes', nextMessageId: 10)],
      );

      final regularMessage = ChatMessage(
        id: 1,
        text: 'Hello',
        delay: 1000,
        sender: 'bot',
      );

      // Act & Assert
      expect(choiceMessage.isChoice, true);
      expect(regularMessage.isChoice, false);
    });

    test('should create text input message from JSON', () {
      // Arrange
      final json = {
        'id': 5,
        'text': 'What is your name?',
        'delay': 1000,
        'sender': 'bot',
        'isTextInput': true,
        'nextMessageId': 6,
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, 5);
      expect(message.text, 'What is your name?');
      expect(message.isTextInput, true);
      expect(message.nextMessageId, 6);
    });

    test('should create regular message without text input flag', () {
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
      expect(message.isTextInput, false);
    });

    test('should convert text input message to JSON', () {
      // Arrange
      final message = ChatMessage(
        id: 5,
        text: 'What is your name?',
        delay: 1000,
        sender: 'bot',
        isTextInput: true,
        nextMessageId: 6,
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 5);
      expect(json['text'], 'What is your name?');
      expect(json['isTextInput'], true);
      expect(json['nextMessageId'], 6);
    });

    test('should identify text input messages correctly', () {
      // Arrange
      final textInputMessage = ChatMessage(
        id: 5,
        text: 'What is your name?',
        delay: 1000,
        sender: 'bot',
        isTextInput: true,
      );

      final regularMessage = ChatMessage(
        id: 1,
        text: 'Hello',
        delay: 1000,
        sender: 'bot',
      );

      // Act & Assert
      expect(textInputMessage.isTextInput, true);
      expect(regularMessage.isTextInput, false);
    });

    test('should create ChatMessage with storeKey from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'What is your name?',
        'delay': 1000,
        'sender': 'bot',
        'isTextInput': true,
        'storeKey': 'user.name',
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, equals(1));
      expect(message.text, equals('What is your name?'));
      expect(message.storeKey, equals('user.name'));
      expect(message.isTextInput, isTrue);
    });

    test('should create ChatMessage without storeKey from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello!',
        'delay': 1000,
        'sender': 'bot',
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.id, equals(1));
      expect(message.text, equals('Hello!'));
      expect(message.storeKey, isNull);
    });

    test('should convert ChatMessage with storeKey to JSON', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: 'What is your name?',
        delay: 1000,
        sender: 'bot',
        isTextInput: true,
        storeKey: 'user.name',
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['text'], equals('What is your name?'));
      expect(json['storeKey'], equals('user.name'));
      expect(json['isTextInput'], isTrue);
    });

    test('should not include storeKey in JSON if null', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: 'Hello!',
        delay: 1000,
        sender: 'bot',
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['text'], equals('Hello!'));
      expect(json.containsKey('storeKey'), isFalse);
    });
  });
}