import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/route_condition.dart';

void main() {
  group('RouteCondition', () {
    test('should create RouteCondition from JSON', () {
      // Arrange
      final json = {
        'condition': 'user.age >= 18',
        'nextMessageId': 10,
      };

      // Act
      final route = RouteCondition.fromJson(json);

      // Assert
      expect(route.condition, 'user.age >= 18');
      expect(route.nextMessageId, 10);
      expect(route.sequenceId, null);
      expect(route.isDefault, false);
    });

    test('should create default RouteCondition from JSON', () {
      // Arrange
      final json = {
        'default': true,
        'nextMessageId': 20,
      };

      // Act
      final route = RouteCondition.fromJson(json);

      // Assert
      expect(route.condition, null);
      expect(route.nextMessageId, 20);
      expect(route.sequenceId, null);
      expect(route.isDefault, true);
    });

    test('should convert RouteCondition to JSON', () {
      // Arrange
      final route = RouteCondition(
        condition: 'user.level == "advanced"',
        nextMessageId: 30,
      );

      // Act
      final json = route.toJson();

      // Assert
      expect(json['condition'], 'user.level == "advanced"');
      expect(json['nextMessageId'], 30);
      expect(json.containsKey('sequenceId'), false);
      expect(json.containsKey('default'), false);
    });

    test('should ignore nextMessageId when sequenceId is present in fromJson', () {
      // Arrange
      final json = {
        'condition': 'user.premium == true',
        'sequenceId': 'premium_flow',
        'nextMessageId': 5, // This should be ignored
      };

      // Act
      final route = RouteCondition.fromJson(json);

      // Assert
      expect(route.condition, 'user.premium == true');
      expect(route.sequenceId, 'premium_flow');
      expect(route.nextMessageId, null); // Should be null, not 5
    });

    test('should not include nextMessageId in toJson when sequenceId is present', () {
      // Arrange
      final route = RouteCondition(
        condition: 'user.needs_help == true',
        sequenceId: 'help_sequence',
        nextMessageId: 10, // This should be ignored in toJson
      );

      // Act
      final json = route.toJson();

      // Assert
      expect(json['condition'], 'user.needs_help == true');
      expect(json['sequenceId'], 'help_sequence');
      expect(json.containsKey('nextMessageId'), false);
    });

    test('should include nextMessageId in toJson when sequenceId is not present', () {
      // Arrange
      final route = RouteCondition(
        condition: 'user.score > 80',
        nextMessageId: 15,
      );

      // Act
      final json = route.toJson();

      // Assert
      expect(json['condition'], 'user.score > 80');
      expect(json['nextMessageId'], 15);
      expect(json.containsKey('sequenceId'), false);
    });

    test('should support equality comparison', () {
      // Arrange
      final route1 = RouteCondition(condition: 'user.age >= 21', nextMessageId: 25);
      final route2 = RouteCondition(condition: 'user.age >= 21', nextMessageId: 25);
      final route3 = RouteCondition(condition: 'user.age >= 18', nextMessageId: 25);

      // Act & Assert
      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });
  });
}