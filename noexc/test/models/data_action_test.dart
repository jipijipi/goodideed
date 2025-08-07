import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/data_action.dart';

void main() {
  group('DataAction', () {
    test('should create DataAction with set type', () {
      final action = DataAction(
        type: DataActionType.set,
        key: 'user.name',
        value: 'John',
      );

      expect(action.type, DataActionType.set);
      expect(action.key, 'user.name');
      expect(action.value, 'John');
    });

    test('should create DataAction with increment type', () {
      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.score',
        value: 10,
      );

      expect(action.type, DataActionType.increment);
      expect(action.key, 'user.score');
      expect(action.value, 10);
    });

    test('should create DataAction with decrement type', () {
      final action = DataAction(
        type: DataActionType.decrement,
        key: 'user.lives',
        value: 1,
      );

      expect(action.type, DataActionType.decrement);
      expect(action.key, 'user.lives');
      expect(action.value, 1);
    });

    test('should create DataAction with reset type', () {
      final action = DataAction(
        type: DataActionType.reset,
        key: 'user.streak',
        value: 0,
      );

      expect(action.type, DataActionType.reset);
      expect(action.key, 'user.streak');
      expect(action.value, 0);
    });

    test('should create DataAction without value', () {
      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.count',
      );

      expect(action.type, DataActionType.increment);
      expect(action.key, 'user.count');
      expect(action.value, isNull);
    });

    test('should convert to JSON correctly', () {
      final action = DataAction(
        type: DataActionType.set,
        key: 'user.name',
        value: 'John',
      );

      final json = action.toJson();

      expect(json['type'], 'set');
      expect(json['key'], 'user.name');
      expect(json['value'], 'John');
    });

    test('should convert to JSON without value', () {
      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.score',
      );

      final json = action.toJson();

      expect(json['type'], 'increment');
      expect(json['key'], 'user.score');
      expect(json.containsKey('value'), false);
    });

    test('should create from JSON correctly', () {
      final json = {
        'type': 'set',
        'key': 'user.name',
        'value': 'John',
      };

      final action = DataAction.fromJson(json);

      expect(action.type, DataActionType.set);
      expect(action.key, 'user.name');
      expect(action.value, 'John');
    });

    test('should create from JSON without value', () {
      final json = {
        'type': 'increment',
        'key': 'user.score',
      };

      final action = DataAction.fromJson(json);

      expect(action.type, DataActionType.increment);
      expect(action.key, 'user.score');
      expect(action.value, isNull);
    });

    test('should handle invalid type in JSON', () {
      final json = {
        'type': 'invalid_type',
        'key': 'user.name',
        'value': 'John',
      };

      final action = DataAction.fromJson(json);

      expect(action.type, DataActionType.set); // Should default to set
      expect(action.key, 'user.name');
      expect(action.value, 'John');
    });

    test('should create DataAction with trigger type', () {
      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'achievement_unlocked',
        data: {
          'title': 'Test Achievement',
          'description': 'Test description',
        },
      );

      expect(action.type, DataActionType.trigger);
      expect(action.key, 'event.key');
      expect(action.event, 'achievement_unlocked');
      expect(action.data, {
        'title': 'Test Achievement',
        'description': 'Test description',
      });
    });

    test('should create DataAction with trigger type from JSON', () {
      final json = {
        'type': 'trigger',
        'key': 'event.key',
        'event': 'achievement_unlocked',
        'data': {
          'title': 'Test Achievement',
          'description': 'Test description',
        },
      };

      final action = DataAction.fromJson(json);

      expect(action.type, DataActionType.trigger);
      expect(action.key, 'event.key');
      expect(action.event, 'achievement_unlocked');
      expect(action.data, {
        'title': 'Test Achievement',
        'description': 'Test description',
      });
    });

    test('should serialize trigger DataAction to JSON', () {
      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'achievement_unlocked',
        data: {
          'title': 'Test Achievement',
          'description': 'Test description',
        },
      );

      final json = action.toJson();

      expect(json['type'], 'trigger');
      expect(json['key'], 'event.key');
      expect(json['event'], 'achievement_unlocked');
      expect(json['data'], {
        'title': 'Test Achievement',
        'description': 'Test description',
      });
    });

    test('should create trigger DataAction without data', () {
      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'simple_event',
      );

      expect(action.type, DataActionType.trigger);
      expect(action.key, 'event.key');
      expect(action.event, 'simple_event');
      expect(action.data, isNull);
    });

    test('should serialize trigger DataAction without data', () {
      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'simple_event',
      );

      final json = action.toJson();

      expect(json['type'], 'trigger');
      expect(json['key'], 'event.key');
      expect(json['event'], 'simple_event');
      expect(json.containsKey('data'), false);
    });
  });
}
