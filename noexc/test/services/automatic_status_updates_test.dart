import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/session_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Automatic Status Updates (Phase 1)', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    group('Current Day Deadline Checks', () {
      test('should mark pending task as overdue after deadline', () async {
        // Setup: Initialize session first to set up basic data
        await sessionService.initializeSession();
        
        // Then set up task with early deadline  
        await userDataService.storeValue('user.task', 'Test task');
        await userDataService.storeValue('task.deadline_time', '06:00'); // Early deadline
        
        // Run session again to trigger deadline check
        await sessionService.initializeSession();
        
        // Should automatically mark as overdue (assuming test runs after 6 AM)
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>('task.current_status'), 'overdue');
          expect(await userDataService.getValue<String>('task.auto_update_reason'), contains('deadline_passed'));
        } else {
          expect(await userDataService.getValue<String>('task.current_status'), 'pending');
        }
      });

      test('should not update non-pending tasks', () async {
        // Setup: Initialize session first
        await sessionService.initializeSession();
        
        // Set up completed task past deadline
        await userDataService.storeValue('user.task', 'Test task');
        await userDataService.storeValue('task.current_status', 'completed');
        await userDataService.storeValue('task.deadline_time', '06:00');
        
        // Run session again
        await sessionService.initializeSession();
        
        // Should remain completed regardless of deadline
        expect(await userDataService.getValue<String>('task.current_status'), 'completed');
      });

      test('should not update if no task exists', () async {
        // Setup: No task set
        await userDataService.storeValue('task.deadline_time', '06:00');
        await sessionService.initializeSession();
        
        // Should remain pending (default) and not trigger overdue
        expect(await userDataService.getValue<String>('task.current_status'), 'pending');
        expect(await userDataService.getValue<String>('task.auto_update_reason'), isNull);
      });
    });

    group('Context-Aware Status Updates', () {
      test('should reset overdue to pending in morning', () async {
        // Setup: Task marked as overdue
        await userDataService.storeValue('user.task', 'Morning task');
        await userDataService.storeValue('task.current_status', 'overdue');
        await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
        
        await sessionService.initializeSession();
        
        // Should reset to pending for fresh start
        expect(await userDataService.getValue<String>('task.current_status'), 'pending');
        expect(await userDataService.getValue<String>('task.auto_update_reason'), contains('morning_fresh_start'));
      });

      test('should not reset overdue outside morning hours', () async {
        // Setup: Task marked as overdue in afternoon
        await userDataService.storeValue('user.task', 'Afternoon task');
        await userDataService.storeValue('task.current_status', 'overdue');
        await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayAfternoon);
        
        await sessionService.initializeSession();
        
        // Should remain overdue
        expect(await userDataService.getValue<String>('task.current_status'), 'overdue');
      });

      test('should not update non-overdue statuses in morning', () async {
        // Setup: Completed task in morning
        await userDataService.storeValue('user.task', 'Morning task');
        await userDataService.storeValue('task.current_status', 'completed');
        await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
        
        await sessionService.initializeSession();
        
        // Should remain completed
        expect(await userDataService.getValue<String>('task.current_status'), 'completed');
      });
    });

    group('Status Update Logging', () {
      test('should log automatic status updates with timestamp', () async {
        // Setup: Overdue task in morning (will trigger fresh start)
        await userDataService.storeValue('user.task', 'Test task');
        await userDataService.storeValue('task.current_status', 'overdue');
        await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
        
        await sessionService.initializeSession();
        
        // Should log the update
        final updateReason = await userDataService.getValue<String>('task.auto_update_reason');
        final lastUpdate = await userDataService.getValue<String>('task.last_auto_update');
        
        expect(updateReason, isNotNull);
        expect(updateReason, contains('current_day: overdue → pending (morning_fresh_start)'));
        expect(lastUpdate, isNotNull);
        expect(lastUpdate, matches(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}')); // Date-time format
      });

      test('should not log if no updates occur', () async {
        // Setup: Normal pending task with future deadline
        await userDataService.storeValue('user.task', 'Future task');
        await userDataService.storeValue('task.deadline_time', '23:59');
        await sessionService.initializeSession();
        
        // Should not log anything
        expect(await userDataService.getValue<String>('task.auto_update_reason'), isNull);
        expect(await userDataService.getValue<String>('task.last_auto_update'), isNull);
      });
    });

    group('Enhanced Grace Period Logging', () {
      test('should log previous day grace period expiration', () async {
        // Setup: Previous day task with expired grace period
        await userDataService.storeValue('task.previous_status', 'pending');
        await userDataService.storeValue('task.deadline_time', '06:00'); // Early deadline
        
        // Simulate moving to new day
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue('task.current_date', yesterdayString);
        
        await sessionService.initializeSession();
        
        // Should log grace period expiration (if test runs after 6 AM)
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>('task.previous_status'), 'failed');
          expect(await userDataService.getValue<String>('task.auto_update_reason'), contains('grace_period_expired'));
        }
      });
    });

    group('Integration Scenarios', () {
      test('should handle multiple status updates in one session', () async {
        // Setup: Complex scenario with both current and previous day updates
        await userDataService.storeValue('user.task', 'Complex task');
        await userDataService.storeValue('task.current_status', 'overdue');
        await userDataService.storeValue('task.previous_status', 'pending');
        await userDataService.storeValue('task.deadline_time', '06:00');
        await userDataService.storeValue('session.timeOfDay', SessionConstants.timeOfDayMorning);
        
        // Simulate new day transition
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue('task.current_date', yesterdayString);
        
        await sessionService.initializeSession();
        
        // Should handle both updates
        expect(await userDataService.getValue<String>('task.current_status'), 'pending'); // Fresh start
        
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>('task.previous_status'), 'failed'); // Grace period expired
        }
        
        // Should log the most recent update
        expect(await userDataService.getValue<String>('task.auto_update_reason'), isNotNull);
      });
    });
  });
}