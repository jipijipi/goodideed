import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('Choice', () {
    test('should create Choice from JSON', () {
      // Arrange
      final json = {
        'text': 'Red',
        'nextMessageId': 10,
      };

      // Act
      final choice = Choice.fromJson(json);

      // Assert
      expect(choice.text, 'Red');
      expect(choice.nextMessageId, 10);
    });

    test('should convert Choice to JSON', () {
      // Arrange
      final choice = Choice(
        text: 'Blue',
        nextMessageId: 20,
      );

      // Act
      final json = choice.toJson();

      // Assert
      expect(json['text'], 'Blue');
      expect(json['nextMessageId'], 20);
    });

    test('should support equality comparison', () {
      // Arrange
      final choice1 = Choice(text: 'Green', nextMessageId: 30);
      final choice2 = Choice(text: 'Green', nextMessageId: 30);
      final choice3 = Choice(text: 'Red', nextMessageId: 30);

      // Act & Assert
      expect(choice1, equals(choice2));
      expect(choice1, isNot(equals(choice3)));
    });

    test('should ignore nextMessageId when sequenceId is present in fromJson', () {
      // Arrange
      final json = {
        'text': 'Go to Tutorial',
        'sequenceId': 'tutorial',
        'nextMessageId': 5, // This should be ignored
      };

      // Act
      final choice = Choice.fromJson(json);

      // Assert
      expect(choice.text, 'Go to Tutorial');
      expect(choice.sequenceId, 'tutorial');
      expect(choice.nextMessageId, null); // Should be null, not 5
    });

    test('should not include nextMessageId in toJson when sequenceId is present', () {
      // Arrange
      final choice = Choice(
        text: 'Go to Menu',
        sequenceId: 'menu',
        nextMessageId: 10, // This should be ignored in toJson
      );

      // Act
      final json = choice.toJson();

      // Assert
      expect(json['text'], 'Go to Menu');
      expect(json['sequenceId'], 'menu');
      expect(json.containsKey('nextMessageId'), false);
    });

    test('should include nextMessageId in toJson when sequenceId is not present', () {
      // Arrange
      final choice = Choice(
        text: 'Continue',
        nextMessageId: 15,
      );

      // Act
      final json = choice.toJson();

      // Assert
      expect(json['text'], 'Continue');
      expect(json['nextMessageId'], 15);
      expect(json.containsKey('sequenceId'), false);
    });
  });
}
