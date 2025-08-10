import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('ChatMessage ContentKey Support', () {
    test('should accept contentKey in constructor', () {
      final message = ChatMessage(
        id: 1,
        text: 'Hello world',
        contentKey: 'bot.inform.welcome.casual',
      );

      expect(message.contentKey, equals('bot.inform.welcome.casual'));
    });

    test('should handle null contentKey', () {
      final message = ChatMessage(id: 1, text: 'Hello world', contentKey: null);

      expect(message.contentKey, isNull);
    });

    test('should handle empty contentKey', () {
      final message = ChatMessage(id: 1, text: 'Hello world', contentKey: '');

      expect(message.contentKey, equals(''));
    });

    test('should serialize contentKey to JSON', () {
      final message = ChatMessage(
        id: 1,
        text: 'Hello world',
        contentKey: 'bot.acknowledge.completion.positive',
      );

      final json = message.toJson();
      expect(json['contentKey'], equals('bot.acknowledge.completion.positive'));
    });

    test('should not include contentKey in JSON when null', () {
      final message = ChatMessage(id: 1, text: 'Hello world', contentKey: null);

      final json = message.toJson();
      expect(json.containsKey('contentKey'), isFalse);
    });

    test('should deserialize contentKey from JSON', () {
      final json = {
        'id': 1,
        'text': 'Hello world',
        'type': 'bot',
        'contentKey': 'bot.request.input.gentle',
      };

      final message = ChatMessage.fromJson(json);
      expect(message.contentKey, equals('bot.request.input.gentle'));
    });

    test('should handle missing contentKey in JSON', () {
      final json = {'id': 1, 'text': 'Hello world', 'type': 'bot'};

      final message = ChatMessage.fromJson(json);
      expect(message.contentKey, isNull);
    });

    test('should create copyWith method that handles contentKey', () {
      final originalMessage = ChatMessage(
        id: 1,
        text: 'Hello world',
        contentKey: 'bot.inform.welcome',
      );

      final copiedMessage = originalMessage.copyWith(
        contentKey: 'bot.inform.welcome.casual',
      );

      expect(copiedMessage.contentKey, equals('bot.inform.welcome.casual'));
      expect(
        copiedMessage.id,
        equals(originalMessage.id),
      ); // Other fields preserved
      expect(copiedMessage.text, equals(originalMessage.text));
    });

    test('should preserve contentKey when expanding multi-text messages', () {
      final multiTextMessage = ChatMessage(
        id: 1,
        text: 'First part ||| Second part ||| Third part',
        contentKey: 'bot.inform.multi_welcome.casual',
      );

      final expandedMessages = multiTextMessage.expandToIndividualMessages();

      expect(expandedMessages.length, equals(3));
      // Only the last message should have the contentKey for processing
      expect(expandedMessages[0].contentKey, isNull);
      expect(expandedMessages[1].contentKey, isNull);
      expect(
        expandedMessages[2].contentKey,
        equals('bot.inform.multi_welcome.casual'),
      );
    });

    test('should handle contentKey with choice messages', () {
      final choiceMessage = ChatMessage(
        id: 1,
        text: '',
        type: MessageType.choice,
        contentKey: 'bot.request.task_status.gentle',
        choices: [
          Choice(
            text: 'Completed',
            contentKey: 'user.choose.task_status.completed',
          ),
          Choice(text: 'Failed', contentKey: 'user.choose.task_status.failed'),
        ],
      );

      expect(
        choiceMessage.contentKey,
        equals('bot.request.task_status.gentle'),
      );
      expect(
        choiceMessage.choices![0].contentKey,
        equals('user.choose.task_status.completed'),
      );
      expect(
        choiceMessage.choices![1].contentKey,
        equals('user.choose.task_status.failed'),
      );
    });
  });
}
