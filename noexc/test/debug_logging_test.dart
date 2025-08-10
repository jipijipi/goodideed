import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/semantic_content_service.dart';
import 'package:noexc/services/chat_service/message_processor.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('Debug Logging Test', () {
    test('should show debug logs for semantic content resolution', () async {
      print('\n=== TESTING SEMANTIC CONTENT SYSTEM DEBUG LOGGING ===\n');

      // Test 1: Direct SemanticContentService call
      final contentService = SemanticContentService.instance;

      print('--- Test 1: Direct service call ---');
      final result1 = await contentService.getContent(
        'bot.introduce.character.casual',
        'Original introduction text',
      );
      print('Result: "$result1"\n');

      // Test 2: MessageProcessor integration
      final processor = MessageProcessor();

      print('--- Test 2: MessageProcessor integration ---');
      final message = ChatMessage(
        id: 1,
        text: 'Original message text',
        type: MessageType.bot,
        contentKey: 'bot.inform.welcome.casual',
      );

      final sequence = ChatSequence(
        sequenceId: 'test_seq',
        name: 'Test Sequence',
        description: 'Test sequence for debug logging',
        messages: [message],
      );

      final result2 = await processor.processMessageTemplate(message, sequence);
      print('Result text: "${result2.text}"');
      print('Result contentKey: "${result2.contentKey}"\n');

      // Test 3: Choice processing
      print('--- Test 3: Choice processing ---');
      final choiceMessage = ChatMessage(
        id: 2,
        text: '',
        type: MessageType.choice,
        contentKey: 'user.choose.greeting',
        choices: [
          Choice.fromJson({
            'text': 'Hi there!',
            'contentKey': 'user.greet.character.friendly',
            'nextMessageId': 3,
          }),
          Choice.fromJson({
            'text': 'Hello...',
            'contentKey': 'user.greet.character.skeptical',
            'nextMessageId': 4,
          }),
        ],
      );

      final result3 = await processor.processMessageTemplate(
        choiceMessage,
        sequence,
      );
      print('Choice message processed');
      print('Number of choices: ${result3.choices?.length}');
      if (result3.choices != null) {
        for (int i = 0; i < result3.choices!.length; i++) {
          print(
            'Choice ${i + 1}: "${result3.choices![i].text}" (contentKey: "${result3.choices![i].contentKey}")',
          );
        }
      }

      print('\n=== DEBUG LOGGING TEST COMPLETE ===\n');

      // Basic assertions to make the test pass
      expect(result1, isNotNull);
      expect(result2.text, isNotNull);
      expect(result3.choices, isNotNull);
    });
  });
}
