import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

void main() {
  group('SessionService', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should initialize session with visit count', () async {
      await sessionService.initializeSession();
      
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      expect(visitCount, 1);
    });

    test('should increment daily visit count on multiple initializations same day', () async {
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      expect(visitCount, 2);
    });

    test('should always increment total visit count', () async {
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      
      final totalVisitCount = await userDataService.getValue<int>('session.totalVisitCount');
      expect(totalVisitCount, 2);
    });

    test('should reset daily visit count on new day', () async {
      // Simulate first day
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 2);
      
      // Manually set yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue('session.lastVisitDate', yesterdayString);
      
      // Initialize today (should reset daily count)
      await sessionService.initializeSession();
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      final totalVisitCount = await userDataService.getValue<int>('session.totalVisitCount');
      
      expect(visitCount, 1); // Reset to 1 for new day
      expect(totalVisitCount, 3); // Total should continue incrementing
    });

    test('should set time of day correctly', () async {
      await sessionService.initializeSession();
      
      final timeOfDay = await userDataService.getValue<int>('session.timeOfDay');
      expect(timeOfDay, isNotNull);
      expect(timeOfDay, isA<int>());
      expect(timeOfDay! >= 1 && timeOfDay <= 4, true);
    });

    test('should set date information', () async {
      await sessionService.initializeSession();
      
      final lastVisitDate = await userDataService.getValue<String>('session.lastVisitDate');
      final firstVisitDate = await userDataService.getValue<String>('session.firstVisitDate');
      final daysSinceFirst = await userDataService.getValue<int>('session.daysSinceFirstVisit');
      final isWeekend = await userDataService.getValue<bool>('session.isWeekend');
      
      expect(lastVisitDate, isNotNull);
      expect(firstVisitDate, isNotNull);
      expect(daysSinceFirst, isA<int>());
      expect(isWeekend, isA<bool>());
    });

    test('should initialize task status', () async {
      await sessionService.initializeSession();
      
      final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      
      // Should initialize task status (date is now set by script)
      expect(currentStatus, 'pending');
    });

    test('should reset task status to pending on new day', () async {
      // First day initialization
      await sessionService.initializeSession();
      
      // Manually change status to completed
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'completed');
      expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'completed');
      
      // Simulate new day by setting yesterday's session date (to trigger isNewDay = true)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue(StorageKeys.sessionLastVisitDate, yesterdayString);
      await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
      
      // Initialize today (should reset status)
      await sessionService.initializeSession();
      
      final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      expect(currentStatus, 'pending');
    });

    test('should preserve task status on same day', () async {
      // Initialize first time
      await sessionService.initializeSession();
      expect(await userDataService.getValue<String>(StorageKeys.taskCurrentStatus), 'pending');
      
      // Change status to completed
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'completed');
      
      // Initialize again same day
      await sessionService.initializeSession();
      
      // Status should remain completed
      final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      expect(currentStatus, 'completed');
    });

    test('should preserve current date set by script', () async {
      // Simulate script setting an old date (e.g., for next_active users)
      await userDataService.storeValue(StorageKeys.taskCurrentDate, '2024-01-01');
      
      await sessionService.initializeSession();
      
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Should preserve the date set by the script, not override it
      expect(currentDate, '2024-01-01');
    });

    test('should archive previous day task when moving to new day', () async {
      // Day 1: Set task and status
      await userDataService.storeValue(StorageKeys.userTask, 'Exercise for 30 minutes');
      await sessionService.initializeSession();
      // Status may be 'pending' or 'overdue' depending on current time vs deadline
      final initialStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      expect(['pending', 'overdue'].contains(initialStatus), true);
      
      // Simulate Day 2 by setting yesterday's session date (to trigger isNewDay = true)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue(StorageKeys.sessionLastVisitDate, yesterdayString);
      await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
      
      // Initialize today (should archive previous day)
      await sessionService.initializeSession();
      
      // Check if previous day was archived (only happens if initial status was pending)
      final previousDate = await userDataService.getValue<String>(StorageKeys.taskPreviousDate);
      final previousStatus = await userDataService.getValue<String>(StorageKeys.taskPreviousStatus);
      final previousTask = await userDataService.getValue<String>(StorageKeys.taskPreviousTask);
      
      if (initialStatus == 'pending') {
        // Should be archived if initial status was pending
        expect(previousDate, yesterdayString);
        expect(previousStatus, 'pending'); // Archived as pending, not overdue
        expect(previousTask, 'Exercise for 30 minutes');
      } else {
        // No archiving if initial status was already overdue
        expect(previousDate, isNull);
        expect(previousStatus, isNull);  
        expect(previousTask, isNull);
      }
      
      // Check current day was reset (should be pending for new day, but may be overdue due to automatic status updates)
      final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      expect(currentStatus, anyOf(equals('pending'), equals('overdue'))); // May be updated by automatic status system
    });

    test('should not archive if no task was set', () async {
      // Day 1: No task set
      await sessionService.initializeSession();
      
      // Simulate Day 2
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
      
      await sessionService.initializeSession();
      
      // Should not have archived anything
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousDate), isNull);
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousStatus), isNull);
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousTask), isNull);
    });

    test('should not archive if task was already completed', () async {
      // Day 1: Set task and mark as completed
      await userDataService.storeValue(StorageKeys.userTask, 'Read a book');
      await sessionService.initializeSession();
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'completed');
      
      // Simulate Day 2
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue(StorageKeys.sessionLastVisitDate, yesterdayString);
      await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
      
      await sessionService.initializeSession();
      
      // Should not have archived completed task
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousDate), isNull);
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousStatus), isNull);
      expect(await userDataService.getValue<String>(StorageKeys.taskPreviousTask), isNull);
    });

    test('should preserve future date for next_active users across same-day sessions', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Simulate script setting next_active timing with future date
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]); // Mon-Fri
      await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString); // Script sets future date
      
      // First session
      await sessionService.initializeSession();
      final firstCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Second session same day - should preserve the date set by script
      await sessionService.initializeSession();
      final secondCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Both should be the same future date (as set by script)
      expect(firstCurrentDate, equals(secondCurrentDate));
      expect(firstCurrentDate, equals(tomorrowString));
    });

    test('should reset to today for today timing users', () async {
      // Simulate script setting today timing (this would be done by dataAction in real scenario)
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'today');
      await userDataService.storeValue(StorageKeys.taskCurrentDate, _formatDate(DateTime.now()));
      
      // Initialize session
      await sessionService.initializeSession();
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Should be today (as set by the script)
      expect(currentDate, equals(_formatDate(DateTime.now())));
    });

    test('should use session date for isNewDay calculation, not task date', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Simulate script setting next_active user with future task date  
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString); // Script sets future date
      await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
      
      // First session
      await sessionService.initializeSession();
      final currentDate1 = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Second session same day - should preserve the script-set date
      await sessionService.initializeSession();
      final currentDate2 = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Task date should remain the same (as set by script)
      expect(currentDate1, equals(currentDate2));
      expect(currentDate1, equals(tomorrowString));
    });

    test('should store next active weekday when calculating future dates', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      // Simulate script setting next_active timing (this would be done by dataAction in real scenario)
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active'); 
      await userDataService.storeValue(StorageKeys.taskActiveDays, [tomorrow.weekday]); // Only tomorrow
      await userDataService.storeValue(StorageKeys.taskCurrentDate, _formatDate(tomorrow));
      await userDataService.storeValue(StorageKeys.taskNextActiveWeekday, tomorrow.weekday);
      
      await sessionService.initializeSession();
      
      final nextActiveWeekday = await userDataService.getValue<int>(StorageKeys.taskNextActiveWeekday);
      
      // Should have the weekday number set by the script
      expect(nextActiveWeekday, isNotNull);
      expect(nextActiveWeekday, equals(tomorrow.weekday));
    });

    test('should return false for isActiveDay when task scheduled for different date', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Simulate script setting next_active user with future date  
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskActiveDays, [tomorrow.weekday]); // Only tomorrow is active
      await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString); // Script sets future date
      
      // Initialize session
      await sessionService.initializeSession();
      
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      // Task should be scheduled for tomorrow (as set by script)
      expect(currentDate, equals(tomorrowString));
      // isActiveDay should be false because task is scheduled for tomorrow, not today
      expect(isActiveDay, equals(false));
    });

    test('should return true for isActiveDay when task scheduled for today and weekday matches', () async {
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      // Set task scheduled for today with today's weekday in active days
      await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
      await userDataService.storeValue(StorageKeys.taskActiveDays, [today.weekday]);
      
      await sessionService.initializeSession();
      
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      // Should be true because task is scheduled for today AND today's weekday is active
      expect(isActiveDay, equals(true));
    });

    group('Task Status Computation', () {
      test('should compute task status as pending when task date equals today', () async {
        final today = DateTime.now();
        final todayString = _formatDate(today);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should compute task status as overdue when task date is before today', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayString = _formatDate(yesterday);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'overdue');
      });

      test('should compute task status as upcoming when task date is after today', () async {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowString = _formatDate(tomorrow);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString);
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'upcoming');
      });

      test('should default to pending when task current date is null', () async {
        // Don't set any task date
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should default to pending when task current date is empty', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '');
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should default to pending when task current date has invalid format', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'invalid-date');
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should default to pending when task current date has partial format', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '2024-12');
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should handle date parsing exceptions gracefully', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'not-a-date-at-all'); // Completely invalid format
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'pending');
      });

      test('should compute status correctly for dates far in the past', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '2020-01-01');
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'overdue');
      });

      test('should compute status correctly for dates far in the future', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '2030-12-31');
        await sessionService.initializeSession();
        
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(status, 'upcoming');
      });

      test('should not interfere with existing task.currentStatus computation', () async {
        final today = DateTime.now();
        final yesterdayString = _formatDate(today.subtract(const Duration(days: 1)));
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await sessionService.initializeSession();
        
        // Both status fields should be set independently
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
        
        expect(status, 'overdue'); // scheduling status
        expect(currentStatus, 'pending'); // execution status (default)
      });
    });

    group('Task End Date Computation', () {
      test('should compute isPastEndDate as false when end date equals today', () async {
        final today = DateTime.now();
        final todayString = _formatDate(today);
        
        await userDataService.storeValue(StorageKeys.taskEndDate, todayString);
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should compute isPastEndDate as true when end date is before today', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayString = _formatDate(yesterday);
        
        await userDataService.storeValue(StorageKeys.taskEndDate, yesterdayString);
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, true);
      });

      test('should compute isPastEndDate as false when end date is after today', () async {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowString = _formatDate(tomorrow);
        
        await userDataService.storeValue(StorageKeys.taskEndDate, tomorrowString);
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should default to false when task end date is null', () async {
        // Don't set any end date
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should default to false when task end date is empty', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, '');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should default to false when task end date has invalid format', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, 'invalid-date');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should default to false when task end date has partial format', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, '2024-12');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should handle date parsing exceptions gracefully', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, 'completely-invalid-date');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should compute correctly for dates far in the past', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, '2020-01-01');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, true);
      });

      test('should compute correctly for dates far in the future', () async {
        await userDataService.storeValue(StorageKeys.taskEndDate, '2030-12-31');
        await sessionService.initializeSession();
        
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(isPastEndDate, false);
      });

      test('should not interfere with existing boolean computations', () async {
        final today = DateTime.now();
        final yesterdayString = _formatDate(today.subtract(const Duration(days: 1)));
        
        await userDataService.storeValue(StorageKeys.taskEndDate, yesterdayString);
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await sessionService.initializeSession();
        
        // All boolean fields should be computed independently
        final isPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        
        expect(isPastEndDate, true); // end date computation
        expect(isActiveDay, isNotNull); // other computations should still work
        expect(isPastDeadline, isNotNull);
      });
    });
  });
}