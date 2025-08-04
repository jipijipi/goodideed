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

    test('should initialize task current date and status', () async {
      await sessionService.initializeSession();
      
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
      
      expect(currentDate, isNotNull);
      expect(currentStatus, 'pending');
      
      // Verify date format matches today
      final today = DateTime.now();
      final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(currentDate, expectedDate);
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

    test('should always update current date to today', () async {
      // Set an old date
      await userDataService.storeValue(StorageKeys.taskCurrentDate, '2024-01-01');
      
      await sessionService.initializeSession();
      
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      final today = DateTime.now();
      final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      expect(currentDate, expectedDate);
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
      // Set user to next_active timing
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]); // Mon-Fri
      
      // First session - should set future date
      await sessionService.initializeSession();
      final firstCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Second session same day - should preserve future date
      await sessionService.initializeSession();
      final secondCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Both should be the same future date, not today
      expect(firstCurrentDate, equals(secondCurrentDate));
      expect(firstCurrentDate, isNot(equals(_formatDate(DateTime.now()))));
    });

    test('should reset to today for today timing users', () async {
      // Set user to today timing
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'today');
      
      // Initialize session
      await sessionService.initializeSession();
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Should always be today for 'today' users  
      expect(currentDate, equals(_formatDate(DateTime.now())));
    });

    test('should use session date for isNewDay calculation, not task date', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Set up next_active user with future task date
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskCurrentDate, tomorrowString);
      await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
      
      // First session - should be treated as same day (no session date change)
      await sessionService.initializeSession();
      final currentDate1 = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Second session same day - should preserve future date
      await sessionService.initializeSession();
      final currentDate2 = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      
      // Task date should remain the same (not recalculated)
      expect(currentDate1, equals(currentDate2));
      expect(currentDate1, equals(tomorrowString));
    });

    test('should store next active weekday when calculating future dates', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      // Set user to next_active with only tomorrow as active day (forces future calculation)
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active'); 
      await userDataService.storeValue(StorageKeys.taskActiveDays, [tomorrow.weekday]); // Only tomorrow
      
      await sessionService.initializeSession();
      
      final nextActiveWeekday = await userDataService.getValue<int>(StorageKeys.taskNextActiveWeekday);
      
      // Should have stored tomorrow's weekday number
      expect(nextActiveWeekday, isNotNull);
      expect(nextActiveWeekday, equals(tomorrow.weekday));
    });

    test('should return false for isActiveDay when task scheduled for different date', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowString = _formatDate(tomorrow);
      
      // Set up next_active user properly - this will cause task to be scheduled for future date
      await userDataService.storeValue(StorageKeys.taskStartTiming, 'next_active');
      await userDataService.storeValue(StorageKeys.taskActiveDays, [tomorrow.weekday]); // Only tomorrow is active
      
      // Initialize session - this should set task date to tomorrow
      await sessionService.initializeSession();
      
      final currentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      // Task should be scheduled for tomorrow
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
  });
}