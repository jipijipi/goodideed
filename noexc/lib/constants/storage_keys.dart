/// Constants for storage keys used throughout the application
class StorageKeys {
  // Session tracking keys
  static const String sessionPrefix = 'session.';
  static const String sessionLastVisitDate = '${sessionPrefix}lastVisitDate';
  static const String sessionVisitCount = '${sessionPrefix}visitCount';
  static const String sessionTotalVisitCount = '${sessionPrefix}totalVisitCount';
  static const String sessionTimeOfDay = '${sessionPrefix}timeOfDay';
  static const String sessionFirstVisitDate = '${sessionPrefix}firstVisitDate';
  static const String sessionDaysSinceFirstVisit = '${sessionPrefix}daysSinceFirstVisit';
  static const String sessionIsWeekend = '${sessionPrefix}isWeekend';
  
  // Task configuration keys
  static const String taskPrefix = 'task.';
  static const String taskDeadlineTime = '${taskPrefix}deadline_time';
  static const String taskActiveDays = '${taskPrefix}active_days';
  
  // Private constructor to prevent instantiation
  StorageKeys._();
}