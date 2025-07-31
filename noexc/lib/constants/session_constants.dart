/// Constants related to session tracking and time-based logic
class SessionConstants {
  // Time of day hour boundaries
  static const int morningStartHour = 5;
  static const int afternoonStartHour = 12;
  static const int eveningStartHour = 17;
  static const int nightStartHour = 21;
  
  // Time of day numeric values
  static const int timeOfDayMorning = 1;
  static const int timeOfDayAfternoon = 2;
  static const int timeOfDayEvening = 3;
  static const int timeOfDayNight = 4;
  
  // Deadline times aligned with time periods
  static const String morningDeadlineTime = '11:00';     // End of morning period
  static const String afternoonDeadlineTime = '17:00';   // Start of evening period  
  static const String eveningDeadlineTime = '21:00';     // Start of night period
  static const String nightDeadlineTime = '05:00';       // Start of morning period (next day)
  static const String defaultDeadlineTime = '21:00';     // Evening default
  
  // Date formatting
  static const int dateFormatPadWidth = 2;
  static const String dateFormatPadChar = '0';
  static const String dateFormatSeparator = '-';
  
  // Private constructor to prevent instantiation
  SessionConstants._();
}