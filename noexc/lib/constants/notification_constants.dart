/// Configuration constants for notification system behavior
class NotificationConfig {
  /// Maximum number of notifications iOS allows to be scheduled simultaneously
  static const int maxIOSNotifications = 64;
  
  /// Maximum number of task days to schedule notifications for
  static const int maxTaskDays = 2;
  
  /// Minimum time window (hours) below which 4-hour reference pattern is used
  static const int minTimeWindowHours = 4;
  
  /// Default number of daily comeback notifications after task completion
  static const int defaultDailyComebackCount = 3;
  
  /// Default number of weekly comeback notifications after task completion  
  static const int defaultWeeklyComebackCount = 3;
  
  /// Primary notification ID for daily reminders
  static const int dailyReminderNotificationId = 1001;
  
  /// Android notification channel configuration
  static const String channelId = 'daily_reminders';
  static const String channelName = 'Daily Task Reminders';
  static const String channelDescription = 'Notifications to remind you about your daily task';
  
  /// Private constructor to prevent instantiation
  NotificationConfig._();
}