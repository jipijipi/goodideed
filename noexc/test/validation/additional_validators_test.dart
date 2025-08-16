import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/choice.dart';
import 'package:noexc/validation/sequence_validator.dart';
import 'package:noexc/models/route_condition.dart';
import 'package:noexc/constants/validation_constants.dart';

void main() {
  group('Additional validators', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    test('image message must have imagePath and no extraneous fields', () {
      final seq = ChatSequence(
        sequenceId: 's',
        name: 'n',
        description: '',
        messages: [
          ChatMessage(id: 1, text: '', type: MessageType.image),
          ChatMessage(id: 2, text: '', type: MessageType.image, imagePath: 'assets/img.png'),
        ],
      );

      final res = SequenceValidator().validateSequence(seq);
      // Error for msg 1 (missing imagePath)
      expect(
        res.errors
            .where((e) => e.type == ValidationConstants.invalidTextForType)
            .any((e) => e.messageId == 1),
        isTrue,
      );
      // No type-rule error for msg 2 (proper image)
      expect(
        res.errors
            .where((e) => e.type == ValidationConstants.invalidTextForType)
            .any((e) => e.messageId == 2),
        isFalse,
      );
    });

    test('delay hygiene warnings for non-display types', () {
      final seq = ChatSequence(
        sequenceId: 's',
        name: 'n',
        description: '',
        messages: [
          ChatMessage(id: 1, text: '', type: MessageType.choice, delay: 123, hasExplicitDelay: true),
          ChatMessage(id: 2, text: '', type: MessageType.autoroute, delay: 0, hasExplicitDelay: true),
        ],
      );
      final res = SequenceValidator().validateSequence(seq);
      // Warning for msg 1 (non-zero explicit delay on non-display type)
      expect(
        res.warnings
            .where((w) => w.type == 'UNNECESSARY_DELAY')
            .any((w) => w.messageId == 1),
        isTrue,
      );
      // No hygiene warning for msg 2 (explicit but zero delay)
      expect(
        res.warnings
            .where((w) => w.type == 'UNNECESSARY_DELAY')
            .any((w) => w.messageId == 2),
        isFalse,
      );
    });

    test('choice ambiguity warning when both sequenceId and nextMessageId', () {
      final seq = ChatSequence(
        sequenceId: 's',
        name: 'n',
        description: '',
        messages: [
          ChatMessage(
            id: 1,
            text: '',
            type: MessageType.choice,
            choices: [Choice(text: 'x', sequenceId: 'a', nextMessageId: 2)],
          ),
        ],
      );
      final res = SequenceValidator().validateSequence(seq);
      expect(res.warnings.any((w) => w.messageId == 1), isTrue);
    });

    test('route syntax warning for suspicious condition', () {
      final seq = ChatSequence(
        sequenceId: 's',
        name: 'n',
        description: '',
        messages: [
          ChatMessage(
            id: 1,
            text: '',
            type: MessageType.autoroute,
            routes: [
              // No operator, should warn
              // ignore: prefer_const_constructors
              RouteCondition(condition: 'user.name')
            ],
          ),
        ],
      );
      final res = SequenceValidator().validateSequence(seq);
      expect(res.warnings.any((w) => w.messageId == 1), isTrue);
    });
  });
}
