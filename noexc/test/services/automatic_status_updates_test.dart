import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
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
        
        // Then set up task with early deadline on active day
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00'); // Early deadline
        
        // Set as active day so deadline check occurs
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, true);
        
        // Run session again to trigger deadline check
        await sessionService.initializeSession();
        
        // Should automatically mark as overdue (assuming test runs after 6 AM)
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'overdue');
          expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), contains('deadline_passed'));
        } else {
          expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'pending');
        }
      });

      test('should not update non-pending tasks', () async {
        // Setup: Initialize session first
        await sessionService.initializeSession();
        
        // Set up completed task past deadline
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'completed');
        await userDataService.storeValue('task.deadline_time', '06:00');
        
        // Run session again
        await sessionService.initializeSession();
        
        // Should remain completed regardless of deadline
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'completed');
      });

      test('should not update if no task exists', () async {
        // Setup: No task set
        await userDataService.storeValue('task.deadline_time', '06:00');
        await sessionService.initializeSession();
        
        // Should remain pending (default) and not trigger overdue
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'pending');
        expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), isNull);
      });

      test('should not mark as overdue when today is not an active day', () async {
        // Setup: Task scheduled for future date (not today)
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Future task');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00'); // Early deadline
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
        
        // Set task for future date (not today) - simulates "I'll do it next time" choice
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowString = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, false);
        
        // Run session again to trigger deadline check
        await sessionService.initializeSession();
        
        // Should remain pending because today is not an active day
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'pending');
        expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), isNull);
      });

      test('should mark as overdue only when active day and past deadline', () async {
        // Setup: Task scheduled for today (active day) with early deadline
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Today task');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00'); // Early deadline
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
        
        // Set task for today (active day)
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, true);
        
        // Run session again to trigger deadline check
        await sessionService.initializeSession();
        
        // Should mark as overdue if past 6 AM
        if (DateTime.now().hour >= 6) {
          expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'overdue');
          expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), contains('deadline_passed'));
        } else {
          expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'pending');
        }
      });
    });

    group('Status Preservation (No Morning Recovery)', () {
      test('should preserve overdue status during same day sessions', () async {
        // Setup: Task marked as overdue on active day
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'overdue');
        await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayMorning);
        
        // Set as active day so task status is preserved
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, true);
        
        await sessionService.initializeSession();
        
        // Should remain overdue (no morning recovery)
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'overdue');
      });

      test('should preserve overdue status regardless of time of day', () async {
        // Setup: Task marked as overdue in afternoon on active day
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Afternoon task');
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'overdue');
        await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayAfternoon);
        
        // Set as active day so task status is preserved
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, true);
        
        await sessionService.initializeSession();
        
        // Should remain overdue
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'overdue');
      });

      test('should preserve completed status during sessions', () async {
        // Setup: Completed task
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Completed task');
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'completed');
        await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayMorning);
        
        await sessionService.initializeSession();
        
        // Should remain completed
        expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'completed');
      });
    });

    group('Status Update Logging', () {
      test('should log automatic status updates with timestamp when deadline passes', () async {
        // Setup: Task with early deadline to trigger overdue status on active day
        await sessionService.initializeSession();
        await userDataService.storeValue(StorageKeys.userTask, 'Test task');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00'); // Early deadline
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
        
        // Set as active day so deadline check occurs
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await userDataService.storeValue(StorageKeys.taskIsActiveDay, true);
        
        await sessionService.initializeSession();
        
        final now = DateTime.now();
        if (now.hour >= 6) {
          // Should log the deadline-passed update
          final updateReason = await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason);
          final lastUpdate = await userDataService.getValue<String>(StorageKeys.taskLastAutoUpdate);
          
          expect(updateReason, isNotNull);
          expect(updateReason, contains('current_day: pending → overdue (deadline_passed)'));
          expect(lastUpdate, isNotNull);
          expect(lastUpdate, matches(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}')); // Date-time format
        }
      });

      test('should not log if no updates occur', () async {
        // Setup: Normal pending task with future deadline
        await userDataService.storeValue(StorageKeys.userTask, 'Future task');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '23:59');
        await sessionService.initializeSession();
        
        // Should not log anything
        expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), isNull);
        expect(await userDataService.getValue<String>(StorageKeys.taskLastAutoUpdate), isNull);
      });
    });

    group('Enhanced Grace Period Logging', () {
      test('should log previous day grace period expiration', () async {
        // Setup: Previous day task with expired grace period
        await userDataService.storeValue(StorageKeys.taskPreviousStatus, 'pending');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00'); // Early deadline
        
        // Simulate moving to new day
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        
        await sessionService.initializeSession();
        
        // Should log grace period expiration (if test runs after 6 AM)
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>(StorageKeys.taskPreviousStatus), 'failed');
          expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), contains('grace_period_expired'));
        }
      });
    });

    group('Integration Scenarios', () {
      test('should handle multiple status updates in one session', () async {
        // Setup: Complex scenario with both current and previous day updates
        await userDataService.storeValue(StorageKeys.userTask, 'Complex task');
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'overdue');
        await userDataService.storeValue(StorageKeys.taskPreviousStatus, 'pending');
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '06:00');
        await userDataService.storeValue(StorageKeys.sessionTimeOfDay, SessionConstants.timeOfDayMorning);
        
        // Simulate new day transition - set current date to yesterday to trigger new day logic
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        
        await sessionService.initializeSession();
        
        // After new day transition, task should be reset to pending and isActiveDay recalculated
        // The specific behavior depends on whether script sets today as active day
        final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
        expect(currentStatus, 'pending'); // New day starts as pending
        
        // Grace period should be checked for previous day
        final now = DateTime.now();
        if (now.hour >= 6) {
          expect(await userDataService.getValue<String>(StorageKeys.taskPreviousStatus), 'failed'); // Grace period expired
          // Should log the grace period expiration
          expect(await userDataService.getValue<String>(StorageKeys.taskAutoUpdateReason), contains('grace_period_expired'));
        }
      });
    });
  });
}