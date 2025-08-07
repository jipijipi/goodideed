import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Daily Reset Integration Test', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    test('should demonstrate daily visit count reset behavior', () async {
      // Day 1: First visit
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 1);
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 1);

      // Day 1: Second visit (same day)
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 2);
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 2);

      // Day 1: Third visit (same day)
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 3);
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 3);

      // Simulate Day 2: Set yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue('session.lastVisitDate', yesterdayString);

      // Day 2: First visit (new day - should reset daily count)
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 1); // Reset to 1
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 4); // Continues counting

      // Day 2: Second visit (same day)
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 2);
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 5);

      // Simulate Day 3: Set day before yesterday
      final dayBeforeYesterday = DateTime.now().subtract(const Duration(days: 2));
      final dayBeforeYesterdayString = '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}';
      await userDataService.storeValue('session.lastVisitDate', dayBeforeYesterdayString);

      // Day 3: First visit (new day - should reset daily count again)
      await sessionService.initializeSession();
      expect(await userDataService.getValue<int>('session.visitCount'), 1); // Reset to 1 again
      expect(await userDataService.getValue<int>('session.totalVisitCount'), 6); // Continues counting
    });

    test('should handle edge case of same day multiple times', () async {
      // Initialize multiple times on the same day
      for (int i = 1; i <= 5; i++) {
        await sessionService.initializeSession();
        expect(await userDataService.getValue<int>('session.visitCount'), i);
        expect(await userDataService.getValue<int>('session.totalVisitCount'), i);
      }
    });

    test('should correctly identify repeat daily visits for conditional routing', () async {
      // First visit of the day
      await sessionService.initializeSession();
      int dailyCount = await userDataService.getValue<int>('session.visitCount') ?? 0;
      expect(dailyCount, 1);

      // Second visit of the day (this would trigger "repeat daily visit" conditions)
      await sessionService.initializeSession();
      dailyCount = await userDataService.getValue<int>('session.visitCount') ?? 0;
      expect(dailyCount, 2);

      // This user would now match conditions like "session.visitCount > 1" for returning daily users
      expect(dailyCount > 1, true);
    });
  });
}
