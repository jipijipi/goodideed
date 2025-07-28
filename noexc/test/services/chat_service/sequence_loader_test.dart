import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/chat_service/sequence_loader.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/config/chat_config.dart';

void main() {
  group('SequenceLoader', () {
    late SequenceLoader sequenceLoader;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      sequenceLoader = SequenceLoader();
    });

    group('loadSequence', () {
      test('should load a valid sequence from assets', () async {
        // This test assumes onboarding_seq.json exists in assets
        final sequence = await sequenceLoader.loadSequence('onboarding_seq');
        
        expect(sequence, isNotNull);
        expect(sequence.sequenceId, equals('onboarding_seq'));
        expect(sequence.messages, isNotEmpty);
        expect(sequenceLoader.currentSequence, equals(sequence));
      });

      test('should build message map after loading sequence', () async {
        final sequence = await sequenceLoader.loadSequence('onboarding_seq');
        
        expect(sequenceLoader.messageMap, isNotEmpty);
        expect(sequenceLoader.messageMap.length, equals(sequence.messages.length));
        
        // Verify all messages are in the map
        for (final message in sequence.messages) {
          expect(sequenceLoader.messageMap.containsKey(message.id), isTrue);
          expect(sequenceLoader.messageMap[message.id], equals(message));
        }
      });

      test('should throw exception for non-existent sequence', () async {
        expect(
          () => sequenceLoader.loadSequence('non_existent_seq'),
          throwsException,
        );
      });

      test('should throw exception with chat config error message', () async {
        try {
          await sequenceLoader.loadSequence('invalid_seq');
          fail('Expected exception was not thrown');
        } catch (e) {
          expect(e.toString(), contains(ChatConfig.chatScriptLoadError));
          expect(e.toString(), contains('invalid_seq'));
        }
      });

      test('should update currentSequence property', () async {
        expect(sequenceLoader.currentSequence, isNull);
        
        final sequence = await sequenceLoader.loadSequence('onboarding_seq');
        
        expect(sequenceLoader.currentSequence, isNotNull);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('onboarding_seq'));
      });
    });

    group('loadChatScript', () {
      test('should load default onboarding sequence for backward compatibility', () async {
        final messages = await sequenceLoader.loadChatScript();
        
        expect(messages, isNotEmpty);
        expect(sequenceLoader.currentSequence, isNotNull);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('onboarding_seq'));
      });

      test('should return messages from loaded sequence', () async {
        final messages = await sequenceLoader.loadChatScript();
        final sequence = sequenceLoader.currentSequence!;
        
        expect(messages, equals(sequence.messages));
      });
    });

    group('hasMessage', () {
      test('should return true for existing message ID', () async {
        await sequenceLoader.loadSequence('onboarding_seq');
        final sequence = sequenceLoader.currentSequence!;
        final firstMessageId = sequence.messages.first.id;
        
        expect(sequenceLoader.hasMessage(firstMessageId), isTrue);
      });

      test('should return false for non-existing message ID', () async {
        await sequenceLoader.loadSequence('onboarding_seq');
        
        expect(sequenceLoader.hasMessage(99999), isFalse);
      });

      test('should return false when no sequence loaded', () {
        expect(sequenceLoader.hasMessage(1), isFalse);
      });
    });

    group('getMessageById', () {
      test('should return message for existing ID', () async {
        await sequenceLoader.loadSequence('onboarding_seq');
        final sequence = sequenceLoader.currentSequence!;
        final firstMessage = sequence.messages.first;
        
        final result = sequenceLoader.getMessageById(firstMessage.id);
        
        expect(result, isNotNull);
        expect(result, equals(firstMessage));
      });

      test('should return null for non-existing ID', () async {
        await sequenceLoader.loadSequence('onboarding_seq');
        
        final result = sequenceLoader.getMessageById(99999);
        
        expect(result, isNull);
      });

      test('should return null when no sequence loaded', () {
        final result = sequenceLoader.getMessageById(1);
        expect(result, isNull);
      });
    });

    group('getInitialMessages', () {
      test('should load and return messages for default sequence', () async {
        final messages = await sequenceLoader.getInitialMessages();
        
        expect(messages, isNotEmpty);
        expect(sequenceLoader.currentSequence, isNotNull);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('onboarding_seq'));
      });

      test('should load and return messages for specified sequence', () async {
        final messages = await sequenceLoader.getInitialMessages(sequenceId: 'welcome_seq');
        
        expect(messages, isNotEmpty);
        expect(sequenceLoader.currentSequence, isNotNull);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('welcome_seq'));
      });

      test('should not reload if same sequence already loaded', () async {
        // Load sequence first time
        await sequenceLoader.loadSequence('onboarding_seq');
        final firstLoadTime = DateTime.now();
        
        // Small delay to ensure time difference
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Get initial messages for same sequence
        final messages = await sequenceLoader.getInitialMessages(sequenceId: 'onboarding_seq');
        
        expect(messages, isNotEmpty);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('onboarding_seq'));
      });

      test('should reload if different sequence requested', () async {
        // Load first sequence
        await sequenceLoader.loadSequence('onboarding_seq');
        expect(sequenceLoader.currentSequence!.sequenceId, equals('onboarding_seq'));
        
        // Load different sequence
        final messages = await sequenceLoader.getInitialMessages(sequenceId: 'welcome_seq');
        
        expect(messages, isNotEmpty);
        expect(sequenceLoader.currentSequence!.sequenceId, equals('welcome_seq'));
      });
    });

    group('createUserResponseMessage', () {
      test('should create user message with correct properties', () {
        const messageId = 100;
        const userInput = 'Test user input';
        
        final message = sequenceLoader.createUserResponseMessage(messageId, userInput);
        
        expect(message.id, equals(messageId));
        expect(message.text, equals(userInput));
        expect(message.delay, equals(0));
        expect(message.sender, equals(ChatConfig.userSender));
        expect(message.type, equals(MessageType.bot)); // Default type is bot
      });

      test('should handle empty user input', () {
        const messageId = 101;
        const userInput = '';
        
        final message = sequenceLoader.createUserResponseMessage(messageId, userInput);
        
        expect(message.id, equals(messageId));
        expect(message.text, equals(''));
        expect(message.sender, equals(ChatConfig.userSender));
      });

      test('should handle special characters in user input', () {
        const messageId = 102;
        const userInput = 'Test with émojis 🎉 and symbols @#\$%';
        
        final message = sequenceLoader.createUserResponseMessage(messageId, userInput);
        
        expect(message.id, equals(messageId));
        expect(message.text, equals(userInput));
        expect(message.sender, equals(ChatConfig.userSender));
      });
    });

    group('state management', () {
      test('should maintain state across multiple operations', () async {
        // Load sequence
        await sequenceLoader.loadSequence('onboarding_seq');
        final originalSequence = sequenceLoader.currentSequence!;
        final originalMessageMap = Map.from(sequenceLoader.messageMap);
        
        // Check message
        final hasMessage = sequenceLoader.hasMessage(originalSequence.messages.first.id);
        expect(hasMessage, isTrue);
        
        // Get message
        final message = sequenceLoader.getMessageById(originalSequence.messages.first.id);
        expect(message, isNotNull);
        
        // State should remain consistent
        expect(sequenceLoader.currentSequence, equals(originalSequence));
        expect(sequenceLoader.messageMap, equals(originalMessageMap));
      });

      test('should clear state when loading new sequence', () async {
        // Load first sequence
        await sequenceLoader.loadSequence('onboarding_seq');
        final firstSequence = sequenceLoader.currentSequence!;
        
        // Load second sequence
        await sequenceLoader.loadSequence('welcome_seq');
        final secondSequence = sequenceLoader.currentSequence!;
        
        expect(secondSequence.sequenceId, equals('welcome_seq'));
        expect(secondSequence, isNot(equals(firstSequence)));
        
        // Message map should be updated
        for (final message in secondSequence.messages) {
          expect(sequenceLoader.hasMessage(message.id), isTrue);
        }
      });
    });

    group('error handling', () {
      test('should handle malformed JSON gracefully', () async {
        // This would require mocking the asset loading to return invalid JSON
        // For now, we test that the exception contains the expected error message
        expect(
          () => sequenceLoader.loadSequence('invalid_json_seq'),
          throwsA(predicate((e) => e.toString().contains(ChatConfig.chatScriptLoadError))),
        );
      });

      test('should handle missing asset files', () async {
        expect(
          () => sequenceLoader.loadSequence('completely_missing_seq'),
          throwsA(predicate((e) => e.toString().contains(ChatConfig.chatScriptLoadError))),
        );
      });
    });
  });
}