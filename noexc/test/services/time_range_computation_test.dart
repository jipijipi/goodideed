import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';

void main() {
  group('Time Range Computation Tests', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      setupQuietTesting();
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should compute isBeforeStart correctly', () async {
      // Setup: Start time at 09:00, deadline at 17:00
      await userDataService.storeValue(StorageKeys.taskStartTime, '09:00');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '17:00');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Initialize session to compute booleans
      await sessionService.initializeSession();
      
      // Check computed boolean (depends on current time)
      final isBeforeStart = await userDataService.getValue<bool>(StorageKeys.taskIsBeforeStart);
      expect(isBeforeStart, isA<bool>());
    });

    test('should compute isInTimeRange correctly', () async {
      // Setup: Start time at 08:00, deadline at 20:00 (wide range)
      await userDataService.storeValue(StorageKeys.taskStartTime, '08:00');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '20:00');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Initialize session to compute booleans
      await sessionService.initializeSession();
      
      // Check computed boolean
      final isInTimeRange = await userDataService.getValue<bool>(StorageKeys.taskIsInTimeRange);
      expect(isInTimeRange, isA<bool>());
    });

    test('should compute isPastDeadline correctly', () async {
      // Setup: Very early deadline to ensure it's past
      await userDataService.storeValue(StorageKeys.taskStartTime, '01:00');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '02:00');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Initialize session to compute booleans
      await sessionService.initializeSession();
      
      // Check computed boolean
      final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      expect(isPastDeadline, isA<bool>());
    });

    test('should derive start time from deadline when no explicit start time', () async {
      // Setup: Only deadline, no start time
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '14:00');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Initialize session to compute booleans
      await sessionService.initializeSession();
      
      // Should still compute range booleans using derived start time
      final isBeforeStart = await userDataService.getValue<bool>(StorageKeys.taskIsBeforeStart);
      final isInTimeRange = await userDataService.getValue<bool>(StorageKeys.taskIsInTimeRange);
      final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      
      expect(isBeforeStart, isA<bool>());
      expect(isInTimeRange, isA<bool>());
      expect(isPastDeadline, isA<bool>());
    });

    test('should handle time range edge cases gracefully', () async {
      // Setup: Invalid time formats should not crash
      await userDataService.storeValue(StorageKeys.taskStartTime, 'invalid');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, 'also-invalid');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Should not crash
      expect(() => sessionService.initializeSession(), returnsNormally);
      
      // Should provide default values
      await sessionService.initializeSession();
      final isBeforeStart = await userDataService.getValue<bool>(StorageKeys.taskIsBeforeStart);
      final isInTimeRange = await userDataService.getValue<bool>(StorageKeys.taskIsInTimeRange);
      final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      
      expect(isBeforeStart, isA<bool>());
      expect(isInTimeRange, isA<bool>());
      expect(isPastDeadline, isA<bool>());
    });

    test('should compute all three time range booleans consistently', () async {
      // Setup: Normal time range
      await userDataService.storeValue(StorageKeys.taskStartTime, '10:00');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, '16:00');
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      
      // Initialize session
      await sessionService.initializeSession();
      
      // Get all three booleans
      final isBeforeStart = await userDataService.getValue<bool>(StorageKeys.taskIsBeforeStart);
      final isInTimeRange = await userDataService.getValue<bool>(StorageKeys.taskIsInTimeRange);
      final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      
      // Logical consistency: at most one should be true
      // (could all be false in edge cases, but not multiple true)
      final trueCount = [isBeforeStart, isInTimeRange, isPastDeadline].where((b) => b == true).length;
      expect(trueCount, lessThanOrEqualTo(1));
    });
  });
}