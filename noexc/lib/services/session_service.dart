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
    
    // Always set current date to today
    await userDataService.storeValue(StorageKeys.taskCurrentDate, today);
    
    if (isNewDay) {
      // Reset task status to pending for new day
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
    
    // Set default status if not exists
    final currentStatus = await userDataService.getValue<String>(StorageKeys.taskCurrentStatus);
    if (currentStatus == null) {
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
    }
  }
  
  /// Helper method to format date consistently
  String _formatDate(DateTime date) {
    return '${date.year}${SessionConstants.dateFormatSeparator}'
           '${date.month.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}${SessionConstants.dateFormatSeparator}'
           '${date.day.toString().padLeft(SessionConstants.dateFormatPadWidth, SessionConstants.dateFormatPadChar)}';
  }
}