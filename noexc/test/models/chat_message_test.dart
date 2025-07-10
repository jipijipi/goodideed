import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';
import 'package:noexc/constants/app_constants.dart';

void main() {
  group('ChatMessage', () {
    test('should use default delay when delay is not provided in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello World',
        // No delay field provided
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.delay, AppConstants.defaultMessageDelay);
      expect(message.delay, 1000); // Verify the default value
    });

    test('should use provided delay when specified in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Hello World',
        'delay': 2000,
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.delay, 2000);
    });

    test('should use default delay when creating ChatMessage without delay parameter', () {
      // Act
      final message = ChatMessage(
        id: 1,
        text: 'Hello World',
        // No delay parameter provided
      );

      // Assert
      expect(message.delay, AppConstants.defaultMessageDelay);
      expect(message.delay, 1000);
    });

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

    test('should default to bot sender when no sender specified in constructor', () {
      // Arrange & Act
      final message = ChatMessage(
        id: 1,
        text: 'Hello World',
        // No sender specified
      );

      // Assert
      expect(message.sender, 'bot');
      expect(message.isFromBot, true);
      expect(message.isFromUser, false);
    });

    test('should include sender in JSON even when it is the default value', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: 'Hello World',
        // sender defaults to 'bot'
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['sender'], 'bot');
      expect(json.containsKey('sender'), true);
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
      expect(message.text, ''); // Choice messages have no text content
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
        text: '', // Choice messages have no text content
        delay: 1500,
        sender: 'user',
        type: MessageType.choice,
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
        text: '', // Choice messages have no text content
        delay: 1500,
        sender: 'user',
        type: MessageType.choice,
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
      expect(message.text, ''); // Text input messages have no text content
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
        text: '', // Text input messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.textInput,
        nextMessageId: 6,
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 5);
      expect(json['text'], ''); // Text input messages have no text content
      expect(json['isTextInput'], true);
      expect(json['nextMessageId'], 6);
    });

    test('should identify text input messages correctly', () {
      // Arrange
      final textInputMessage = ChatMessage(
        id: 5,
        text: '', // Text input messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.textInput,
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
      expect(message.text, equals('')); // Text input messages have no text content
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
        text: '', // Text input messages have no text content
        delay: 1000,
        sender: 'bot',
        type: MessageType.textInput,
        storeKey: 'user.name',
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['text'], equals('')); // Text input messages have no text content
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

  group('placeholderText field', () {
    test('should use default placeholder text when not provided in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Enter your name',
        'isTextInput': true,
        // No placeholderText field provided
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.placeholderText, 'Type your answer...');
    });

    test('should use provided placeholder text when specified in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'text': 'Enter your name',
        'isTextInput': true,
        'placeholderText': 'Enter your full name here...',
      };

      // Act
      final message = ChatMessage.fromJson(json);

      // Assert
      expect(message.placeholderText, 'Enter your full name here...');
    });

    test('should include placeholderText in toJson when provided', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: '', // Text input messages have no text content
        type: MessageType.textInput,
        placeholderText: 'Your name here...',
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['placeholderText'], 'Your name here...');
    });

    test('should not include placeholderText in toJson when using default', () {
      // Arrange
      final message = ChatMessage(
        id: 1,
        text: '', // Text input messages have no text content
        type: MessageType.textInput,
        // Using default placeholder text
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json.containsKey('placeholderText'), false);
    });
  });

  group('Multi-text functionality with separator', () {
    test('should detect multi-text message with separator', () {
      final message = ChatMessage(
        id: 1,
        text: 'First message ||| Second message ||| Third message',
        sender: 'bot',
      );

      expect(message.hasMultipleTexts, isTrue);
    });

    test('should detect single text message without separator', () {
      final message = ChatMessage(
        id: 1,
        text: 'Single message',
        sender: 'bot',
      );

      expect(message.hasMultipleTexts, isFalse);
    });

    test('should return correct allTexts for single text message', () {
      final message = ChatMessage(
        id: 1,
        text: 'Single message',
        sender: 'bot',
      );

      expect(message.allTexts, equals(['Single message']));
    });

    test('should return correct allTexts for multi-text message with separator', () {
      final message = ChatMessage(
        id: 1,
        text: 'First message ||| Second message ||| Third message',
        sender: 'bot',
      );

      expect(message.allTexts, equals(['First message', 'Second message', 'Third message']));
    });

    test('should handle extra whitespace around separator', () {
      final message = ChatMessage(
        id: 1,
        text: 'First message  |||  Second message  |||  Third message',
        sender: 'bot',
      );

      expect(message.allTexts, equals(['First message', 'Second message', 'Third message']));
    });

    test('should return correct allDelays for single text message', () {
      final message = ChatMessage(
        id: 1,
        text: 'Single message',
        delay: 1500,
        sender: 'bot',
      );

      expect(message.allDelays, equals([1500]));
    });

    test('should return correct allDelays for multi-text message', () {
      final message = ChatMessage(
        id: 1,
        text: 'First message ||| Second message ||| Third message',
        delay: 1200,
        sender: 'bot',
      );

      expect(message.allDelays, equals([1200, 1200, 1200]));
    });

    test('should expand single text message to single message', () {
      final message = ChatMessage(
        id: 1,
        text: 'Single message',
        delay: 1000,
        sender: 'bot',
        nextMessageId: 2,
      );

      final expanded = message.expandToIndividualMessages();

      expect(expanded.length, equals(1));
      expect(expanded[0].id, equals(1));
      expect(expanded[0].text, equals('Single message'));
      expect(expanded[0].nextMessageId, equals(2));
    });

    test('should expand multi-text message to individual messages', () {
      final message = ChatMessage(
        id: 10,
        text: 'First message ||| Second message ||| Third message',
        delay: 1500,
        sender: 'bot',
        nextMessageId: 20,
      );

      final expanded = message.expandToIndividualMessages();

      expect(expanded.length, equals(3));
      
      // First message
      expect(expanded[0].id, equals(10));
      expect(expanded[0].text, equals('First message'));
      expect(expanded[0].delay, equals(1500));
      expect(expanded[0].isChoice, isFalse);
      expect(expanded[0].choices, isNull);
      expect(expanded[0].nextMessageId, isNull);
      
      // Second message
      expect(expanded[1].id, equals(11));
      expect(expanded[1].text, equals('Second message'));
      expect(expanded[1].delay, equals(1500));
      expect(expanded[1].isChoice, isFalse);
      expect(expanded[1].choices, isNull);
      expect(expanded[1].nextMessageId, isNull);
      
      // Third message (last one gets the next message ID)
      expect(expanded[2].id, equals(12));
      expect(expanded[2].text, equals('Third message'));
      expect(expanded[2].delay, equals(1500));
      expect(expanded[2].isChoice, isFalse);
      expect(expanded[2].choices, isNull);
      expect(expanded[2].nextMessageId, equals(20));
    });

    test('should handle empty segments in multi-text', () {
      final message = ChatMessage(
        id: 1,
        text: 'First message ||| ||| Third message',
        sender: 'bot',
      );

      // Empty segments should be filtered out
      expect(message.allTexts, equals(['First message', 'Third message']));
    });

    group('Text field separation enforcement', () {
      test('should enforce empty text for choice messages from JSON with text field', () {
        // Arrange
        final json = {
          'id': 1,
          'text': 'This text should be ignored for choice messages',
          'isChoice': true,
          'choices': [
            {'text': 'Option 1', 'nextMessageId': 2}
          ]
        };

        // Act
        final message = ChatMessage.fromJson(json);

        // Assert
        expect(message.text, '');
        expect(message.isChoice, true);
      });

      test('should enforce empty text for autoroute messages from JSON with text field', () {
        // Arrange
        final json = {
          'id': 1,
          'text': 'This text should be ignored for autoroute messages',
          'isAutoRoute': true,
          'routes': [
            {'default': true, 'nextMessageId': 2}
          ]
        };

        // Act
        final message = ChatMessage.fromJson(json);

        // Assert
        expect(message.text, '');
        expect(message.isAutoRoute, true);
      });

      test('should allow text for regular messages', () {
        // Arrange
        final json = {
          'id': 1,
          'text': 'This text should be preserved for regular messages',
        };

        // Act
        final message = ChatMessage.fromJson(json);

        // Assert
        expect(message.text, 'This text should be preserved for regular messages');
        expect(message.isChoice, false);
        expect(message.isTextInput, false);
        expect(message.isAutoRoute, false);
      });
    });
  });
}