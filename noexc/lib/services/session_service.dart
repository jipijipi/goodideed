import 'user_data_service.dart';
import '../constants/session_constants.dart';
import '../constants/storage_keys.dart';

class SessionService {
  final UserDataService userDataService;
  
  SessionService(this.userDataService);
  
  /// Initialize session data on app start
  Future<void> initializeSession() async {
    // Capture the original session date before any updates
    final originalLastVisitDate = await userDataService.getValue<String>(StorageKeys.sessionLastVisitDate);
    
    await _updateVisitCount();
    await _updateTotalVisitCount();
    await _updateTimeOfDay();
    await _updateDateInfo();
    await _updateTaskInfo(originalLastVisitDate);
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
  Future<void> _updateTaskInfo(String? originalLastVisitDate) async {
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Check if this is a new calendar day using the original session date
    final isNewDay = originalLastVisitDate != today;
    final lastTaskDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    
    if (isNewDay && lastTaskDate != null) {
      // Archive current day as previous day before updating
      await _archivePreviousDay(lastTaskDate);
      
      // Check if previous day grace period expired
      await _checkPreviousDayGracePeriod(now);
    }
    
    // Note: task.currentDate is now set by the script via template functions
    // No need for complex date management logic here
    
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
    
    // Compute scheduling-based task status
    await _computeTaskStatus(now);
    
    // Compute task end date based on current date + active days
    await _computeTaskEndDate(now);
    
    // Compute task due day (weekday integer of task.currentDate)
    await _computeTaskDueDay();
    
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
    
    // Compute isActiveDay inline to avoid race conditions with concurrent recalculations
    final isActiveDay = await _computeIsActiveDay(now);
    
    // Only check if task exists, is currently pending, AND today is an active day
    if (currentStatus == 'pending' && userTask != null && isActiveDay) {
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
    
    // Compute time range booleans
    final isBeforeStart = await _computeIsBeforeStart(now);
    await userDataService.storeValue(StorageKeys.taskIsBeforeStart, isBeforeStart);
    
    final isInTimeRange = await _computeIsInTimeRange(now);
    await userDataService.storeValue(StorageKeys.taskIsInTimeRange, isInTimeRange);
    
    final isPastDeadline = await _computeIsPastDeadline(now);
    await userDataService.storeValue(StorageKeys.taskIsPastDeadline, isPastDeadline);
    
    final isPastEndDate = await _computeIsPastEndDate(now);
    await userDataService.storeValue(StorageKeys.taskIsPastEndDate, isPastEndDate);
  }

  /// Compute scheduling-based task status (overdue/upcoming/pending)
  Future<void> _computeTaskStatus(DateTime now) async {
    final taskCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    
    // Default to pending if no task date is set or if date is invalid
    if (taskCurrentDate == null || taskCurrentDate.isEmpty) {
      await userDataService.storeValue(StorageKeys.taskStatus, 'pending');
      return;
    }
    
    // Validate and parse the task date
    try {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(taskCurrentDate)) {
        // Invalid date format, default to pending
        await userDataService.storeValue(StorageKeys.taskStatus, 'pending');
        return;
      }
      
      final taskDate = DateTime.parse(taskCurrentDate);
      final today = DateTime(now.year, now.month, now.day);
      final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
      
      String status;
      if (taskDateOnly.isBefore(today)) {
        status = 'overdue';
      } else if (taskDateOnly.isAfter(today)) {
        status = 'upcoming';
      } else {
        status = 'pending'; // taskDate equals today
      }
      
      await userDataService.storeValue(StorageKeys.taskStatus, status);
    } catch (e) {
      // Date parsing failed, default to pending and log warning
      await userDataService.storeValue(StorageKeys.taskStatus, 'pending');
      // Note: We could add logging here if needed, but keeping it simple for now
    }
  }

  /// Compute task end date as the next active day after task.currentDate
  Future<void> _computeTaskEndDate(DateTime now) async {
    final taskCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    
    // Default to empty if no task date is set
    if (taskCurrentDate == null || taskCurrentDate.isEmpty) {
      await userDataService.storeValue(StorageKeys.taskEndDate, '');
      return;
    }
    
    // Validate and parse the task date
    try {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(taskCurrentDate)) {
        // Invalid date format, default to empty
        await userDataService.storeValue(StorageKeys.taskEndDate, '');
        return;
      }
      
      final startDate = DateTime.parse(taskCurrentDate);
      final activeDays = await userDataService.getValue<List<dynamic>>('task.activeDays');
      
      // If no active days configured, default to next day
      if (activeDays == null || activeDays.isEmpty) {
        final endDate = startDate.add(const Duration(days: 1));
        await userDataService.storeValue(StorageKeys.taskEndDate, _formatDate(endDate));
        return;
      }
      
      // Find the next active day after task.currentDate (exclusive)
      for (int i = 1; i <= 365; i++) { // Max 1 year lookahead
        final testDate = startDate.add(Duration(days: i));
        final testWeekday = testDate.weekday;
        
        if (activeDays.contains(testWeekday)) {
          await userDataService.storeValue(StorageKeys.taskEndDate, _formatDate(testDate));
          return;
        }
      }
      
      // Fallback - should never reach here if activeDays is valid
      final fallbackEndDate = startDate.add(const Duration(days: 1));
      await userDataService.storeValue(StorageKeys.taskEndDate, _formatDate(fallbackEndDate));
    } catch (e) {
      // Date parsing failed, default to empty
      await userDataService.storeValue(StorageKeys.taskEndDate, '');
    }
  }

  /// Public method to recalculate isActiveDay (called by dataAction triggers)
  Future<void> recalculateActiveDay() async {
    final now = DateTime.now();
    final isActiveDay = await _computeIsActiveDay(now);
    await userDataService.storeValue(StorageKeys.taskIsActiveDay, isActiveDay);
  }

  /// Public method to recalculate isPastDeadline (called by dataAction triggers)
  Future<void> recalculatePastDeadline() async {
    final now = DateTime.now();
    final isPastDeadline = await _computeIsPastDeadline(now);
    await userDataService.storeValue(StorageKeys.taskIsPastDeadline, isPastDeadline);
  }

  /// Public method to recalculate task.endDate (called by dataAction triggers)
  Future<void> recalculateTaskEndDate() async {
    final now = DateTime.now();
    await _computeTaskEndDate(now);
    
    // Also recalculate isPastEndDate since it depends on endDate
    final isPastEndDate = await _computeIsPastEndDate(now);
    await userDataService.storeValue(StorageKeys.taskIsPastEndDate, isPastEndDate);
  }

  /// Public method to recalculate task.dueDay (called by dataAction triggers)
  Future<void> recalculateTaskDueDay() async {
    await _computeTaskDueDay();
  }

  /// Compute task due day as the weekday integer of task.currentDate
  Future<void> _computeTaskDueDay() async {
    final taskCurrentDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    
    // Default to 0 if no task date is set
    if (taskCurrentDate == null || taskCurrentDate.isEmpty) {
      await userDataService.storeValue(StorageKeys.taskDueDay, 0);
      return;
    }
    
    // Validate and parse the task date
    try {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(taskCurrentDate)) {
        // Invalid date format, default to 0
        await userDataService.storeValue(StorageKeys.taskDueDay, 0);
        return;
      }
      
      final taskDate = DateTime.parse(taskCurrentDate);
      // DateTime.weekday returns 1-7 (Monday=1, Sunday=7)
      await userDataService.storeValue(StorageKeys.taskDueDay, taskDate.weekday);
    } catch (e) {
      // Date parsing failed, default to 0
      await userDataService.storeValue(StorageKeys.taskDueDay, 0);
    }
  }

  // Note: _setTaskCurrentDate and _getNextActiveDay methods removed
  // These are now handled by script template functions in DataActionProcessor

  /// Check if today is an active day based on weekday configuration
  /// Returns true if today's weekday is in the user's activeDays configuration
  Future<bool> _computeIsActiveDay(DateTime now) async {
    // Get user's configured active days
    final activeDays = await userDataService.getValue<List<dynamic>>('task.activeDays');
    
    // If no activeDays configured, default to false
    if (activeDays == null || activeDays.isEmpty) {
      return false;
    }
    
    // Return true if today's weekday (1=Monday, 7=Sunday) is in the activeDays list
    return activeDays.contains(now.weekday);
  }

  /// Check if current time is before today's start time
  Future<bool> _computeIsBeforeStart(DateTime now) async {
    try {
      final startTimeString = await _getStartTimeAsString();
      final startParts = startTimeString.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      
      // Create today's start datetime
      final todayStart = DateTime(now.year, now.month, now.day, startHour, startMinute);
      
      // Return true if current time is before start time
      return now.isBefore(todayStart);
    } catch (e) {
      // If there's any error parsing start time, default to false (not before start)
      return false;
    }
  }

  /// Check if current time is within the start-deadline range
  Future<bool> _computeIsInTimeRange(DateTime now) async {
    try {
      final isBeforeStart = await _computeIsBeforeStart(now);
      final isPastDeadline = await _computeIsPastDeadline(now);
      
      // In range if not before start and not past deadline
      return !isBeforeStart && !isPastDeadline;
    } catch (e) {
      // If there's any error, default to true (assume in range)
      return true;
    }
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

  /// Check if current date is past the task's end date
  Future<bool> _computeIsPastEndDate(DateTime now) async {
    final taskEndDate = await userDataService.getValue<String>(StorageKeys.taskEndDate);
    
    // Default to false if no end date is set or if date is invalid
    if (taskEndDate == null || taskEndDate.isEmpty) {
      return false;
    }
    
    // Validate and parse the end date
    try {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(taskEndDate)) {
        // Invalid date format, default to false
        return false;
      }
      
      final endDate = DateTime.parse(taskEndDate);
      final today = DateTime(now.year, now.month, now.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      
      // Return true if end date is before today
      return endDateOnly.isBefore(today);
    } catch (e) {
      // Date parsing failed, default to false
      return false;
    }
  }

  /// Update task status based on contextual factors like time of day
  Future<void> _updateStatusBasedOnContext(DateTime now) async {
    // Note: Morning recovery logic removed - new days start as pending 
    // and are immediately checked against deadline, which is the correct behavior
    // No additional context-based updates needed at this time
  }

  /// Get start time as string with migration for existing deadline-only users
  Future<String> _getStartTimeAsString() async {
    // Try to get explicit start time first
    final startTime = await userDataService.getValue<String>(StorageKeys.taskStartTime);
    if (startTime != null) {
      return startTime;
    }
    
    // If no start time set, derive default from deadline time
    final deadlineTime = await _getDeadlineTimeAsString();
    return _getDefaultStartTimeForDeadline(deadlineTime);
  }

  /// Get deadline time as string, with migration from integer format
  Future<String> _getDeadlineTimeAsString() async {
    // Try to get as string first (new format)
    final stringValue = await userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
    if (stringValue != null) {
      // Check if it's a valid time format (HH:MM), otherwise it might be a converted integer
      if (stringValue.contains(':')) {
        return stringValue;
      } else {
        // It's a stringified integer, convert it
        final intValue = int.tryParse(stringValue);
        if (intValue != null) {
          final migratedTime = _convertIntegerToTimeString(intValue);
          await userDataService.storeValue(StorageKeys.taskDeadlineTime, migratedTime);
          return migratedTime;
        }
      }
    }
    
    // Try to get as integer (legacy format) and migrate
    final intValue = await userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
    if (intValue != null) {
      // Convert integer to time string and store the migrated value
      final migratedTime = _convertIntegerToTimeString(intValue);
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, migratedTime);
      return migratedTime;
    }
    
    // Default if no deadline found
    return SessionConstants.defaultDeadlineTime;
  }
  
  /// Convert legacy integer deadline to time string
  String _convertIntegerToTimeString(int intValue) {
    switch (intValue) {
      case SessionConstants.timeOfDayMorning: return SessionConstants.morningDeadlineTime;
      case SessionConstants.timeOfDayAfternoon: return SessionConstants.afternoonDeadlineTime;
      case SessionConstants.timeOfDayEvening: return SessionConstants.eveningDeadlineTime;
      case SessionConstants.timeOfDayNight: return SessionConstants.nightDeadlineTime;
      default: return SessionConstants.defaultDeadlineTime;
    }
  }
  
  /// Get default start time for a given deadline time
  String _getDefaultStartTimeForDeadline(String deadlineTime) {
    switch (deadlineTime) {
      case SessionConstants.morningDeadlineTime: return SessionConstants.morningStartTime;
      case SessionConstants.afternoonDeadlineTime: return SessionConstants.afternoonStartTime;
      case SessionConstants.eveningDeadlineTime: return SessionConstants.eveningStartTime;
      case SessionConstants.nightDeadlineTime: return SessionConstants.nightStartTime;
      default: return SessionConstants.defaultStartTime;
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