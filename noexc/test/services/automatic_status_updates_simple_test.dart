import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/session_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Automatic Status Updates - Simple Tests', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should initialize with automatic status update functionality', () async {
      // Basic test to ensure new functionality doesn't break existing flow
      await sessionService.initializeSession();
      
      // Should have basic task tracking initialized
      expect(await userDataService.getValue<String>('task.current_date'), isNotNull);
      expect(await userDataService.getValue<String>('task.current_status'), 'pending');
    });

    test('should add auto-update logging storage keys', () async {
      // Test that new storage keys are available
      await sessionService.initializeSession();
      
      // These should be null initially (no updates yet)
      expect(await userDataService.getValue<String>('task.last_auto_update'), isNull);
      expect(await userDataService.getValue<String>('task.auto_update_reason'), isNull);
      
      // But the keys should be accessible
      await userDataService.storeValue('task.last_auto_update', 'test');
      expect(await userDataService.getValue<String>('task.last_auto_update'), 'test');
    });

    test('should preserve overdue status on same day (no morning recovery)', () async {
      // Setup: Set overdue status and morning time
      await sessionService.initializeSession();
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue('task.current_status', 'overdue');
      await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayMorning);
      
      // Trigger update - should preserve overdue status on same day
      await sessionService.initializeSession();
      
      // Should remain overdue (no morning recovery)
      expect(await userDataService.getValue<String>('task.current_status'), 'overdue');
    });

    test('should preserve overdue status regardless of time of day', () async {
      // Setup: Set overdue status and afternoon time
      await sessionService.initializeSession();
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue('task.current_status', 'overdue');
      await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayAfternoon);
      
      // Trigger update - should preserve status regardless of time
      await sessionService.initializeSession();
      
      // Should remain overdue (no time-based recovery)
      expect(await userDataService.getValue<String>('task.current_status'), 'overdue');
    });

    test('should log deadline-based status updates with proper format', () async {
      // Setup: Task with early deadline that will trigger overdue status
      await sessionService.initializeSession();
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue('task.deadline_time', '06:00'); // Early deadline
      await userDataService.storeValue('task.current_status', 'pending');
      
      // Trigger update - if current time is past 6 AM, should mark as overdue
      await sessionService.initializeSession();
      
      final now = DateTime.now();
      if (now.hour >= 6) {
        // Should log the deadline-passed update
        final updateReason = await userDataService.getValue<String>('task.auto_update_reason');
        final lastUpdate = await userDataService.getValue<String>('task.last_auto_update');
        
        expect(updateReason, contains('current_day: pending → overdue (deadline_passed)'));
        expect(lastUpdate, matches(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}'));
      }
    });

    test('should preserve completed status during automatic updates', () async {
      // Setup: Set completed status
      await sessionService.initializeSession();
      await userDataService.storeValue(StorageKeys.userTask, 'Test task');
      await userDataService.storeValue('task.current_status', 'completed');
      await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayMorning);
      
      // Trigger update
      await sessionService.initializeSession();
      
      // Should remain completed (not reset by morning logic)
      expect(await userDataService.getValue<String>('task.current_status'), 'completed');
    });

    test('should handle multiple session initializations', () async {
      // Test that multiple calls don't cause issues
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      
      // Should still work normally
      expect(await userDataService.getValue<String>('task.current_status'), 'pending');
    });
  });
}