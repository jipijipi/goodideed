import 'user_data_service.dart';
import '../constants/session_constants.dart';
import '../constants/storage_keys.dart';
import 'service_locator.dart';

class SessionService {
  final UserDataService userDataService;

  SessionService(this.userDataService);

  /// Initialize session data on app start
  Future<void> initializeSession() async {
    // Capture the original session date before any updates
    final originalLastVisitDate = await userDataService.getValue<String>(
      StorageKeys.sessionLastVisitDate,
    );

    await _updateVisitCount();
    await _updateTotalVisitCount();
    await _updateTimeOfDay();
    await _updateDateInfo();
    await _updateTaskInfo(originalLastVisitDate);
    await _scheduleNotifications();
  }

  /// Update visit count (daily counter that resets each day)
  Future<void> _updateVisitCount() async {
    final now = DateTime.now();
    final today = _formatDate(now);

    // Check last visit date
    final lastVisitDate = await userDataService.getValue<String>(
      StorageKeys.sessionLastVisitDate,
    );
    final isNewDay = lastVisitDate != today;

    if (isNewDay) {
      // Reset daily visit count for new day
      await userDataService.storeValue(StorageKeys.sessionVisitCount, 1);
    } else {
      // Increment daily visit count for same day
      final currentCount =
          await userDataService.getValue<int>(StorageKeys.sessionVisitCount) ??
          0;
      await userDataService.storeValue(
        StorageKeys.sessionVisitCount,
        currentCount + 1,
      );
    }
  }

  /// Update total visit count (never resets)
  Future<void> _updateTotalVisitCount() async {
    final currentTotal =
        await userDataService.getValue<int>(
          StorageKeys.sessionTotalVisitCount,
        ) ??
        0;
    await userDataService.storeValue(
      StorageKeys.sessionTotalVisitCount,
      currentTotal + 1,
    );
  }

  /// Update time of day (1=morning, 2=afternoon, 3=evening, 4=night)
  Future<void> _updateTimeOfDay() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Store the actual current hour instead of abstract time-of-day constants
    // This makes session.timeOfDay compatible with timeDisplay formatter and more useful
    await userDataService.storeValue(StorageKeys.sessionTimeOfDay, hour);
  }

  /// Update date-related information
  Future<void> _updateDateInfo() async {
    final now = DateTime.now();
    final today = _formatDate(now);

    // Check if this is a new day
    final lastVisitDate = await userDataService.getValue<String>(
      StorageKeys.sessionLastVisitDate,
    );
    final isNewDay = lastVisitDate != today;

    if (isNewDay) {
      await userDataService.storeValue(StorageKeys.sessionLastVisitDate, today);
    }

    // Set first visit date if not exists
    final firstVisitDate = await userDataService.getValue<String>(
      StorageKeys.sessionFirstVisitDate,
    );
    if (firstVisitDate == null) {
      await userDataService.storeValue(
        StorageKeys.sessionFirstVisitDate,
        today,
      );
    }

    // Calculate days since first visit
    final updatedFirstVisitDate = await userDataService.getValue<String>(
      StorageKeys.sessionFirstVisitDate,
    );
    if (updatedFirstVisitDate != null) {
      final firstDate = DateTime.parse(updatedFirstVisitDate);
      final daysSinceFirst = now.difference(firstDate).inDays;
      await userDataService.storeValue(
        StorageKeys.sessionDaysSinceFirstVisit,
        daysSinceFirst,
      );
    } else {
      await userDataService.storeValue(
        StorageKeys.sessionDaysSinceFirstVisit,
        0,
      );
    }

    // Set weekend flag
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    await userDataService.storeValue(StorageKeys.sessionIsWeekend, isWeekend);
  }

  /// Update daily task information
  Future<void> _updateTaskInfo(String? originalLastVisitDate) async {
    final now = DateTime.now();
    final today = _formatDate(now);

    // Check if this is a new calendar day using the original session date
    final isNewDay = originalLastVisitDate != today;
    //final lastTaskDate = await userDataService.getValue<String>(StorageKeys.taskCurrentDate);

    // Note: Previous day archiving and grace period logic moved to script

    // Note: task.currentDate is now set by the script via template functions
    // No need for complex date management logic here

    if (isNewDay) {
      // Reset task status to pending for new day
      await userDataService.storeValue(
        StorageKeys.taskCurrentStatus,
        'pending',
      );
    }

    // Set default status if not exists
    final currentStatus = await userDataService.getValue<String>(
      StorageKeys.taskCurrentStatus,
    );
    if (currentStatus == null) {
      await userDataService.storeValue(
        StorageKeys.taskCurrentStatus,
        'pending',
      );
    }

    // Compute scheduling-based task status
    await _computeTaskStatus(now);

    // Compute task end date based on current date + active days
    await _computeTaskEndDate(now);

    // Compute task due day (weekday integer of task.currentDate)
    await _computeTaskDueDay();

    // Compute derived task boolean values (after endDate is calculated)
    await _computeTaskBooleans(now);
  }

  /// Compute derived task boolean values for easier conditional routing
  Future<void> _computeTaskBooleans(DateTime now) async {
    // Compute isActiveDay
    final isActiveDay = await _computeIsActiveDay(now);
    await userDataService.storeValue(StorageKeys.taskIsActiveDay, isActiveDay);

    // Compute time range booleans
    final isBeforeStart = await _computeIsBeforeStart(now);
    await userDataService.storeValue(
      StorageKeys.taskIsBeforeStart,
      isBeforeStart,
    );

    final isInTimeRange = await _computeIsInTimeRange(now);
    await userDataService.storeValue(
      StorageKeys.taskIsInTimeRange,
      isInTimeRange,
    );

    final isPastDeadline = await _computeIsPastDeadline(now);
    await userDataService.storeValue(
      StorageKeys.taskIsPastDeadline,
      isPastDeadline,
    );

    final isPastEndDate = await _computeIsPastEndDate(now);
    await userDataService.storeValue(
      StorageKeys.taskIsPastEndDate,
      isPastEndDate,
    );

    // Update weekly session actives derived from task.activeDays
    await _updateWeeklyActiveDays();
  }

  /// Compute scheduling-based task status (overdue/upcoming/pending)
  Future<void> _computeTaskStatus(DateTime now) async {
    final taskCurrentDate = await userDataService.getValue<String>(
      StorageKeys.taskCurrentDate,
    );

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
      final taskDateOnly = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
      );

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
    final taskCurrentDate = await userDataService.getValue<String>(
      StorageKeys.taskCurrentDate,
    );

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
      final activeDays = await userDataService.getValue<List<dynamic>>(
        'task.activeDays',
      );

      // If no active days configured, default to next day
      if (activeDays == null || activeDays.isEmpty) {
        final endDate = startDate.add(const Duration(days: 1));
        await userDataService.storeValue(
          StorageKeys.taskEndDate,
          _formatDate(endDate),
        );
        return;
      }

      // Find the next active day after task.currentDate (exclusive)
      for (int i = 1; i <= 365; i++) {
        // Max 1 year lookahead
        final testDate = startDate.add(Duration(days: i));
        final testWeekday = testDate.weekday;

        if (activeDays.contains(testWeekday)) {
          await userDataService.storeValue(
            StorageKeys.taskEndDate,
            _formatDate(testDate),
          );
          return;
        }
      }

      // Fallback - should never reach here if activeDays is valid
      final fallbackEndDate = startDate.add(const Duration(days: 1));
      await userDataService.storeValue(
        StorageKeys.taskEndDate,
        _formatDate(fallbackEndDate),
      );
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
    await _updateWeeklyActiveDays();
  }

  /// Public method to recalculate `session.<day>_active` flags from task.activeDays
  Future<void> recalculateWeeklyActiveDays() async {
    await _updateWeeklyActiveDays();
  }

  /// Map task.activeDays (DateTime.weekday: 1=Mon..7=Sun) to `session.<day>_active` = 0/1
  Future<void> _updateWeeklyActiveDays() async {
    final activeDays = await userDataService.getValue<List<dynamic>>(
      StorageKeys.taskActiveDays,
    );

    bool contains(int weekday) => activeDays != null && activeDays.contains(weekday);

    await userDataService.storeValue(StorageKeys.sessionMonActive, contains(DateTime.monday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionTueActive, contains(DateTime.tuesday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionWedActive, contains(DateTime.wednesday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionThuActive, contains(DateTime.thursday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionFriActive, contains(DateTime.friday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionSatActive, contains(DateTime.saturday) ? 1 : 0);
    await userDataService.storeValue(StorageKeys.sessionSunActive, contains(DateTime.sunday) ? 1 : 0);
  }

  /// Public method to recalculate isPastDeadline (called by dataAction triggers)
  Future<void> recalculatePastDeadline() async {
    final now = DateTime.now();
    final isPastDeadline = await _computeIsPastDeadline(now);
    await userDataService.storeValue(
      StorageKeys.taskIsPastDeadline,
      isPastDeadline,
    );
  }

  /// Public method to recalculate only the isPastEndDate flag without touching the endDate
  Future<void> recalculatePastEndDate() async {
    final now = DateTime.now();
    final isPastEndDate = await _computeIsPastEndDate(now);
    await userDataService.storeValue(
      StorageKeys.taskIsPastEndDate,
      isPastEndDate,
    );
  }

  /// Public method to recalculate task.endDate (called by dataAction triggers)
  Future<void> recalculateTaskEndDate() async {
    final now = DateTime.now();
    await _computeTaskEndDate(now);

    // Also recalculate isPastEndDate since it depends on endDate
    final isPastEndDate = await _computeIsPastEndDate(now);
    await userDataService.storeValue(
      StorageKeys.taskIsPastEndDate,
      isPastEndDate,
    );
  }

  /// Public method to recalculate task.dueDay (called by dataAction triggers)
  Future<void> recalculateTaskDueDay() async {
    await _computeTaskDueDay();
  }

  /// Public method to recalculate task.status (called by dataAction triggers)
  Future<void> recalculateTaskStatus() async {
    final now = DateTime.now();
    await _computeTaskStatus(now);
  }

  /// Public method to recalculate time-range variables (called by dataAction triggers)
  Future<void> recalculateTimeRange() async {
    final now = DateTime.now();
    
    // Recalculate task.isBeforeStart
    final isBeforeStart = await _computeIsBeforeStart(now);
    await userDataService.storeValue(StorageKeys.taskIsBeforeStart, isBeforeStart);
    
    // Recalculate task.isInTimeRange  
    final isInTimeRange = await _computeIsInTimeRange(now);
    await userDataService.storeValue(StorageKeys.taskIsInTimeRange, isInTimeRange);
  }

  /// Public method to recalculate session.timeOfDay (called by dataAction triggers)
  Future<void> recalculateTimeOfDay() async {
    await _updateTimeOfDay();
  }

  /// Compute task due day as the weekday integer of task.currentDate
  Future<void> _computeTaskDueDay() async {
    final taskCurrentDate = await userDataService.getValue<String>(
      StorageKeys.taskCurrentDate,
    );

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
      await userDataService.storeValue(
        StorageKeys.taskDueDay,
        taskDate.weekday,
      );
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
    final activeDays = await userDataService.getValue<List<dynamic>>(
      'task.activeDays',
    );

    // If no activeDays configured, default to true for backward compatibility
    if (activeDays == null || activeDays.isEmpty) {
      return true;
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
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );

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
      final todayDeadline = DateTime(
        now.year,
        now.month,
        now.day,
        deadlineHour,
        deadlineMinute,
      );

      // Return true if current time is after deadline
      return now.isAfter(todayDeadline);
    } catch (e) {
      // If there's any error parsing deadline, default to false (not past deadline)
      return false;
    }
  }

  /// Check if current date is past the task's end date
  Future<bool> _computeIsPastEndDate(DateTime now) async {
    final taskEndDate = await userDataService.getValue<String>(
      StorageKeys.taskEndDate,
    );

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

  /// Get start time as string
  /// If explicit start time is missing or invalid, fallback to default '08:00'
  Future<String> _getStartTimeAsString() async {
    final s = await userDataService.getValue<String>(
      StorageKeys.taskStartTime,
    );
    if (s != null) {
      if (s.contains(':')) return s;
      final asInt = int.tryParse(s);
      if (asInt != null) return _convertIntegerToTimeString(asInt);
    }
    final i = await userDataService.getValue<int>(StorageKeys.taskStartTime);
    if (i != null) return _convertIntegerToTimeString(i);
    return SessionConstants.defaultStartTime;
  }

  /// Get deadline time as string, with migration from integer format
  Future<String> _getDeadlineTimeAsString() async {
    // Try to get as string first (new format)
    final stringValue = await userDataService.getValue<String>(
      StorageKeys.taskDeadlineTime,
    );
    if (stringValue != null) {
      // Check if it's a valid time format (HH:MM), otherwise it might be a converted integer
      if (stringValue.contains(':')) {
        return stringValue;
      } else {
        // It's a stringified integer, convert it for display only
        final intValue = int.tryParse(stringValue);
        if (intValue != null) {
          return _convertIntegerToTimeString(intValue);
        }
      }
    }

    // Try to get as integer (legacy format) and migrate
    final intValue = await userDataService.getValue<int>(
      StorageKeys.taskDeadlineTime,
    );
    if (intValue != null) {
      // Convert integer to time string for display only
      return _convertIntegerToTimeString(intValue);
    }

    // Default if no deadline found
    return SessionConstants.defaultDeadlineTime;
  }

  /// Convert integer hour to time string (e.g., 14 -> "14:00")
  String _convertIntegerToTimeString(int hour) {
    // Handle special "end of day" case
    if (hour == 24) {
      return '23:59';
    }
    
    // Handle direct hour values (0-23)
    if (hour >= 0 && hour <= 23) {
      return '${hour.toString().padLeft(2, '0')}:00';
    }
    
    // Fallback to default for invalid values
    return SessionConstants.defaultDeadlineTime;
  }

  // No deadline-based default start time mapping anymore.

  /// Schedule notifications based on current user settings
  Future<void> _scheduleNotifications() async {
    try {
      // Only schedule if the service locator is initialized and has the notification service
      if (ServiceLocator.instance.isInitialized) {
        final notificationService = ServiceLocator.instance.notificationService;
        await notificationService.scheduleDeadlineReminder();
      }
    } catch (e) {
      // Log error but don't crash the session initialization
      // We can't use logger service here due to potential circular dependency
      // The notification service will log its own errors
    }
  }

  /// Check if the session is currently at an end state
  Future<bool> isAtEndState() async {
    return await userDataService.getValue<bool>(StorageKeys.sessionIsAtEndState) ?? false;
  }

  /// Set the end state flag
  Future<void> setEndState(bool isAtEnd) async {
    await userDataService.storeValue(StorageKeys.sessionIsAtEndState, isAtEnd);
  }

  /// Clear the end state flag (convenience method for setEndState(false))
  Future<void> clearEndState() async {
    await setEndState(false);
  }

  /// Helper method to format date consistently
  String _formatDate(DateTime date) {
    return '${date.year}${SessionConstants.dateFormatSeparator}'
        '${date.month.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}${SessionConstants.dateFormatSeparator}'
        '${date.day.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}';
  }
}
