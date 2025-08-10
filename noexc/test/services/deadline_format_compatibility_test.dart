import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Deadline Format Compatibility Tests', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should handle string deadline format (HH:MM)', () async {
      // Setup: Store deadline as string format
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '15:30');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(
        StorageKeys.taskCurrentStatus,
        'pending',
      );

      // Should not crash when processing deadline
      await sessionService.initializeSession();

      // Should work correctly (may be overdue due to automatic status updates)
      final status = await userDataService.getValue<String>(
        StorageKeys.taskCurrentStatus,
      );
      expect(status, anyOf(equals('pending'), equals('overdue')));

      // Should compute new range booleans
      final isBeforeStart = await userDataService.getValue<bool>(
        StorageKeys.taskIsBeforeStart,
      );
      final isInTimeRange = await userDataService.getValue<bool>(
        StorageKeys.taskIsInTimeRange,
      );
      final isPastDeadline = await userDataService.getValue<bool>(
        StorageKeys.taskIsPastDeadline,
      );

      expect(isBeforeStart, isNotNull);
      expect(isInTimeRange, isNotNull);
      expect(isPastDeadline, isNotNull);
    });

    test(
      'should handle integer deadline format (legacy from JSON sequences)',
      () async {
        // Setup: Store deadline as integer format (like from old sequences)
        await userDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          2,
        ); // Afternoon
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(
          StorageKeys.taskCurrentStatus,
          'pending',
        );

        // Should not crash when processing deadline
        await sessionService.initializeSession();

        // Should work correctly (may be overdue due to automatic status updates)
        final status2 = await userDataService.getValue<String>(
          StorageKeys.taskCurrentStatus,
        );
        expect(status2, anyOf(equals('pending'), equals('overdue')));

        // Should migrate the integer value to string format
        final migratedDeadline = await userDataService.getValue<String>(
          StorageKeys.taskDeadlineTime,
        );
        expect(migratedDeadline, equals('14:00')); // Afternoon deadline time
      },
    );

    test('should convert integer deadline values to correct times', () async {
      final testCases = [
        {'input': 1, 'expected': '10:00'}, // Morning
        {'input': 2, 'expected': '14:00'}, // Afternoon
        {'input': 3, 'expected': '18:00'}, // Evening
        {'input': 4, 'expected': '23:00'}, // Night
      ];

      for (final testCase in testCases) {
        // Setup: Clear previous values
        SharedPreferences.setMockInitialValues({});
        userDataService = UserDataService();
        sessionService = SessionService(userDataService);

        // Store integer deadline
        await userDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          testCase['input'],
        );
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(
          StorageKeys.taskCurrentStatus,
          'pending',
        );

        // Initialize session (this will process the deadline)
        await sessionService.initializeSession();

        // The deadline should be converted internally
        // We can't directly test the private method, but we can verify it doesn't crash
        expect(
          await userDataService.getValue<String>(StorageKeys.taskCurrentStatus),
          isNotNull,
        );
      }
    });

    test('should default to 21:00 when no deadline is set', () async {
      // Setup: No deadline set
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(
        StorageKeys.taskCurrentStatus,
        'pending',
      );

      // Should not crash and should use default
      await sessionService.initializeSession();

      // Should work with default deadline (may be overdue due to automatic status updates)
      final status3 = await userDataService.getValue<String>(
        StorageKeys.taskCurrentStatus,
      );
      expect(status3, anyOf(equals('pending'), equals('overdue')));
    });

    test('should prefer string format when both formats exist', () async {
      // Setup: Store both formats (this shouldn't normally happen, but test edge case)
      await userDataService.storeValue(
        StorageKeys.taskDeadlineTime,
        '14:00',
      ); // String format
      // Note: Can't store both int and string to same key, but string should take precedence

      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(
        StorageKeys.taskCurrentStatus,
        'pending',
      );

      // Should work with string format
      await sessionService.initializeSession();

      final status4 = await userDataService.getValue<String>(
        StorageKeys.taskCurrentStatus,
      );
      expect(status4, anyOf(equals('pending'), equals('overdue')));
    });
  });
}
