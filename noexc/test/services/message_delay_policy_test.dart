import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/app_constants.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/services/message_delay_policy.dart';

import '../test_helpers.dart';

void main() {
  setUp(() {
    setupQuietTesting();
  });

  group('MessageDelayPolicy', () {
    test('uses explicit delay from script when provided', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 0, text: 'Some previous text', delay: 0);
      final next = ChatMessage.fromJson({
        'id': 1,
        'text': 'Hello there',
        'delay': 750,
        'sender': 'bot',
      });

      final delay = policy.delayBefore(prev, next);
      expect(delay, 750);
    });

    test(
      'computes reading delay from previous message when no explicit delay',
      () {
        final policy = MessageDelayPolicy();
        final prev = ChatMessage.fromJson({
          'id': 1,
          'text': 'Three little words', // 3 words
          'sender': 'bot',
        });
        final next = ChatMessage.fromJson({
          'id': 2,
          'text': 'Next bubble',
          'sender': 'bot',
        });

        final delay = policy.delayBefore(prev, next);

        final expected =
            AppConstants.dynamicDelayBaseMs +
            3 * AppConstants.dynamicDelayPerWordMs;
        final clamped = expected.clamp(
          AppConstants.dynamicDelayMinMs,
          AppConstants.dynamicDelayMaxMs,
        );

        expect(delay, clamped);
      },
    );

    test('returns zero delay in instant mode', () {
      final policy = MessageDelayPolicy(mode: DelayMode.instant);
      final prev = ChatMessage(id: 1, text: 'Any words here', delay: 0);
      final next = ChatMessage(id: 2, text: 'Next', delay: 0, sender: 'bot');

      final delay = policy.delayBefore(prev, next);
      expect(delay, 0);
    });

    test('no delay before user messages', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Bot text', delay: 0, sender: 'bot');
      final userNext = ChatMessage(
        id: 4,
        text: 'User reply',
        delay: 1000, // ignored for user messages
        sender: 'user',
        type: MessageType.user,
      );

      final delay = policy.delayBefore(prev, userNext);
      expect(delay, 0);
    });

    test('applies constant delay for choice messages in production mode', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Read me', delay: 0, sender: 'bot');
      final choiceNext = ChatMessage(
        id: 10,
        text: '',
        type: MessageType.choice,
        sender: 'bot',
      );

      final delay = policy.delayBefore(prev, choiceNext);
      expect(delay, AppConstants.choiceDisplayDelayMs);
    });

    test('choice messages are instant in instant mode', () {
      final policy = MessageDelayPolicy(mode: DelayMode.instant);
      final prev = ChatMessage(id: 1, text: 'Prev', delay: 0, sender: 'bot');
      final choiceNext = ChatMessage(
        id: 11,
        text: '',
        type: MessageType.choice,
        sender: 'user', // even if sender is user, instant wins
      );

      final delay = policy.delayBefore(prev, choiceNext);
      expect(delay, 0);
    });

    test('no delay for image messages', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Previous message', delay: 0, sender: 'bot');
      final imageNext = ChatMessage(
        id: 12,
        text: '',
        type: MessageType.image,
        sender: 'bot',
      );

      final delay = policy.delayBefore(prev, imageNext);
      expect(delay, 0, reason: 'Image messages should have no delay for fast resume');
    });

    test('no delay for dataAction messages', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Previous message', delay: 0, sender: 'bot');
      final dataActionNext = ChatMessage(
        id: 13,
        text: '',
        type: MessageType.dataAction,
        sender: 'bot',
      );

      final delay = policy.delayBefore(prev, dataActionNext);
      expect(delay, 0, reason: 'DataAction messages should have no delay for fast resume');
    });

    test('no delay for autoroute messages', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Previous message', delay: 0, sender: 'bot');
      final autorouteNext = ChatMessage(
        id: 14,
        text: '',
        type: MessageType.autoroute,
        sender: 'bot',
      );

      final delay = policy.delayBefore(prev, autorouteNext);
      expect(delay, 0, reason: 'Autoroute messages should have no delay for fast resume');
    });

    test('bot text messages still get reading delays in adaptive mode', () {
      final policy = MessageDelayPolicy();
      final prev = ChatMessage(id: 1, text: 'Previous with some words here', delay: 0, sender: 'bot');
      final botTextNext = ChatMessage(
        id: 15,
        text: 'This is a bot text message',
        type: MessageType.bot,
        sender: 'bot',
      );

      final delay = policy.delayBefore(prev, botTextNext);
      expect(delay, greaterThan(0), reason: 'Bot text messages should still have reading delays for natural conversation');
    });
  });
}
