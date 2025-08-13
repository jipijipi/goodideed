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

      final result = await userDataService.getValue<String>(
        StorageKeys.userName,
      );
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

      final result = await userDataService.getValue<int>(
        StorageKeys.userStreak,
      );
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

      final result = await userDataService.getValue<int>(
        StorageKeys.userStreak,
      );
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
        DataAction(type: DataActionType.set, key: 'user.score', value: 10),
        DataAction(type: DataActionType.increment, key: 'user.score', value: 5),
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
        data: {'title': 'Test Achievement', 'description': 'Test description'},
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

      final action = DataAction(type: DataActionType.trigger, key: 'event.key');

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
        DataAction(type: DataActionType.set, key: 'user.score', value: 50),
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
        processorWithSession = DataActionProcessor(
          userDataService,
          sessionService: sessionService,
        );
      });

      test('should resolve TODAY_DATE template function', () async {
        final today = DateTime.now();
        final expectedDate =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.date',
          value: 'TODAY_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.date');
        expect(result, expectedDate);
      });

      test('should resolve NEXT_ACTIVE_DATE excluding today', () async {
        // Set active days to include today and tomorrow
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        await userDataService.storeValue('task.activeDays', [
          today.weekday,
          tomorrow.weekday,
        ]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final expectedDate =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate); // Should be tomorrow, not today
      });

      test('should handle non-template string values unchanged', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.customDate',
          value: '2024-12-25',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>(
          'task.customDate',
        );
        expect(result, '2024-12-25');
      });

      test('should work without session service (fallback mode)', () async {
        final action = DataAction(
          type: DataActionType.set,
          key: 'task.nextDate',
          value: 'NEXT_ACTIVE_DATE',
        );

        // Use processor without session service
        await processor.processActions([action]);

        final result = await userDataService.getValue<String>('task.nextDate');
        final today = DateTime.now();
        final expectedDate = today.add(const Duration(days: 1));
        final expectedDateString =
            '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}';
        expect(result, expectedDateString);
      });

      test('should resolve FIRST_ACTIVE_DATE when today is active', () async {
        // Set active days to include today
        final today = DateTime.now();
        await userDataService.storeValue('task.activeDays', [today.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDate',
          value: 'FIRST_ACTIVE_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>(
          'task.firstActiveDate',
        );
        final expectedDate =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test('should resolve FIRST_ACTIVE_DATE when today is not active', () async {
        // Set active days to exclude today but include tomorrow
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        await userDataService.storeValue('task.activeDays', [tomorrow.weekday]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDate',
          value: 'FIRST_ACTIVE_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>(
          'task.firstActiveDate',
        );
        final expectedDate =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(result, expectedDate);
      });

      test(
        'should resolve FIRST_ACTIVE_DATE with no active days configured',
        () async {
          // Don't set any active days - should default to today
          final today = DateTime.now();

          final action = DataAction(
            type: DataActionType.set,
            key: 'task.firstActiveDate',
            value: 'FIRST_ACTIVE_DATE',
          );

          await processorWithSession.processActions([action]);

          final result = await userDataService.getValue<String>(
            'task.firstActiveDate',
          );
          final expectedDate =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          expect(result, expectedDate);
        },
      );

      test('should resolve FIRST_ACTIVE_DATE with weekdays only', () async {
        // Set active days to weekdays only (1-5)
        await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);

        final action = DataAction(
          type: DataActionType.set,
          key: 'task.firstActiveDate',
          value: 'FIRST_ACTIVE_DATE',
        );

        await processorWithSession.processActions([action]);

        final result = await userDataService.getValue<String>(
          'task.firstActiveDate',
        );
        expect(result, isNotNull);
        // Should be a valid date string
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result!), true);

        // Parse the result date and verify it's a weekday
        final resultDate = DateTime.parse(result);
        expect([1, 2, 3, 4, 5].contains(resultDate.weekday), true);
      });

      test(
        'should resolve FIRST_ACTIVE_DATE without session service (fallback)',
        () async {
          final action = DataAction(
            type: DataActionType.set,
            key: 'task.firstActiveDate',
            value: 'FIRST_ACTIVE_DATE',
          );

          // Use processor without session service
          await processor.processActions([action]);

          final result = await userDataService.getValue<String>(
            'task.firstActiveDate',
          );
          final today = DateTime.now();
          final expectedDate =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          expect(result, expectedDate);
        },
      );
    });

    group('Recalculate Triggers', () {
      late SessionService sessionService;
      late DataActionProcessor processorWithSession;

      setUp(() async {
        sessionService = SessionService(userDataService);
        processorWithSession = DataActionProcessor(
          userDataService,
          sessionService: sessionService,
        );
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

      test(
        'should handle recalculate_end_date trigger with data payload',
        () async {
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
        },
      );

      test(
        'should handle recalculate_end_date trigger without callback set',
        () async {
          final action = DataAction(
            type: DataActionType.trigger,
            key: 'test.key',
            event: 'recalculate_end_date',
          );

          // Should not throw error even without callback
          await processorWithSession.processActions([action]);

          expect(true, true); // Test passes if no exception thrown
        },
      );

      test('should handle refresh_task_calculations trigger', () async {
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
          event: 'refresh_task_calculations',
        );

        await processorWithSession.processActions([action]);

        // Verify trigger was called with correct event type
        expect(triggerCalled, true);
        expect(capturedEvent, 'refresh_task_calculations');
        expect(capturedData, {});
      });

      test(
        'should handle refresh_task_calculations trigger with data payload',
        () async {
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
            event: 'refresh_task_calculations',
            data: {'reason': 'active_days_updated'},
          );

          await processorWithSession.processActions([action]);

          expect(triggerCalled, true);
          expect(capturedEvent, 'refresh_task_calculations');
          expect(capturedData, {'reason': 'active_days_updated'});
        },
      );

      test(
        'should handle refresh_task_calculations trigger for comprehensive recalculation',
        () async {
          bool triggerCalled = false;
          String? capturedEvent;

          processorWithSession.setEventCallback((eventType, data) async {
            triggerCalled = true;
            capturedEvent = eventType;
          });

          final action = DataAction(
            type: DataActionType.trigger,
            key: 'test.key',
            event: 'refresh_task_calculations',
            data: {'reason': 'task_configuration_changed'},
          );

          await processorWithSession.processActions([action]);

          // Verify trigger was called - this would recalculate:
          // - task.endDate + task.isPastEndDate
          // - task.dueDay
          // - task.status
          expect(triggerCalled, true);
          expect(capturedEvent, 'refresh_task_calculations');
        },
      );

      test(
        'should handle refresh_task_calculations trigger without callback set',
        () async {
          final action = DataAction(
            type: DataActionType.trigger,
            key: 'test.key',
            event: 'refresh_task_calculations',
          );

          // Should not throw error even without callback
          await processorWithSession.processActions([action]);

          expect(true, true); // Test passes if no exception thrown
        },
      );
    });

    group('List Operations', () {
      test('should append to empty list (create new)', () async {
        final action = DataAction(
          type: DataActionType.append,
          key: 'user.tags',
          value: 'important',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['important']);
      });

      test('should append to existing list', () async {
        // Set initial list
        await userDataService.storeValue('user.tags', ['first', 'second']);

        final action = DataAction(
          type: DataActionType.append,
          key: 'user.tags',
          value: 'third',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['first', 'second', 'third']);
      });

      test('should not append duplicate values', () async {
        // Set initial list
        await userDataService.storeValue('user.tags', ['first', 'second']);

        final action = DataAction(
          type: DataActionType.append,
          key: 'user.tags',
          value: 'second', // Duplicate
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['first', 'second']); // No duplicate added
      });

      test('should append to JSON string list', () async {
        // Set initial list as JSON string (how weekdays are often stored)
        await userDataService.storeValue('task.activeDays', '[1,2,3]');

        final action = DataAction(
          type: DataActionType.append,
          key: 'task.activeDays',
          value: 4,
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('task.activeDays');
        expect(result, [1, 2, 3, 4]);
      });

      test('should handle append with null value gracefully', () async {
        final action = DataAction(
          type: DataActionType.append,
          key: 'user.tags',
          value: null,
        );

        await processor.processActions([action]);

        // Should not create list or modify anything
        final result = await userDataService.getValue<List>('user.tags');
        expect(result, isNull);
      });

      test('should handle append to non-list value gracefully', () async {
        // Set a non-list value
        await userDataService.storeValue('user.name', 'John');

        final action = DataAction(
          type: DataActionType.append,
          key: 'user.name',
          value: 'Doe',
        );

        await processor.processActions([action]);

        // Original value should remain unchanged
        final result = await userDataService.getValue<String>('user.name');
        expect(result, 'John');
      });

      test('should remove from existing list', () async {
        // Set initial list
        await userDataService.storeValue('user.tags', ['first', 'second', 'third']);

        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.tags',
          value: 'second',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['first', 'third']);
      });

      test('should remove from JSON string list', () async {
        // Set initial list as JSON string
        await userDataService.storeValue('task.activeDays', '[1,2,3,4,5]');

        final action = DataAction(
          type: DataActionType.remove,
          key: 'task.activeDays',
          value: 3,
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('task.activeDays');
        expect(result, [1, 2, 4, 5]);
      });

      test('should handle remove from non-existent key gracefully', () async {
        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.nonexistent',
          value: 'something',
        );

        await processor.processActions([action]);

        // Should not throw error
        expect(true, true);
      });

      test('should handle remove non-existent value gracefully', () async {
        // Set initial list
        await userDataService.storeValue('user.tags', ['first', 'second']);

        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.tags',
          value: 'nonexistent',
        );

        await processor.processActions([action]);

        // List should remain unchanged
        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['first', 'second']);
      });

      test('should handle remove with null value gracefully', () async {
        await userDataService.storeValue('user.tags', ['first', 'second']);

        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.tags',
          value: null,
        );

        await processor.processActions([action]);

        // List should remain unchanged
        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['first', 'second']);
      });

      test('should handle remove from non-list value gracefully', () async {
        // Set a non-list value
        await userDataService.storeValue('user.name', 'John');

        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.name',
          value: 'John',
        );

        await processor.processActions([action]);

        // Original value should remain unchanged
        final result = await userDataService.getValue<String>('user.name');
        expect(result, 'John');
      });

      test('should remove multiple instances of same value', () async {
        // Set initial list with duplicates
        await userDataService.storeValue('user.tags', ['first', 'second', 'first', 'third']);

        final action = DataAction(
          type: DataActionType.remove,
          key: 'user.tags',
          value: 'first',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['second', 'third']);
      });

      test('should process mixed list operations', () async {
        final actions = [
          DataAction(type: DataActionType.set, key: 'user.tags', value: ['initial']),
          DataAction(type: DataActionType.append, key: 'user.tags', value: 'second'),
          DataAction(type: DataActionType.append, key: 'user.tags', value: 'third'),
          DataAction(type: DataActionType.remove, key: 'user.tags', value: 'initial'),
        ];

        await processor.processActions(actions);

        final result = await userDataService.getValue<List>('user.tags');
        expect(result, ['second', 'third']);
      });

      test('should handle complex weekday scenario', () async {
        final actions = [
          // Start with weekdays only
          DataAction(type: DataActionType.set, key: 'task.activeDays', value: [1, 2, 3, 4, 5]),
          // Add Saturday
          DataAction(type: DataActionType.append, key: 'task.activeDays', value: 6),
          // Add Sunday
          DataAction(type: DataActionType.append, key: 'task.activeDays', value: 7),
          // Remove Wednesday
          DataAction(type: DataActionType.remove, key: 'task.activeDays', value: 3),
        ];

        await processor.processActions(actions);

        final result = await userDataService.getValue<List>('task.activeDays');
        expect(result, [1, 2, 4, 5, 6, 7]); // Mon, Tue, Thu, Fri, Sat, Sun
      });

      test('should handle JSON parsing errors gracefully', () async {
        // Set an invalid JSON string
        await userDataService.storeValue('task.activeDays', '[1,2,invalid}');

        final action = DataAction(
          type: DataActionType.append,
          key: 'task.activeDays',
          value: 3,
        );

        await processor.processActions([action]);

        // Should not throw error and leave original value unchanged
        final result = await userDataService.getValue<String>('task.activeDays');
        expect(result, '[1,2,invalid}');
      });

      test('should parse JSON list with mixed types', () async {
        // Set JSON list with mixed number and string types
        await userDataService.storeValue('mixed.list', '[1,"hello",3]');

        final action = DataAction(
          type: DataActionType.append,
          key: 'mixed.list',
          value: 'world',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('mixed.list');
        expect(result, [1, 'hello', 3, 'world']);
      });

      test('should handle empty JSON list', () async {
        await userDataService.storeValue('empty.list', '[]');

        final action = DataAction(
          type: DataActionType.append,
          key: 'empty.list',
          value: 'first',
        );

        await processor.processActions([action]);

        final result = await userDataService.getValue<List>('empty.list');
        expect(result, ['first']);
      });
    });
  });
}
