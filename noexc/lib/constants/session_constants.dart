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
  
  // Date formatting
  static const int dateFormatPadWidth = 2;
  static const String dateFormatPadChar = '0';
  static const String dateFormatSeparator = '-';
  
  // Private constructor to prevent instantiation
  SessionConstants._();
}