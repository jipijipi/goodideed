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
  static const String morningDeadlineTime = '10:00';     // End of morning period
  static const String afternoonDeadlineTime = '14:00';   // Mid afternoon  
  static const String eveningDeadlineTime = '18:00';     // Early evening
  static const String nightDeadlineTime = '23:00';       // Late night
  static const String defaultDeadlineTime = '23:00';     // Default deadline
  
  // Default start times (2 hours before deadline for reasonable range)
  static const String morningStartTime = '08:00';        // 2 hours before morning deadline
  static const String afternoonStartTime = '12:00';      // 2 hours before afternoon deadline
  static const String eveningStartTime = '16:00';        // 2 hours before evening deadline
  static const String nightStartTime = '21:00';          // 2 hours before night deadline
  static const String defaultStartTime = '21:00';        // Default start time
  
  // Date formatting
  static const int dateFormatPadWidth = 2;
  static const String dateFormatPadChar = '0';
  static const String dateFormatSeparator = '-';
  
  // Private constructor to prevent instantiation
  SessionConstants._();
}