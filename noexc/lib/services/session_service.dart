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
    
    // Set current date based on task start timing preference
    await _setTaskCurrentDate(today, isNewDay);
    
    if (isNewDay) {
      // Reset task status to pending for new day
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
    
    // Set default status if not exists
    final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    if (currentStatus == null) {
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
    
    // Compute derived task boolean values
    await _computeTaskBooleans(now);
    
    // Phase 1: Enhanced automatic status updates (run after status initialization)
    await _checkCurrentDayDeadline(now);
    await _updateStatusBasedOnContext(now);
  }

  /// Archive current day task as previous day
  Future<void> _archivePreviousDay(String lastTaskDate) async {
    final lastStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    final lastTask = await userDataService.getValue<String>(StorageKeys.userTask);
    
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
      // Get deadline time using helper that handles both int and string formats
      final deadlineTimeString = await _getDeadlineTimeAsString();
      final deadlineParts = deadlineTimeString.split(':');
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
    final userTask = await userDataService.getValue<String>(StorageKeys.userTask);
    
    // Only check if task exists and is currently pending
    if (currentStatus == 'pending' && userTask != null) {
      final deadlineTimeString = await _getDeadlineTimeAsString();
      final deadlineParts = deadlineTimeString.split(':');
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

  /// Compute derived task boolean values for easier conditional routing
  Future<void> _computeTaskBooleans(DateTime now) async {
    // Compute isActiveDay
    final isActiveDay = await _computeIsActiveDay(now);
    await userDataService.storeValue(StorageKeys.taskIsActiveDay, isActiveDay);
    
    // Compute isPastDeadline
    final isPastDeadline = await _computeIsPastDeadline(now);
    await userDataService.storeValue(StorageKeys.taskIsPastDeadline, isPastDeadline);
  }

  /// Public method to recalculate isActiveDay (called by dataAction triggers)
  Future<void> recalculateActiveDay() async {
    final now = DateTime.now();
    final isActiveDay = await _computeIsActiveDay(now);
    await userDataService.storeValue(StorageKeys.taskIsActiveDay, isActiveDay);
  }

  /// Set task current date based on start timing preference
  Future<void> _setTaskCurrentDate(String today, bool isNewDay) async {
    final startTiming = await userDataService.getValue<String>(StorageKeys.taskStartTiming);
    
    // If no timing preference set, default to today (existing behavior)
    if (startTiming == null) {
      await userDataService.storeValue(StorageKeys.taskCurrentDate, today);
      return;
    }
    
    // If user chose to start today, or it's not a new day, use today
    if (startTiming == 'today' || !isNewDay) {
      await userDataService.storeValue(StorageKeys.taskCurrentDate, today);
      return;
    }
    
    // If user chose to wait for next active day, calculate it
    if (startTiming == 'next_active') {
      final nextActiveDate = await _getNextActiveDay();
      await userDataService.storeValue(StorageKeys.taskCurrentDate, nextActiveDate);
      return;
    }
    
    // Default fallback
    await userDataService.storeValue(StorageKeys.taskCurrentDate, today);
  }

  /// Get the next active day based on user's active days configuration
  Future<String> _getNextActiveDay() async {
    final now = DateTime.now();
    final activeDays = await userDataService.getValue<List<dynamic>>(StorageKeys.taskActiveDays);
    
    // If no active days configured, default to tomorrow
    if (activeDays == null || activeDays.isEmpty) {
      final tomorrow = now.add(const Duration(days: 1));
      return _formatDate(tomorrow);
    }
    
    // Find the next day that matches an active day
    for (int i = 1; i <= 7; i++) {
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      
      if (activeDays.contains(testWeekday)) {
        return _formatDate(testDate);
      }
    }
    
    // Fallback - should never reach here if activeDays is valid
    final tomorrow = now.add(const Duration(days: 1));
    return _formatDate(tomorrow);
  }

  /// Check if today is an active day based on user's active_days configuration
  Future<bool> _computeIsActiveDay(DateTime now) async {
    final activeDays = await userDataService.getValue<List<dynamic>>(StorageKeys.taskActiveDays);
    
    if (activeDays == null || activeDays.isEmpty) {
      // If no active days configured, default to every day being active
      return true;
    }
    
    // Convert current day to weekday number (1=Monday, 7=Sunday)
    final currentWeekday = now.weekday;
    
    // Check if current weekday is in the active days list
    return activeDays.contains(currentWeekday);
  }

  /// Check if current time is past today's deadline
  Future<bool> _computeIsPastDeadline(DateTime now) async {
    try {
      final deadlineTimeString = await _getDeadlineTimeAsString();
      final deadlineParts = deadlineTimeString.split(':');
      final deadlineHour = int.parse(deadlineParts[0]);
      final deadlineMinute = int.parse(deadlineParts[1]);
      
      // Create today's deadline datetime
      final todayDeadline = DateTime(now.year, now.month, now.day, deadlineHour, deadlineMinute);
      
      // Return true if current time is after deadline
      return now.isAfter(todayDeadline);
    } catch (e) {
      // If there's any error parsing deadline, default to false (not past deadline)
      return false;
    }
  }

  /// Update task status based on contextual factors like time of day
  Future<void> _updateStatusBasedOnContext(DateTime now) async {
    // Note: Morning recovery logic removed - new days start as pending 
    // and are immediately checked against deadline, which is the correct behavior
    // No additional context-based updates needed at this time
  }

  /// Get deadline time as string, handling both integer and string storage formats
  Future<String> _getDeadlineTimeAsString() async {
    // Try to get as string first (new format)
    try {
      final stringValue = await userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
      if (stringValue != null) {
        return stringValue;
      }
    } catch (e) {
      // Type cast failed, value is probably an integer
    }
    
    // Try to get as integer (legacy format from JSON sequences)
    try {
      final intValue = await userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
      if (intValue != null) {
        // Convert integer to time string based on task config sequence format
        switch (intValue) {
          case 1: return '11:00'; // Morning (before noon)
          case 2: return '17:00'; // Afternoon (noon to 5pm) 
          case 3: return '21:00'; // Evening (5pm to 9pm)
          case 4: return '06:00'; // Night (9pm to 6am) - use 6am as reasonable night deadline
          default: return '21:00'; // Default to evening
        }
      }
    } catch (e) {
      // Type cast failed, value is probably a string or doesn't exist
    }
    
    // Default if neither format found
    return '21:00';
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