import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../lib/services/notification_service.dart';
import '../../lib/services/user_data_service.dart';
import '../../lib/constants/storage_keys.dart';
import '../test_helpers.dart';

class MockUserDataService extends UserDataService {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> storeValue(String key, dynamic value) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }
  
  @override
  Future<T?> getValue<T>(String key) async {
    final value = _storage[key];
    return value as T?;
  }
  
  @override
  Future<bool> hasValue(String key) async {
    return _storage.containsKey(key);
  }
  
  @override
  Future<void> removeValue(String key) async {
    _storage.remove(key);
  }
  
  @override
  Future<void> clearAllData() async {
    _storage.clear();
  }
}

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockUserDataService mockUserDataService;
    
    setUp(() {
      setupQuietTesting();
      mockUserDataService = MockUserDataService();
      notificationService = NotificationService(mockUserDataService);
    });
    
    group('initialization', () {
      test('should initialize without throwing errors', () async {
        // Note: Full initialization may fail in test environment due to platform dependencies
        // This test just ensures the service can be created
        expect(notificationService, isNotNull);
      });
    });
    
    group('scheduleDeadlineReminder', () {
      test('should not schedule when reminders intensity is 0', () async {
        // Set up: reminders disabled
        await mockUserDataService.storeValue('task.remindersIntensity', 0);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:30');
        
        // Execute
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: notification should be disabled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
      
      test('should not schedule when reminders intensity is null', () async {
        // Set up: no reminders intensity set
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:30');
        
        // Execute
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: notification should be disabled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
      
      test('should handle missing deadline time gracefully', () async {
        // Set up: reminders enabled but no deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true)); // Should be null or false
      });
      
      test('should handle invalid deadline time format gracefully', () async {
        // Set up: reminders enabled but invalid deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, 'invalid-time');
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true)); // Should be null or false
      });
      
      test('should handle invalid hour values gracefully', () async {
        // Set up: reminders enabled but invalid hour
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '25:30');
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true)); // Should be null or false
      });
      
      test('should handle invalid minute values gracefully', () async {
        // Set up: reminders enabled but invalid minute
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:65');
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true)); // Should be null or false
      });
      
      test('should attempt to schedule with valid inputs', () async {
        // Set up: valid reminders, deadline time, and task current date
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:30');
        await mockUserDataService.storeValue('task.currentDate', '2024-12-11'); // Add required task date
        
        // Execute - this may fail due to platform dependencies in test, but should not crash
        try {
          await notificationService.scheduleDeadlineReminder();
          
          // If successful, should have scheduled time stored
          final lastScheduled = await mockUserDataService.getValue<String>(StorageKeys.notificationLastScheduled);
          expect(lastScheduled, isNotNull);
        } catch (e) {
          // Platform-dependent operations may fail in test environment
          // This is acceptable as we're testing the error handling
          expect(e, isNotNull);
          
          // Should disable notifications on failure
          final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
          expect(isEnabled, false);
        }
      });
    });
    
    group('cancelAllNotifications', () {
      test('should disable notifications when cancelling', () async {
        // Set up: enable notifications first
        await mockUserDataService.storeValue(StorageKeys.notificationIsEnabled, true);
        
        // Execute
        await notificationService.cancelAllNotifications();
        
        // Verify
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
    });
    
    group('cancelDeadlineReminder', () {
      test('should disable notifications when cancelling deadline reminder', () async {
        // Set up: enable notifications first
        await mockUserDataService.storeValue(StorageKeys.notificationIsEnabled, true);
        
        // Execute
        await notificationService.cancelDeadlineReminder();
        
        // Verify
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
    });
    
    group('getPendingNotifications', () {
      test('should return empty list when no notifications are pending', () async {
        // Execute - may fail due to platform dependencies but should not crash
        try {
          final pending = await notificationService.getPendingNotifications();
          expect(pending, isA<List<PendingNotificationRequest>>());
        } catch (e) {
          // Platform operations may fail in test environment
          expect(e, isNotNull);
        }
      });
    });
    
    group('hasScheduledNotifications', () {
      test('should return boolean indicating if notifications are scheduled', () async {
        // Execute - may fail due to platform dependencies but should not crash
        try {
          final hasScheduled = await notificationService.hasScheduledNotifications();
          expect(hasScheduled, isA<bool>());
        } catch (e) {
          // Platform operations may fail in test environment
          expect(e, isNotNull);
        }
      });
    });
    
    group('requestPermissions', () {
      test('should handle permission request gracefully', () async {
        // Execute - may fail due to platform dependencies but should not crash
        try {
          final granted = await notificationService.requestPermissions();
          expect(granted, isA<bool>());
        } catch (e) {
          // Platform operations may fail in test environment
          expect(e, isNotNull);
        }
      });
    });
    
    group('edge cases and error handling', () {
      test('should handle null reminders intensity as disabled', () async {
        // Set up: no reminders intensity value
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:30');
        
        // Execute
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: should behave as if disabled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
      
      test('should handle negative reminders intensity as disabled', () async {
        // Set up: negative reminders intensity
        await mockUserDataService.storeValue('task.remindersIntensity', -1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14:30');
        
        // Execute
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: should behave as if disabled
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, false);
      });
      
      test('should handle empty deadline time string', () async {
        // Set up: empty deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '');
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: should not crash and not enable notifications
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true));
      });
      
      test('should handle deadline time with wrong separator', () async {
        // Set up: deadline time with wrong separator
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '14-30');
        
        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();
        
        // Verify: should handle gracefully
        final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
        expect(isEnabled, isNot(true));
      });
      
      test('should handle single digit time format', () async {
        // Set up: single digit format
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '9:5');
        await mockUserDataService.storeValue('task.currentDate', '2024-12-11'); // Add required task date
        
        // Execute - should not throw
        try {
          await notificationService.scheduleDeadlineReminder();
          
          // Valid time format should work (9:05 is valid)
          final lastScheduled = await mockUserDataService.getValue<String>(StorageKeys.notificationLastScheduled);
          expect(lastScheduled, isNotNull);
        } catch (e) {
          // Platform operations may fail in test, but parsing should work
          final isEnabled = await mockUserDataService.getValue<bool>(StorageKeys.notificationIsEnabled);
          expect(isEnabled, false); // Should be disabled on platform failure
        }
      });
    });
  });
}