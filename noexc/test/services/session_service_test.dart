import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SessionService', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should initialize session with visit count', () async {
      await sessionService.initializeSession();
      
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      expect(visitCount, 1);
    });

    test('should increment daily visit count on multiple initializations same day', () async {
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      expect(visitCount, 2);
    });

    test('should always increment total visit count', () async {
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      
      final totalVisitCount = await userDataService.getValue<int>('session.totalVisitCount');
      expect(totalVisitCount, 2);
    });

    test('should reset daily visit count on new day', () async {
      // Simulate first day
      await sessionService.initializeSession();
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 2);
      
      // Manually set yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue('session.lastVisitDate', yesterdayString);
      
      // Initialize today (should reset daily count)
      await sessionService.initializeSession();
      final visitCount = await userDataService.getValue<int>('session.visitCount');
      final totalVisitCount = await userDataService.getValue<int>('session.totalVisitCount');
      
      expect(visitCount, 1); // Reset to 1 for new day
      expect(totalVisitCount, 3); // Total should continue incrementing
    });

    test('should set time of day correctly', () async {
      await sessionService.initializeSession();
      
      final timeOfDay = await userDataService.getValue<int>('session.timeOfDay');
      expect(timeOfDay, isNotNull);
      expect(timeOfDay, isA<int>());
      expect(timeOfDay! >= 1 && timeOfDay <= 4, true);
    });

    test('should set date information', () async {
      await sessionService.initializeSession();
      
      final lastVisitDate = await userDataService.getValue<String>('session.lastVisitDate');
      final firstVisitDate = await userDataService.getValue<String>('session.firstVisitDate');
      final daysSinceFirst = await userDataService.getValue<int>('session.daysSinceFirstVisit');
      final isWeekend = await userDataService.getValue<bool>('session.isWeekend');
      
      expect(lastVisitDate, isNotNull);
      expect(firstVisitDate, isNotNull);
      expect(daysSinceFirst, isA<int>());
      expect(isWeekend, isA<bool>());
    });
  });
}