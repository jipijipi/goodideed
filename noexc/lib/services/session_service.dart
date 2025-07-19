import 'user_data_service.dart';
import '../constants/session_constants.dart';
import '../constants/storage_keys.dart';

class SessionService {
  final UserDataService userDataService;
  
  SessionService(this.userDataService);
  
  /// Initialize session data on app start
  Future<void> initializeSession() async {
    await _updateVisitCount();
    await _updateTotalVisitCount();
    await _updateTimeOfDay();
    await _updateDateInfo();
    await _updateTaskInfo();
  }
  
  /// Update visit count (daily counter that resets each day)
  Future<void> _updateVisitCount() async {
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Check last visit date
    final lastVisitDate = await userDataService.getValue<String>(StorageKeys.sessionLastVisitDate);
    final isNewDay = lastVisitDate != today;
    
    if (isNewDay) {
      // Reset daily visit count for new day
      await userDataService.storeValue(StorageKeys.sessionVisitCount, 1);
    } else {
      // Increment daily visit count for same day
      final currentCount = await userDataService.getValue<int>(StorageKeys.sessionVisitCount) ?? 0;
      await userDataService.storeValue(StorageKeys.sessionVisitCount, currentCount + 1);
    }
  }
  
  /// Update total visit count (never resets)
  Future<void> _updateTotalVisitCount() async {
    final currentTotal = await userDataService.getValue<int>(StorageKeys.sessionTotalVisitCount) ?? 0;
    await userDataService.storeValue(StorageKeys.sessionTotalVisitCount, currentTotal + 1);
  }
  
  /// Update time of day (1=morning, 2=afternoon, 3=evening, 4=night)
  Future<void> _updateTimeOfDay() async {
    final now = DateTime.now();
    final hour = now.hour;
    
    int timeOfDay;
    if (hour >= SessionConstants.morningStartHour && hour < SessionConstants.afternoonStartHour) {
      timeOfDay = SessionConstants.timeOfDayMorning;
    } else if (hour >= SessionConstants.afternoonStartHour && hour < SessionConstants.eveningStartHour) {
      timeOfDay = SessionConstants.timeOfDayAfternoon;
    } else if (hour >= SessionConstants.eveningStartHour && hour < SessionConstants.nightStartHour) {
      timeOfDay = SessionConstants.timeOfDayEvening;
    } else {
      timeOfDay = SessionConstants.timeOfDayNight;
    }
    
    await userDataService.storeValue(StorageKeys.sessionTimeOfDay, timeOfDay);
  }
  
  /// Update date-related information
  Future<void> _updateDateInfo() async {
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Check if this is a new day
    final lastVisitDate = await userDataService.getValue<String>(StorageKeys.sessionLastVisitDate);
    final isNewDay = lastVisitDate != today;
    
    if (isNewDay) {
      await userDataService.storeValue(StorageKeys.sessionLastVisitDate, today);
    }
    
    // Set first visit date if not exists
    final firstVisitDate = await userDataService.getValue<String>(StorageKeys.sessionFirstVisitDate);
    if (firstVisitDate == null) {
      await userDataService.storeValue(StorageKeys.sessionFirstVisitDate, today);
    }
    
    // Calculate days since first visit
    final updatedFirstVisitDate = await userDataService.getValue<String>(StorageKeys.sessionFirstVisitDate);
    if (updatedFirstVisitDate != null) {
      final firstDate = DateTime.parse(updatedFirstVisitDate);
      final daysSinceFirst = now.difference(firstDate).inDays;
      await userDataService.storeValue(StorageKeys.sessionDaysSinceFirstVisit, daysSinceFirst);
    } else {
      await userDataService.storeValue(StorageKeys.sessionDaysSinceFirstVisit, 0);
    }
    
    // Set weekend flag
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    await userDataService.storeValue(StorageKeys.sessionIsWeekend, isWeekend);
  }

  /// Update daily task information
  Future<void> _updateTaskInfo() async {
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Check if this is a new day for tasks
    final lastTaskDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    final isNewDay = lastTaskDate != today;
    
    if (isNewDay && lastTaskDate != null) {
      // Archive current day as previous day before updating
      await _archivePreviousDay(lastTaskDate);
      
      // Check if previous day grace period expired
      await _checkPreviousDayGracePeriod(now);
    }
    
    // Always set current date to today
    await userDataService.storeValue(StorageKeys.taskCurrentDate, today);
    
    if (isNewDay) {
      // Reset task status to pending for new day
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
    
    // Set default status if not exists
    final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    if (currentStatus == null) {
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
    
    // Phase 1: Enhanced automatic status updates (run after status initialization)
    await _checkCurrentDayDeadline(now);
    await _updateStatusBasedOnContext(now);
  }

  /// Archive current day task as previous day
  Future<void> _archivePreviousDay(String lastTaskDate) async {
    final lastStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    final lastTask = await userDataService.getValue<String>('user.task');
    
    // Only archive if there was an actual task and it was pending
    if (lastTask != null && lastStatus == 'pending') {
      await userDataService.storeValue(StorageKeys.taskPreviousDate, lastTaskDate);
      await userDataService.storeValue(StorageKeys.taskPreviousStatus, 'pending');
      await userDataService.storeValue(StorageKeys.taskPreviousTask, lastTask);
    }
  }

  /// Check if previous day grace period has expired
  Future<void> _checkPreviousDayGracePeriod(DateTime now) async {
    final previousStatus = await userDataService.getValue<String>(StorageKeys.taskPreviousStatus);
    
    if (previousStatus == 'pending') {
      // Get deadline time (default 21:00 if not set)
      final deadlineTime = await userDataService.getValue<String>(StorageKeys.taskDeadlineTime) ?? '21:00';
      final deadlineParts = deadlineTime.split(':');
      final deadlineHour = int.parse(deadlineParts[0]);
      final deadlineMinute = int.parse(deadlineParts[1]);
      
      // Create today's deadline datetime
      final todayDeadline = DateTime(now.year, now.month, now.day, deadlineHour, deadlineMinute);
      
      if (now.isAfter(todayDeadline)) {
        // Grace period expired - mark previous day as failed
        await userDataService.storeValue(StorageKeys.taskPreviousStatus, 'failed');
        await _logStatusUpdate('previous_day', 'pending', 'failed', 'grace_period_expired');
      }
    }
  }

  /// Check if current day task is past deadline and update status
  Future<void> _checkCurrentDayDeadline(DateTime now) async {
    final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    final userTask = await userDataService.getValue<String>('user.task');
    
    // Only check if task exists and is currently pending
    if (currentStatus == 'pending' && userTask != null) {
      final deadlineTime = await userDataService.getValue<String>(StorageKeys.taskDeadlineTime) ?? '21:00';
      final deadlineParts = deadlineTime.split(':');
      final deadlineHour = int.parse(deadlineParts[0]);
      final deadlineMinute = int.parse(deadlineParts[1]);
      
      // Create today's deadline datetime
      final todayDeadline = DateTime(now.year, now.month, now.day, deadlineHour, deadlineMinute);
      
      if (now.isAfter(todayDeadline)) {
        // Past deadline - mark as overdue (allows recovery unlike "failed")
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'overdue');
        await _logStatusUpdate('current_day', 'pending', 'overdue', 'deadline_passed');
      }
    }
  }

  /// Update task status based on contextual factors like time of day
  Future<void> _updateStatusBasedOnContext(DateTime now) async {
    final timeOfDay = await userDataService.getValue<int>(StorageKeys.sessionTimeOfDay);
    final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    final userTask = await userDataService.getValue<String>('user.task');
    
    // Only update if task exists
    if (userTask != null && currentStatus != null) {
      // Morning fresh start: Reset overdue to pending
      if (timeOfDay == SessionConstants.timeOfDayMorning && currentStatus == 'overdue') {
        await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
        await _logStatusUpdate('current_day', 'overdue', 'pending', 'morning_fresh_start');
      }
    }
  }

  /// Log automatic status updates for transparency
  Future<void> _logStatusUpdate(String scope, String oldStatus, String newStatus, String reason) async {
    final now = DateTime.now();
    final timestamp = '${_formatDate(now)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    await userDataService.storeValue(StorageKeys.taskLastAutoUpdate, timestamp);
    await userDataService.storeValue(StorageKeys.taskAutoUpdateReason, '$scope: $oldStatus → $newStatus ($reason)');
  }
  
  /// Helper method to format date consistently
  String _formatDate(DateTime date) {
    return '${date.year}${SessionConstants.dateFormatSeparator}'
           '${date.month.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}${SessionConstants.dateFormatSeparator}'
           '${date.day.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}';
  }
}