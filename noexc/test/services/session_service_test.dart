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

    test('should return false for isActiveDay when today is not in activeDays', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Set active days to only include tomorrow's weekday (not today)
      await userDataService.storeValue(StorageKeys.taskActiveDays, [tomorrow.weekday]);
      await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString);
      
      // Initialize session
      await sessionService.initializeSession();
      
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      // isActiveDay should be false because today's weekday is not in activeDays
      expect(isActiveDay, equals(false));
    });

    test('should return true for isActiveDay when today is in activeDays', () async {
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      // Set today's weekday in active days (task date is irrelevant now)
      await userDataService.storeValue(StorageKeys.taskActiveDays, [today.weekday]);
      await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
      
      await sessionService.initializeSession();
      
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      // Should be true because today's weekday is in activeDays
      expect(isActiveDay, equals(true));
    });

    group('Active Day Pure Weekday Logic', () {
      test('should return false when no activeDays configured', () async {
        // Don't set any activeDays
        await sessionService.initializeSession();
        
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, false);
      });

      test('should return false when activeDays is empty array', () async {
        await userDataService.storeValue(StorageKeys.taskActiveDays, []);
        await sessionService.initializeSession();
        
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, false);
      });

      test('should return true for weekdays when activeDays includes weekdays', () async {
        // Set activeDays to weekdays (Monday=1 to Friday=5)
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final today = DateTime.now();
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should be true if today is a weekday, false if weekend
        final expectedResult = today.weekday >= 1 && today.weekday <= 5;
        expect(isActiveDay, expectedResult);
      });

      test('should return true for weekends when activeDays includes weekends', () async {
        // Set activeDays to weekends (Saturday=6, Sunday=7)
        await userDataService.storeValue(StorageKeys.taskActiveDays, [6, 7]);
        await sessionService.initializeSession();
        
        final today = DateTime.now();
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should be true if today is weekend, false if weekday
        final expectedResult = today.weekday == 6 || today.weekday == 7;
        expect(isActiveDay, expectedResult);
      });

      test('should ignore task.currentDate and only check weekday', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayString = _formatDate(yesterday);
        
        // Set task date to yesterday but activeDays to include today
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [today.weekday]);
        await sessionService.initializeSession();
        
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should be true because today's weekday is in activeDays, regardless of task date
        expect(isActiveDay, true);
      });

      test('should work with single weekday in activeDays', () async {
        final today = DateTime.now();
        
        // Set activeDays to only include today's weekday
        await userDataService.storeValue(StorageKeys.taskActiveDays, [today.weekday]);
        await sessionService.initializeSession();
        
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true);
      });

      test('should work with all weekdays in activeDays', () async {
        // Set activeDays to include all days of week
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        await sessionService.initializeSession();
        
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true); // Should always be true
      });
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

    group('Task End Date Computation', () {
      test('should compute task.endDate as next day when active days are everyday', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final saturday = DateTime(2024, 1, 6); // Saturday
        final fridayString = _formatDate(friday);
        final saturdayString = _formatDate(saturday);
        
        // Set task date to Friday with everyday active
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, saturdayString);
      });

      test('should compute task.endDate as next Monday when active days are weekdays and task is Friday', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final monday = DateTime(2024, 1, 8); // Next Monday
        final fridayString = _formatDate(friday);
        final mondayString = _formatDate(monday);
        
        // Set task date to Friday with weekdays only
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]); // Weekdays
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, mondayString);
      });

      test('should compute task.endDate as next Saturday when active days are weekends and task is Sunday', () async {
        final sunday = DateTime(2024, 1, 7); // Sunday
        final saturday = DateTime(2024, 1, 13); // Next Saturday
        final sundayString = _formatDate(sunday);
        final saturdayString = _formatDate(saturday);
        
        // Set task date to Sunday with weekends only
        await userDataService.storeValue(StorageKeys.taskCurrentDate, sundayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [6, 7]); // Weekends
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, saturdayString);
      });

      test('should compute task.endDate correctly with single active day', () async {
        final tuesday = DateTime(2024, 1, 2); // Tuesday
        final thursday = DateTime(2024, 1, 4); // Thursday
        final tuesdayString = _formatDate(tuesday);
        final thursdayString = _formatDate(thursday);
        
        // Set task date to Tuesday with only Thursday active
        await userDataService.storeValue(StorageKeys.taskCurrentDate, tuesdayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [4]); // Thursday only
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, thursdayString);
      });

      test('should default to empty string when no task.currentDate is set', () async {
        // Don't set any task date
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, '');
      });

      test('should default to empty string when task.currentDate is empty', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '');
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, '');
      });

      test('should default to empty string when task.currentDate has invalid format', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'invalid-date');
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, '');
      });

      test('should default to next day when no activeDays configured', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final saturday = DateTime(2024, 1, 6); // Saturday
        final fridayString = _formatDate(friday);
        final saturdayString = _formatDate(saturday);
        
        // Set task date but no active days
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, saturdayString);
      });

      test('should default to next day when activeDays is empty array', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final saturday = DateTime(2024, 1, 6); // Saturday
        final fridayString = _formatDate(friday);
        final saturdayString = _formatDate(saturday);
        
        // Set task date with empty active days
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, []);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, saturdayString);
      });

      test('should handle same weekday correctly (next week)', () async {
        final monday = DateTime(2024, 1, 1); // Monday
        final nextMonday = DateTime(2024, 1, 8); // Next Monday
        final mondayString = _formatDate(monday);
        final nextMondayString = _formatDate(nextMonday);
        
        // Set task date to Monday with only Monday active
        await userDataService.storeValue(StorageKeys.taskCurrentDate, mondayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1]); // Monday only
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, nextMondayString);
      });

      test('should handle cross-month boundary correctly', () async {
        final january31 = DateTime(2024, 1, 31); // Wednesday, January 31
        final february1 = DateTime(2024, 2, 1); // Thursday, February 1
        final jan31String = _formatDate(january31);
        final feb1String = _formatDate(february1);
        
        // Set task date to January 31 with Thursday active
        await userDataService.storeValue(StorageKeys.taskCurrentDate, jan31String);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [4]); // Thursday
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, feb1String);
      });

      test('should handle date parsing exceptions gracefully', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'completely-invalid-date'); // Invalid format
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(endDate, '');
      });

      test('should not interfere with other computations', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final fridayString = _formatDate(friday);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        // All computations should work independently
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        expect(endDate, isNotNull);
        expect(status, isNotNull);
        expect(isActiveDay, isNotNull);
      });

      test('should be recalculable via DataAction trigger', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final monday = DateTime(2024, 1, 8); // Monday
        final fridayString = _formatDate(friday);
        final mondayString = _formatDate(monday);
        
        // Initial setup - weekdays only
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        final initialEndDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        expect(initialEndDate, mondayString);
        
        // Change to everyday and recalculate
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        await sessionService.recalculateTaskEndDate();
        
        final newEndDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final saturdayString = _formatDate(DateTime(2024, 1, 6)); // Saturday
        expect(newEndDate, saturdayString);
      });

      test('should recalculate task.isPastEndDate when recalculateTaskEndDate is called', () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = _formatDate(yesterday);
        
        // Set task date to yesterday
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        await sessionService.initializeSession();
        
        // Initial state - endDate should be today, isPastEndDate should be false
        final initialEndDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final initialIsPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        expect(initialEndDate, _formatDate(DateTime.now()));
        expect(initialIsPastEndDate, false);
        
        // Manually set endDate to yesterday to simulate past end date
        await userDataService.storeValue(StorageKeys.taskEndDate, yesterdayString);
        
        // Recalculate - this should update both endDate and isPastEndDate
        await sessionService.recalculateTaskEndDate();
        
        // Verify both values were recalculated
        final newEndDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final newIsPastEndDate = await userDataService.getValue<bool>(StorageKeys.taskIsPastEndDate);
        
        expect(newEndDate, _formatDate(DateTime.now())); // Should be recalculated to today
        expect(newIsPastEndDate, false); // Should be false since endDate is now today
      });
    });

    group('Task Due Day Computation', () {
      test('should compute task.dueDay as weekday integer of task.currentDate', () async {
        final monday = DateTime(2024, 1, 1); // Monday = 1
        final mondayString = _formatDate(monday);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, mondayString);
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 1); // Monday
      });

      test('should compute task.dueDay correctly for different weekdays', () async {
        final testCases = [
          (DateTime(2024, 1, 1), 1), // Monday
          (DateTime(2024, 1, 2), 2), // Tuesday
          (DateTime(2024, 1, 3), 3), // Wednesday
          (DateTime(2024, 1, 4), 4), // Thursday
          (DateTime(2024, 1, 5), 5), // Friday
          (DateTime(2024, 1, 6), 6), // Saturday
          (DateTime(2024, 1, 7), 7), // Sunday
        ];

        for (final (date, expectedWeekday) in testCases) {
          await userDataService.clearAllData();
          await userDataService.storeValue(StorageKeys.taskCurrentDate, _formatDate(date));
          await sessionService.initializeSession();
          
          final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
          expect(dueDay, expectedWeekday, reason: 'Failed for ${date.toString()}');
        }
      });

      test('should default to 0 when no task.currentDate is set', () async {
        // Don't set any task date
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 0);
      });

      test('should default to 0 when task.currentDate is empty', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '');
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 0);
      });

      test('should default to 0 when task.currentDate has invalid format', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'invalid-date');
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 0);
      });

      test('should default to 0 when task.currentDate has partial format', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, '2024-12');
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 0);
      });

      test('should handle date parsing exceptions gracefully', () async {
        await userDataService.storeValue(StorageKeys.taskCurrentDate, 'completely-invalid-date');
        await sessionService.initializeSession();
        
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 0);
      });

      test('should compute correctly for dates in different months and years', () async {
        final testCases = [
          (DateTime(2024, 2, 5), 1), // Monday in February
          (DateTime(2023, 12, 31), 7), // Sunday in December 2023
          (DateTime(2025, 6, 15), 7), // Sunday in June 2025
          (DateTime(2024, 7, 4), 4), // Thursday (July 4th)
        ];

        for (final (date, expectedWeekday) in testCases) {
          await userDataService.clearAllData();
          await userDataService.storeValue(StorageKeys.taskCurrentDate, _formatDate(date));
          await sessionService.initializeSession();
          
          final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
          expect(dueDay, expectedWeekday, reason: 'Failed for ${date.toString()}');
        }
      });

      test('should not interfere with other computations', () async {
        final friday = DateTime(2024, 1, 5); // Friday
        final fridayString = _formatDate(friday);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, fridayString);
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        // All computations should work independently
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        expect(dueDay, 5); // Friday
        expect(endDate, isNotNull);
        expect(status, isNotNull);
        expect(isActiveDay, isNotNull);
      });

      test('should be computed at launch in correct order', () async {
        final wednesday = DateTime(2024, 1, 3); // Wednesday = 3
        final wednesdayString = _formatDate(wednesday);
        
        await userDataService.storeValue(StorageKeys.taskCurrentDate, wednesdayString);
        await sessionService.initializeSession();
        
        // Verify that task.dueDay is computed and available after initialization
        final dueDay = await userDataService.getValue<int>(StorageKeys.taskDueDay);
        expect(dueDay, 3); // Wednesday
        
        // Verify it's computed alongside other task calculations
        final endDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
        final status = await userDataService.getValue<String>(StorageKeys.taskStatus);
        
        expect(endDate, isNotNull); // Should be computed
        expect(status, isNotNull); // Should be computed
      });

      test('should recalculate task.status when recalculateTaskStatus is called', () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayString = _formatDate(yesterday);
        
        // Set task date to yesterday (should be overdue)
        await userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
        await sessionService.initializeSession();
        
        // Initial state should be overdue
        final initialStatus = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(initialStatus, 'overdue');
        
        // Change task date to today
        final todayString = _formatDate(DateTime.now());
        await userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
        
        // Recalculate status
        await sessionService.recalculateTaskStatus();
        
        // Status should now be pending
        final newStatus = await userDataService.getValue<String>(StorageKeys.taskStatus);
        expect(newStatus, 'pending');
      });
    });
  });
}
