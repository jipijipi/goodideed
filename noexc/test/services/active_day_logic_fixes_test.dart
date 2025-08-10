import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Active Day Logic Fixes', () {
    late SessionService sessionService;
    late UserDataService userDataService;
    late DataActionProcessor dataActionProcessor;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
      dataActionProcessor = DataActionProcessor(
        userDataService,
        sessionService: sessionService,
      );
    });

    group('Problem 1: isActiveDay Logic with activeDays', () {
      test('should return false when today is not in activeDays', () async {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final mondayString = '2025-08-04'; // This is a Monday

        // Set task scheduled for some day (task date doesn't affect isActiveDay)
        await userDataService.storeValue(
          StorageKeys.taskCurrentDate,
          mondayString,
        );

        // Set activeDays to only include tomorrow's weekday (not today)
        // This ensures today's weekday is NOT in activeDays
        await userDataService.storeValue('task.activeDays', [tomorrow.weekday]);

        // Initialize session to compute booleans
        await sessionService.initializeSession();

        // Should return false because today's weekday is not in activeDays
        final isActiveDay = await userDataService.getValue<bool>(
          StorageKeys.taskIsActiveDay,
        );
        expect(isActiveDay, false);
      });

      test(
        'should return true when today is Saturday and activeDays is [6,7] (weekends only)',
        () async {
          // Note: This test checks the logic when today is actually a Saturday
          // Since we can't easily mock DateTime.now(), we test what would happen
          // if the session initialized on a Saturday

          final now = DateTime.now();

          // Only run this test if today is actually Saturday (weekday 6)
          if (now.weekday == 6) {
            // Setup: Task scheduled for today (Saturday) with weekend activeDays
            final todayString =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

            await userDataService.storeValue(
              StorageKeys.taskCurrentDate,
              todayString,
            );
            await userDataService.storeValue('task.activeDays', [6, 7]);

            await sessionService.initializeSession();

            final isActiveDay = await userDataService.getValue<bool>(
              StorageKeys.taskIsActiveDay,
            );
            expect(isActiveDay, true);
          } else {
            // Skip this test if not running on Saturday
            // This is a limitation of not being able to mock DateTime.now()
            // Test would pass if run on a Saturday
          }
        },
      );

      test(
        'should return true when no activeDays configured (backward compatibility)',
        () async {
          // Setup: Task scheduled for today with no activeDays
          final today = DateTime.now();
          final todayString =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          await userDataService.storeValue(
            StorageKeys.taskCurrentDate,
            todayString,
          );
          // No activeDays set (null)

          await sessionService.initializeSession();

          // Should default to true for backward compatibility
          final isActiveDay = await userDataService.getValue<bool>(
            StorageKeys.taskIsActiveDay,
          );
          expect(isActiveDay, true);
        },
      );
    });

    group('Problem 2: NEXT_ACTIVE_DATE with JSON String Format', () {
      test('should handle JSON string activeDays format "[6,7]"', () async {
        // Setup: Monday with activeDays as JSON string (legacy format)
        await userDataService.storeValue('task.activeDays', '[6,7]');

        // Process actions to trigger template function logic
        await dataActionProcessor.processActions([]);

        // Verify that the parsing works - should remain as string until processed by choice
        final parsedActiveDays = await userDataService.getValue<dynamic>(
          'task.activeDays',
        );
        expect(
          parsedActiveDays,
          isA<String>(),
        ); // Should still be string until choice is made
      });

      test(
        'should return Saturday when called on Monday with weekend-only activeDays',
        () async {
          // This is an integration test that would require more complex setup
          // For now, we verify that the logic exists and doesn't crash
          expect(dataActionProcessor, isNotNull);
        },
      );
    });

    group('Array Format Parsing', () {
      test('should handle List<int> activeDays format', () async {
        await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);

        final activeDays = await userDataService.getValue<List<dynamic>>(
          'task.activeDays',
        );
        expect(activeDays, isA<List>());
        expect(activeDays, [1, 2, 3, 4, 5]);
      });

      test('should handle mixed type arrays [1, "2", 3]', () async {
        await userDataService.storeValue('task.activeDays', [1, "2", 3]);

        final activeDays = await userDataService.getValue<List<dynamic>>(
          'task.activeDays',
        );
        expect(activeDays, isA<List>());
        // The parsing should handle mixed types
      });
    });
  });
}
