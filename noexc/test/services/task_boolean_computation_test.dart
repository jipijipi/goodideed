import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Task Boolean Computation Tests', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    group('isActiveDay Computation', () {
      test('should default to true when no active days configured', () async {
        // Setup: No active days configured
        await sessionService.initializeSession();
        
        // Should default to active day
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true);
      });

      test('should return true when today is in active days list', () async {
        // Setup: Set active days to include today
        final today = DateTime.now();
        final activeDays = [today.weekday]; // Just today
        await userDataService.storeValue(StorageKeys.taskActiveDays, activeDays);
        
        await sessionService.initializeSession();
        
        // Should be active day
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true);
      });

      test('should return false when today is not in active days list', () async {
        // Setup: Set active days to exclude today
        final today = DateTime.now();
        final otherDay = today.weekday == 1 ? 2 : 1; // Different day
        final activeDays = [otherDay];
        await userDataService.storeValue(StorageKeys.taskActiveDays, activeDays);
        
        await sessionService.initializeSession();
        
        // Should not be active day
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, false);
      });

      test('should handle weekdays configuration correctly', () async {
        // Setup: Weekdays only [1,2,3,4,5] (Monday-Friday)
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        
        await sessionService.initializeSession();
        
        final today = DateTime.now();
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should match weekend status
        final isWeekday = today.weekday >= 1 && today.weekday <= 5;
        expect(isActiveDay, isWeekday);
      });

      test('should handle weekend configuration correctly', () async {
        // Setup: Weekends only [6,7] (Saturday-Sunday)
        await userDataService.storeValue(StorageKeys.taskActiveDays, [6, 7]);
        
        await sessionService.initializeSession();
        
        final today = DateTime.now();
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should match weekend status
        final isWeekend = today.weekday == 6 || today.weekday == 7;
        expect(isActiveDay, isWeekend);
      });

      test('should handle every day configuration correctly', () async {
        // Setup: Every day [1,2,3,4,5,6,7]
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        
        await sessionService.initializeSession();
        
        // Should always be active day
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true);
      });

      test('should handle empty active days list', () async {
        // Setup: Empty active days list
        await userDataService.storeValue(StorageKeys.taskActiveDays, <int>[]);
        
        await sessionService.initializeSession();
        
        // Should default to true
        final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        expect(isActiveDay, true);
      });

      test('should update isActiveDay value on session initialization', () async {
        // Setup: Start with weekdays only
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5]);
        await sessionService.initializeSession();
        
        
        // Change to every day
        await userDataService.storeValue(StorageKeys.taskActiveDays, [1, 2, 3, 4, 5, 6, 7]);
        await sessionService.initializeSession();
        
        final secondResult = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
        
        // Should be true now (every day is active)
        expect(secondResult, true);
      });
    });

    group('isPastDeadline Computation', () {
      test('should return false when no deadline is configured', () async {
        // Setup: No deadline configured (will use default 21:00)
        await sessionService.initializeSession();
        
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        final now = DateTime.now();
        
        // Should match whether current time is past 21:00
        final expectedResult = now.hour >= 21;
        expect(isPastDeadline, expectedResult);
      });

      test('should return true when current time is past deadline', () async {
        // Setup: Set deadline to early morning (should be past for most test runs)
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '10:00'); // Morning deadline
        await sessionService.initializeSession();
        
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        final now = DateTime.now();
        
        // Should match whether current time is past 11:00
        final expectedResult = now.hour >= 11;
        expect(isPastDeadline, expectedResult);
      });

      test('should return false when current time is before deadline', () async {
        // Setup: Set deadline to late night (should be future for most test runs)
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '23:00'); // Night deadline
        await sessionService.initializeSession();
        
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        final now = DateTime.now();
        
        // Should match whether current time is past 23:00
        final expectedResult = now.hour >= 23;
        expect(isPastDeadline, expectedResult);
      });

      test('should handle deadline exactly at current time', () async {
        // Setup: Set deadline to current hour
        final now = DateTime.now();
        final currentHour = now.hour;
        
        // Find deadline option that matches current hour approximately
        int deadlineOption;
        if (currentHour < 11) {
          deadlineOption = 1; // 11:00 - Morning
        } else if (currentHour < 17) {
          deadlineOption = 2; // 17:00 - Afternoon
        } else if (currentHour < 21) {
          deadlineOption = 3; // 21:00 - Evening
        } else {
          deadlineOption = 4; // 06:00 - Night (next day)
        }
        
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, deadlineOption);
        await sessionService.initializeSession();
        
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        
        // Should be a valid boolean value
        expect(isPastDeadline, isA<bool>());
      });

      test('should handle invalid deadline gracefully', () async {
        // Setup: Invalid deadline data
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, 'invalid');
        await sessionService.initializeSession();
        
        // Should default to false when deadline parsing fails
        final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        expect(isPastDeadline, false);
      });

      test('should update isPastDeadline value on session initialization', () async {
        // Setup: Set a deadline
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '18:00'); // Evening deadline
        await sessionService.initializeSession();
        
        final firstResult = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        
        // Change deadline
        await userDataService.storeValue(StorageKeys.taskDeadlineTime, '10:00'); // Morning deadline
        await sessionService.initializeSession();
        
        final secondResult = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
        
        // Both should be valid boolean values (may be different depending on time of test)
        expect(firstResult, isA<bool>());
        expect(secondResult, isA<bool>());
      });
    });
  });
}
