/// Constants for storage keys used throughout the application
class StorageKeys {
  // Session tracking keys
  static const String sessionPrefix = 'session.';
  static const String sessionLastVisitDate = '${sessionPrefix}lastVisitDate';
  static const String sessionVisitCount = '${sessionPrefix}visitCount';
  static const String sessionTotalVisitCount =
      '${sessionPrefix}totalVisitCount';
  static const String sessionTimeOfDay = '${sessionPrefix}timeOfDay';
  static const String sessionFirstVisitDate = '${sessionPrefix}firstVisitDate';
  static const String sessionDaysSinceFirstVisit =
      '${sessionPrefix}daysSinceFirstVisit';
  static const String sessionIsWeekend = '${sessionPrefix}isWeekend';

  // User data keys
  static const String userPrefix = 'user.';
  static const String userName = '${userPrefix}name';
  static const String userTask = '${userPrefix}task';
  static const String userStreak = '${userPrefix}streak';
  static const String userIsOnboarded = '${userPrefix}isOnboarded';
  static const String userIsOnNotice = '${userPrefix}isOnNotice';

  // Task configuration keys
  static const String taskPrefix = 'task.';
  static const String taskStartTime = '${taskPrefix}startTime';
  static const String taskDeadlineTime = '${taskPrefix}deadlineTime';
  static const String taskActiveDays = '${taskPrefix}activeDays';
  static const String taskCurrentDate = '${taskPrefix}currentDate';
  static const String taskEndDate = '${taskPrefix}endDate';
  static const String taskDueDay = '${taskPrefix}dueDay';
  static const String taskCurrentStatus = '${taskPrefix}currentStatus';
  static const String taskStatus = '${taskPrefix}status';
  static const String taskPreviousDate = '${taskPrefix}previousDate';
  static const String taskPreviousStatus = '${taskPrefix}previousStatus';
  static const String taskPreviousTask = '${taskPrefix}previousTask';
  static const String taskLastAutoUpdate = '${taskPrefix}lastAutoUpdate';
  static const String taskAutoUpdateReason = '${taskPrefix}autoUpdateReason';
  static const String taskIsActiveDay = '${taskPrefix}isActiveDay';
  static const String taskIsBeforeStart = '${taskPrefix}isBeforeStart';
  static const String taskIsInTimeRange = '${taskPrefix}isInTimeRange';
  static const String taskIsPastDeadline = '${taskPrefix}isPastDeadline';
  static const String taskIsPastEndDate = '${taskPrefix}isPastEndDate';
  static const String taskStartTiming = '${taskPrefix}startTiming';
  static const String taskNextActiveWeekday = '${taskPrefix}nextActiveWeekday';

  // Notification keys
  static const String notificationPrefix = 'notification.';
  static const String notificationIsEnabled = '${notificationPrefix}isEnabled';
  static const String notificationLastScheduled =
      '${notificationPrefix}lastScheduled';
  static const String notificationScheduledFor =
      '${notificationPrefix}scheduledFor';

  // Permission tracking keys
  static const String notificationPermissionStatus =
      '${notificationPrefix}permissionStatus';
  static const String notificationPermissionRequestCount =
      '${notificationPrefix}requestCount';
  static const String notificationPermissionLastRequested =
      '${notificationPrefix}lastRequested';

  // Notification tap tracking keys (used by AppStateService)
  static const String notificationLastTapEvent =
      '${notificationPrefix}lastTapEvent';
  static const String notificationLastTapTime =
      '${notificationPrefix}lastTapTime';

  // Private constructor to prevent instantiation
  StorageKeys._();
}
