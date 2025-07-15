import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/models/data_action.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
  group('DataActionProcessor', () {
    late UserDataService userDataService;
    late DataActionProcessor processor;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      processor = DataActionProcessor(userDataService);
    });

    tearDown(() async {
      await userDataService.clearAllData();
    });

    test('should process set action', () async {
      final action = DataAction(
        type: DataActionType.set,
        key: 'user.name',
        value: 'John',
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<String>('user.name');
      expect(result, 'John');
    });

    test('should process increment action', () async {
      // Set initial value
      await userDataService.storeValue('user.score', 10);

      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.score',
        value: 5,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.score');
      expect(result, 15);
    });

    test('should process increment action with default value', () async {
      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.score',
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.score');
      expect(result, 1); // Default increment is 1
    });

    test('should process increment action on non-existent key', () async {
      final action = DataAction(
        type: DataActionType.increment,
        key: 'user.newScore',
        value: 10,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.newScore');
      expect(result, 10); // Should start from 0 and add 10
    });

    test('should process decrement action', () async {
      // Set initial value
      await userDataService.storeValue('user.lives', 5);

      final action = DataAction(
        type: DataActionType.decrement,
        key: 'user.lives',
        value: 2,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.lives');
      expect(result, 3);
    });

    test('should process decrement action with default value', () async {
      // Set initial value
      await userDataService.storeValue('user.lives', 5);

      final action = DataAction(
        type: DataActionType.decrement,
        key: 'user.lives',
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.lives');
      expect(result, 4); // Default decrement is 1
    });

    test('should process decrement action on non-existent key', () async {
      final action = DataAction(
        type: DataActionType.decrement,
        key: 'user.newLives',
        value: 3,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.newLives');
      expect(result, -3); // Should start from 0 and subtract 3
    });

    test('should process reset action', () async {
      // Set initial value
      await userDataService.storeValue('user.streak', 25);

      final action = DataAction(
        type: DataActionType.reset,
        key: 'user.streak',
        value: 0,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.streak');
      expect(result, 0);
    });

    test('should process reset action with default value', () async {
      // Set initial value
      await userDataService.storeValue('user.streak', 25);

      final action = DataAction(
        type: DataActionType.reset,
        key: 'user.streak',
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.streak');
      expect(result, 0); // Default reset value is 0
    });

    test('should process reset action with custom value', () async {
      // Set initial value
      await userDataService.storeValue('user.level', 5);

      final action = DataAction(
        type: DataActionType.reset,
        key: 'user.level',
        value: 1,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>('user.level');
      expect(result, 1);
    });

    test('should process multiple actions in sequence', () async {
      final actions = [
        DataAction(
          type: DataActionType.set,
          key: 'user.score',
          value: 10,
        ),
        DataAction(
          type: DataActionType.increment,
          key: 'user.score',
          value: 5,
        ),
        DataAction(
          type: DataActionType.set,
          key: 'user.name',
          value: 'John',
        ),
      ];

      await processor.processActions(actions);

      final score = await userDataService.getValue<int>('user.score');
      final name = await userDataService.getValue<String>('user.name');
      
      expect(score, 15);
      expect(name, 'John');
    });

    test('should handle empty actions list', () async {
      await processor.processActions([]);

      // Should not throw error
      expect(true, true);
    });

    test('should process trigger action', () async {
      String? capturedEvent;
      Map<String, dynamic>? capturedData;

      // Set up event callback
      processor.setEventCallback((eventType, data) async {
        capturedEvent = eventType;
        capturedData = data;
      });

      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'achievement_unlocked',
        data: {
          'title': 'Test Achievement',
          'description': 'Test description',
        },
      );

      await processor.processActions([action]);

      expect(capturedEvent, 'achievement_unlocked');
      expect(capturedData, {
        'title': 'Test Achievement',
        'description': 'Test description',
      });
    });

    test('should process trigger action without data', () async {
      String? capturedEvent;
      Map<String, dynamic>? capturedData;

      // Set up event callback
      processor.setEventCallback((eventType, data) async {
        capturedEvent = eventType;
        capturedData = data;
      });

      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'simple_event',
      );

      await processor.processActions([action]);

      expect(capturedEvent, 'simple_event');
      expect(capturedData, {});
    });

    test('should handle trigger action without callback', () async {
      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'achievement_unlocked',
      );

      // Should not throw error even without callback
      await processor.processActions([action]);
      
      expect(true, true);
    });

    test('should handle trigger action without event', () async {
      String? capturedEvent;
      
      // Set up event callback
      processor.setEventCallback((eventType, data) async {
        capturedEvent = eventType;
      });

      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
      );

      await processor.processActions([action]);

      // Should not trigger callback when event is null
      expect(capturedEvent, isNull);
    });

    test('should handle error in event callback gracefully', () async {
      // Set up event callback that throws an error
      processor.setEventCallback((eventType, data) async {
        throw Exception('Test error');
      });

      final action = DataAction(
        type: DataActionType.trigger,
        key: 'event.key',
        event: 'achievement_unlocked',
      );

      // Should not throw error even if callback fails
      await processor.processActions([action]);
      
      expect(true, true);
    });

    test('should process mixed actions with triggers', () async {
      final events = <String>[];
      
      // Set up event callback
      processor.setEventCallback((eventType, data) async {
        events.add(eventType);
      });

      final actions = [
        DataAction(
          type: DataActionType.set,
          key: 'user.score',
          value: 50,
        ),
        DataAction(
          type: DataActionType.trigger,
          key: 'event.key',
          event: 'score_updated',
        ),
        DataAction(
          type: DataActionType.increment,
          key: 'user.score',
          value: 50,
        ),
        DataAction(
          type: DataActionType.trigger,
          key: 'event.key',
          event: 'achievement_unlocked',
        ),
      ];

      await processor.processActions(actions);

      final score = await userDataService.getValue<int>('user.score');
      expect(score, 100);
      expect(events, ['score_updated', 'achievement_unlocked']);
    });
  });
}