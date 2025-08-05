import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/models/data_action.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/session_service.dart';

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
        key: StorageKeys.userName,
        value: 'John',
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<String>(StorageKeys.userName);
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
      await userDataService.storeValue(StorageKeys.userStreak, 25);

      final action = DataAction(
        type: DataActionType.reset,
        key: StorageKeys.userStreak,
        value: 0,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>(StorageKeys.userStreak);
      expect(result, 0);
    });

    test('should process reset action with default value', () async {
      // Set initial value
      await userDataService.storeValue(StorageKeys.userStreak, 25);

      final action = DataAction(
        type: DataActionType.reset,
        key: StorageKeys.userStreak,
      );

      await processor.processActions([action]);

      final result = await userDataService.getValue<int>(StorageKeys.userStreak);
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
          key: StorageKeys.userName,
          value: 'John',
        ),
      ];

      await processor.processActions(actions);

      final score = await userDataService.getValue<int>('user.score');
      final name = await userDataService.getValue<String>(StorageKeys.userName);
      
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

    group('Template Functions', () {
      late SessionService sessionService;
      late DataActionProcessor processorWithSession;

      setUp(() async {
        sessionService = SessionService(userDataService);
        processorWithSession = DataActionProcessor(userDataService, sessionService: sessionService);
      });

      test('should resolve TODAY_DATE template function', () async {
        final today = DateTime.now();
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.date',
          value: 'TODAY_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.date');
        expect(result, expectedDate);
      });

      test('should resolve NEXT_ACTIVE_DATE_1 when today is active', () async {
        // Set active days to include today
        final today = DateTime.now();
        await userDataService.storeValue('task.activeDays', [today.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE_1',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve NEXT_ACTIVE_DATE_1 when today is not active', () async {
        // Set active days to exclude today but include tomorrow
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        await userDataService.storeValue('task.activeDays', [tomorrow.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE_1',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve NEXT_ACTIVE_DATE_2 correctly', () async {
        // Set active days to Monday and Wednesday (1 and 3)
        await userDataService.storeValue('task.activeDays', [1, 3]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.secondNextDate',
          value: 'NEXT_ACTIVE_DATE_2',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.secondNextDate');
        expect(result, isNotNull);
        // Should be a valid date string
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result!), true);
      });

      test('should resolve NEXT_ACTIVE_DATE_3 with weekdays only', () async {
        // Set active days to weekdays only (1-5)
        await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.thirdNextDate',
          value: 'NEXT_ACTIVE_DATE_3',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.thirdNextDate');
        expect(result, isNotNull);
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result!), true);
      });

      test('should handle NEXT_ACTIVE_DATE_X with no active days configured', () async {
        // Don't set any active days
        final today = DateTime.now();

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE_2',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final tomorrow = today.add(const Duration(days: 1));
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should handle invalid NEXT_ACTIVE_DATE index gracefully', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE_0',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        expect(result, isNotNull);
        // Should still return a valid date (fallback to index 1)
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result!), true);
      });

      test('should handle non-template string values unchanged', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.customDate',
          value: '2024-12-25',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.customDate');
        expect(result, '2024-12-25');
      });

      test('should work without session service (fallback mode)', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE_2',
        );

        // Use processor without session service
        await processor.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final today = DateTime.now();
        final expectedDate = today.add(const Duration(days: 1));
        final expectedDateString = '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}';
        expect(result, expectedDateString);
      });

      test('should resolve FIRST_ACTIVE_DAY when today is active', () async {
        // Set active days to include today
        final today = DateTime.now();
        await userDataService.storeValue('task.activeDays', [today.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDay',
          value: 'FIRST_ACTIVE_DAY',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.firstActiveDay');
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve FIRST_ACTIVE_DAY when today is not active', () async {
        // Set active days to exclude today but include tomorrow
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        await userDataService.storeValue('task.activeDays', [tomorrow.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDay',
          value: 'FIRST_ACTIVE_DAY',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.firstActiveDay');
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve FIRST_ACTIVE_DAY with no active days configured', () async {
        // Don't set any active days - should default to today
        final today = DateTime.now();

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDay',
          value: 'FIRST_ACTIVE_DAY',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.firstActiveDay');
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve FIRST_ACTIVE_DAY with weekdays only', () async {
        // Set active days to weekdays only (1-5)
        await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDay',
          value: 'FIRST_ACTIVE_DAY',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.firstActiveDay');
        expect(result, isNotNull);
        // Should be a valid date string
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result!), true);
        
        // Parse the result date and verify it's a weekday
        final resultDate = DateTime.parse(result);
        expect([1, 2, 3, 4, 5].contains(resultDate.weekday), true);
      });

      test('should resolve FIRST_ACTIVE_DAY without session service (fallback)', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDay',
          value: 'FIRST_ACTIVE_DAY',
        );

        // Use processor without session service
        await processor.processActions([action]);

        final result = await userDataService.getValue<String>('task.firstActiveDay');
        final today = DateTime.now();
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });
    });

    group('Recalculate Triggers', () {
      late SessionService sessionService;
      late DataActionProcessor processorWithSession;
      
      setUp(() async {
        sessionService = SessionService(userDataService);
        processorWithSession = DataActionProcessor(userDataService, sessionService: sessionService);
      });

      test('should handle recalculate_end_date trigger', () async {
        bool triggerCalled = false;
        String? capturedEvent;
        Map<String, dynamic>? capturedData;
        
        processorWithSession.setEventCallback((eventType, data) async {
          triggerCalled = true;
          capturedEvent = eventType;
          capturedData = data;
        });

        final action = DataAction(
          type: DataActionType.trigger,
          key: 'test.key',
          event: 'recalculate_end_date',
        );

        await processorWithSession.processActions([action]);

        // Verify trigger was called with correct event type
        expect(triggerCalled, true);
        expect(capturedEvent, 'recalculate_end_date');
        expect(capturedData, {});
      });

      test('should handle recalculate_end_date trigger with data payload', () async {
        bool triggerCalled = false;
        String? capturedEvent;
        Map<String, dynamic>? capturedData;
        
        processorWithSession.setEventCallback((eventType, data) async {
          triggerCalled = true;
          capturedEvent = eventType;
          capturedData = data;
        });

        final action = DataAction(
          type: DataActionType.trigger,
          key: 'test.key',
          event: 'recalculate_end_date',
          data: {'reason': 'task_updated'},
        );

        await processorWithSession.processActions([action]);

        expect(triggerCalled, true);
        expect(capturedEvent, 'recalculate_end_date');
        expect(capturedData, {'reason': 'task_updated'});
      });

      test('should handle recalculate_end_date trigger without callback set', () async {
        final action = DataAction(
          type: DataActionType.trigger,
          key: 'test.key',
          event: 'recalculate_end_date',
        );

        // Should not throw error even without callback
        await processorWithSession.processActions([action]);
        
        expect(true, true); // Test passes if no exception thrown
      });
    });
  });
}