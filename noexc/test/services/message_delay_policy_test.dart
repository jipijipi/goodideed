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
      final msg = ChatMessage.fromJson({
        'id': 1,
        'text': 'Hello there',
        'delay': 750,
        'sender': 'bot',
      });

      final delay = policy.effectiveDelay(msg);
      expect(delay, 750);
    });

    test('computes adaptive delay based on word count when no delay provided', () {
      final policy = MessageDelayPolicy();
      final msg = ChatMessage.fromJson({
        'id': 2,
        'text': 'Three little words', // 3 words
        // no delay field on purpose
        'sender': 'bot',
      });

      final delay = policy.effectiveDelay(msg);

      final expected = AppConstants.dynamicDelayBaseMs +
          3 * AppConstants.dynamicDelayPerWordMs;
      final clamped = expected.clamp(
        AppConstants.dynamicDelayMinMs,
        AppConstants.dynamicDelayMaxMs,
      );

      expect(delay, clamped);
    });

    test('returns zero delay in instant mode', () {
      final policy = MessageDelayPolicy(mode: DelayMode.instant);
      final msg = ChatMessage.fromJson({
        'id': 3,
        'text': 'Any words here',
        'sender': 'bot',
      });

      final delay = policy.effectiveDelay(msg);
      expect(delay, 0);
    });

    test('non-bot messages have no delay by default', () {
      final policy = MessageDelayPolicy();
      final msg = ChatMessage(
        id: 4,
        text: 'User reply',
        delay: 1000, // ignored for user messages
        sender: 'user',
        type: MessageType.user,
      );

      final delay = policy.effectiveDelay(msg);
      expect(delay, 0);
    });
  });
}

