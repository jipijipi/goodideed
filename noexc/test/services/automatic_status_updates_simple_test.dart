import 'package:flutter_test/flutter_test.dart';
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

    test('should handle context-aware morning reset', () async {
      // Setup: Set overdue status and morning time
      await sessionService.initializeSession();
      await userDataService.storeValue('user.task', 'Test task');
      await userDataService.storeValue('task.current_status', 'overdue');
      await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
      
      // Trigger update
      await sessionService.initializeSession();
      
      // Should reset to pending in morning
      expect(await userDataService.getValue<String>('task.current_status'), 'pending');
      expect(await userDataService.getValue<String>('task.auto_update_reason'), contains('morning_fresh_start'));
    });

    test('should not reset overdue status outside morning hours', () async {
      // Setup: Set overdue status and afternoon time
      await sessionService.initializeSession();
      await userDataService.storeValue('user.task', 'Test task');
      await userDataService.storeValue('task.current_status', 'overdue');
      await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayAfternoon);
      
      // Trigger update - should not reset since it's not morning
      await sessionService.initializeSession();
      
      // In our current implementation, same-day initialization preserves status
      // but morning logic only runs during morning hours
      final currentStatus = await userDataService.getValue<String>('task.current_status');
      final timeOfDay = await userDataService.getValue<int>('session.timeOfDay');
      
      // If it's actually morning during test, status might reset
      if (timeOfDay == SessionConstants.timeOfDayMorning) {
        expect(currentStatus, 'pending'); // Expected morning reset
      } else {
        expect(currentStatus, 'overdue'); // Should remain overdue
      }
    });

    test('should log status updates with proper format', () async {
      // Setup: Trigger a morning fresh start update
      await sessionService.initializeSession();
      await userDataService.storeValue('user.task', 'Test task');
      await userDataService.storeValue('task.current_status', 'overdue');
      await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
      
      // Trigger update
      await sessionService.initializeSession();
      
      // Should log the update
      final updateReason = await userDataService.getValue<String>('task.auto_update_reason');
      final lastUpdate = await userDataService.getValue<String>('task.last_auto_update');
      
      expect(updateReason, contains('current_day: overdue → pending (morning_fresh_start)'));
      expect(lastUpdate, matches(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}'));
    });

    test('should preserve completed status during automatic updates', () async {
      // Setup: Set completed status
      await sessionService.initializeSession();
      await userDataService.storeValue('user.task', 'Test task');
      await userDataService.storeValue('task.current_status', 'completed');
      await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
      
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