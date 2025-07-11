import 'user_data_service.dart';

class SessionService {
  final UserDataService userDataService;
  
  SessionService(this.userDataService);
  
  /// Initialize session data on app start
  Future<void> initializeSession() async {
    await _updateVisitCount();
    await _updateTotalVisitCount();
    await _updateTimeOfDay();
    await _updateDateInfo();
  }
  
  /// Update visit count (daily counter that resets each day)
  Future<void> _updateVisitCount() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Check last visit date
    final lastVisitDate = await userDataService.getValue<String>('session.lastVisitDate');
    final isNewDay = lastVisitDate != today;
    
    if (isNewDay) {
      // Reset daily visit count for new day
      await userDataService.storeValue('session.visitCount', 1);
    } else {
      // Increment daily visit count for same day
      final currentCount = await userDataService.getValue<int>('session.visitCount') ?? 0;
      await userDataService.storeValue('session.visitCount', currentCount + 1);
    }
  }
  
  /// Update total visit count (never resets)
  Future<void> _updateTotalVisitCount() async {
    final currentTotal = await userDataService.getValue<int>('session.totalVisitCount') ?? 0;
    await userDataService.storeValue('session.totalVisitCount', currentTotal + 1);
  }
  
  /// Update time of day (1=morning, 2=afternoon, 3=evening, 4=night)
  Future<void> _updateTimeOfDay() async {
    final now = DateTime.now();
    final hour = now.hour;
    
    int timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 1; // morning
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 2; // afternoon
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 3; // evening
    } else {
      timeOfDay = 4; // night
    }
    
    await userDataService.storeValue('session.timeOfDay', timeOfDay);
  }
  
  /// Update date-related information
  Future<void> _updateDateInfo() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Check if this is a new day
    final lastVisitDate = await userDataService.getValue<String>('session.lastVisitDate');
    final isNewDay = lastVisitDate != today;
    
    if (isNewDay) {
      await userDataService.storeValue('session.lastVisitDate', today);
    }
    
    // Set first visit date if not exists
    final firstVisitDate = await userDataService.getValue<String>('session.firstVisitDate');
    if (firstVisitDate == null) {
      await userDataService.storeValue('session.firstVisitDate', today);
    }
    
    // Calculate days since first visit
    final updatedFirstVisitDate = await userDataService.getValue<String>('session.firstVisitDate');
    if (updatedFirstVisitDate != null) {
      final firstDate = DateTime.parse(updatedFirstVisitDate);
      final daysSinceFirst = now.difference(firstDate).inDays;
      await userDataService.storeValue('session.daysSinceFirstVisit', daysSinceFirst);
    } else {
      await userDataService.storeValue('session.daysSinceFirstVisit', 0);
    }
    
    // Set weekend flag
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    await userDataService.storeValue('session.isWeekend', isWeekend);
  }
}