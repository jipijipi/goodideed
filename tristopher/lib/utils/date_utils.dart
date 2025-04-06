import 'package:intl/intl.dart';

/// Utility functions for date handling
class DateUtil {
  // Format date as "Month day, year" (e.g., "April 15, 2023")
  static String formatFullDate(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }
  
  // Format date as "Mon, Apr 15" (e.g., "Mon, Apr 15")
  static String formatShortDate(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }
  
  // Get date string for "today", "yesterday", or formatted date
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return formatShortDate(date);
    }
  }
  
  // Get day of week name (e.g., "Monday")
  static String getDayOfWeekName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
  
  // Get short day of week name (e.g., "Mon")
  static String getShortDayOfWeekName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
  
  // Format days of week as string (e.g., "Mon, Wed, Fri")
  static String formatDaysOfWeek(List<int> days) {
    if (days.isEmpty) return 'No days selected';
    if (days.length == 7) return 'Every day';
    
    final weekdays = [1, 2, 3, 4, 5];
    final weekend = [6, 7];
    
    if (days.length == 5 && weekdays.every((day) => days.contains(day))) {
      return 'Weekdays';
    }
    
    if (days.length == 2 && weekend.every((day) => days.contains(day))) {
      return 'Weekends';
    }
    
    // Sort days to ensure they appear in correct order
    final sortedDays = [...days]..sort();
    return sortedDays.map((day) => getShortDayOfWeekName(day)).join(', ');
  }
  
  // Check if today is one of the selected days of the week
  static bool isTodaySelectedDay(List<int>? days) {
    if (days == null || days.isEmpty) return false;
    
    final now = DateTime.now();
    // Convert from DateTime weekday (1=Monday, 7=Sunday) to match our format
    int todayWeekday = now.weekday;
    
    return days.contains(todayWeekday);
  }
}
