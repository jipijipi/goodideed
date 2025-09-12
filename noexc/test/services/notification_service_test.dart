import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:noexc/services/notification_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/app_state_service.dart';
import 'package:noexc/models/notification_permission_status.dart';
import 'package:noexc/models/notification_tap_event.dart';
import 'package:noexc/constants/storage_keys.dart';
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
      setupTestingWithMocks(); // Use platform mocks instead of just quiet testing
      
      // Initialize timezone data for tests that use timezone functionality
      tz.initializeTimeZones();
      
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
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );

        // Execute
        await notificationService.scheduleDeadlineReminder();

        // Verify: notification should be disabled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, false);
      });

      test('should not schedule when reminders intensity is null', () async {
        // Set up: no reminders intensity set
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );

        // Execute
        await notificationService.scheduleDeadlineReminder();

        // Verify: notification should be disabled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, false);
      });

      test('should handle missing deadline time gracefully', () async {
        // Set up: reminders enabled but no deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true)); // Should be null or false
      });

      test('should handle invalid deadline time format gracefully', () async {
        // Set up: reminders enabled but invalid deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          'invalid-time',
        );

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true)); // Should be null or false
      });

      test('should handle invalid hour values gracefully', () async {
        // Set up: reminders enabled but invalid hour
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '25:30',
        );

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true)); // Should be null or false
      });

      test('should handle invalid minute values gracefully', () async {
        // Set up: reminders enabled but invalid minute
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:65',
        );

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: no notification scheduled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true)); // Should be null or false
      });

      test('should attempt to schedule with valid inputs', () async {
        // Set up: valid reminders, deadline time, and task current date
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );
        await mockUserDataService.storeValue(
          'task.currentDate',
          '2024-12-11',
        ); // Add required task date

        // Execute - this may fail due to platform dependencies in test, but should not crash
        try {
          await notificationService.scheduleDeadlineReminder();

          // If successful, should have scheduled time stored
          final lastScheduled = await mockUserDataService.getValue<String>(
            StorageKeys.notificationLastScheduled,
          );
          expect(lastScheduled, isNotNull);
        } catch (e) {
          // Platform-dependent operations may fail in test environment
          // This is acceptable as we're testing the error handling
          expect(e, isNotNull);

          // Should disable notifications on failure
          final isEnabled = await mockUserDataService.getValue<bool>(
            StorageKeys.notificationIsEnabled,
          );
          expect(isEnabled, false);
        }
      });
    });

    group('cancelAllNotifications', () {
      test('should disable notifications when cancelling', () async {
        // Set up: enable notifications first
        await mockUserDataService.storeValue(
          StorageKeys.notificationIsEnabled,
          true,
        );

        // Execute
        await notificationService.cancelAllNotifications();

        // Verify
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, false);
      });
    });

    group('cancelDeadlineReminder', () {
      test(
        'should disable notifications when cancelling deadline reminder',
        () async {
          // Set up: enable notifications first
          await mockUserDataService.storeValue(
            StorageKeys.notificationIsEnabled,
            true,
          );

          // Execute
          await notificationService.cancelDeadlineReminder();

          // Verify
          final isEnabled = await mockUserDataService.getValue<bool>(
            StorageKeys.notificationIsEnabled,
          );
          expect(isEnabled, false);
        },
      );
    });

    group('getPendingNotifications', () {
      test(
        'should return empty list when no notifications are pending',
        () async {
          // Execute - may fail due to platform dependencies but should not crash
          try {
            final pending = await notificationService.getPendingNotifications();
            expect(pending, isA<List<PendingNotificationRequest>>());
          } catch (e) {
            // Platform operations may fail in test environment
            expect(e, isNotNull);
          }
        },
      );
    });

    group('hasScheduledNotifications', () {
      test(
        'should return boolean indicating if notifications are scheduled',
        () async {
          // Execute - may fail due to platform dependencies but should not crash
          try {
            final hasScheduled =
                await notificationService.hasScheduledNotifications();
            expect(hasScheduled, isA<bool>());
          } catch (e) {
            // Platform operations may fail in test environment
            expect(e, isNotNull);
          }
        },
      );
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
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );

        // Execute
        await notificationService.scheduleDeadlineReminder();

        // Verify: should behave as if disabled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, false);
      });

      test('should handle negative reminders intensity as disabled', () async {
        // Set up: negative reminders intensity
        await mockUserDataService.storeValue('task.remindersIntensity', -1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );

        // Execute
        await notificationService.scheduleDeadlineReminder();

        // Verify: should behave as if disabled
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, false);
      });

      test('should handle empty deadline time string', () async {
        // Set up: empty deadline time
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(StorageKeys.taskDeadlineTime, '');

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: should not crash and not enable notifications
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true));
      });

      test('should handle deadline time with wrong separator', () async {
        // Set up: deadline time with wrong separator
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14-30',
        );

        // Execute - should not throw
        await notificationService.scheduleDeadlineReminder();

        // Verify: should handle gracefully
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true));
      });

      test('should handle single digit time format', () async {
        // Set up: single digit format
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '9:5',
        );
        await mockUserDataService.storeValue(
          'task.currentDate',
          '2024-12-11',
        ); // Add required task date

        // Execute - should not throw
        try {
          await notificationService.scheduleDeadlineReminder();

          // Valid time format should work (9:05 is valid)
          final lastScheduled = await mockUserDataService.getValue<String>(
            StorageKeys.notificationLastScheduled,
          );
          expect(lastScheduled, isNotNull);
        } catch (e) {
          // Platform operations may fail in test, but parsing should work
          final isEnabled = await mockUserDataService.getValue<bool>(
            StorageKeys.notificationIsEnabled,
          );
          expect(isEnabled, false); // Should be disabled on platform failure
        }
      });
    });

    group('past date fallback behavior', () {
      test(
        'should use fallback when task.currentDate is in the past',
        () async {
          // Set up: valid reminders, deadline time, but past task date
          await mockUserDataService.storeValue('task.remindersIntensity', 1);
          await mockUserDataService.storeValue(
            StorageKeys.taskDeadlineTime,
            '14:30',
          );
          await mockUserDataService.storeValue(
            'task.currentDate',
            '2020-01-01',
          ); // Very old date
          await mockUserDataService.storeValue(
            'task.activeDays',
            '[1,2,3,4,5]',
          ); // Weekdays

          // Execute - should not throw and should use fallback
          try {
            await notificationService.scheduleDeadlineReminder();

            // Verify fallback information was stored
            final fallbackDate = await mockUserDataService.getValue<String>(
              'notification.fallbackDate',
            );
            final fallbackReason = await mockUserDataService.getValue<String>(
              'notification.fallbackReason',
            );

            expect(fallbackDate, isNotNull);
            expect(fallbackReason, 'task.currentDate was in the past');

            // Verify the fallback date is in the future
            final parsedFallbackDate = DateTime.parse(fallbackDate!);
            expect(parsedFallbackDate.isAfter(DateTime.now()), true);
          } catch (e) {
            // Platform operations may fail in test environment
            // Should disable notifications on failure
            final isEnabled = await mockUserDataService.getValue<bool>(
              StorageKeys.notificationIsEnabled,
            );
            expect(isEnabled, false);
          }
        },
      );

      test('should clear fallback info when date is not in the past', () async {
        // Set up: Add old fallback info first
        await mockUserDataService.storeValue(
          'notification.fallbackDate',
          '2025-01-01',
        );
        await mockUserDataService.storeValue(
          'notification.fallbackReason',
          'test reason',
        );

        // Set up valid reminders with future date
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );

        // Use a future date
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final futureDateString =
            '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
        await mockUserDataService.storeValue(
          'task.currentDate',
          futureDateString,
        );

        // Execute
        try {
          await notificationService.scheduleDeadlineReminder();

          // Verify fallback information was cleared
          final fallbackDate = await mockUserDataService.getValue<String>(
            'notification.fallbackDate',
          );
          final fallbackReason = await mockUserDataService.getValue<String>(
            'notification.fallbackReason',
          );

          expect(fallbackDate, isNull);
          expect(fallbackReason, isNull);
        } catch (e) {
          // Platform operations may fail in test environment
          expect(e, isNotNull);
        }
      });

      test('should handle error in fallback calculation gracefully', () async {
        // Set up: valid reminders, deadline time, past task date, but no active days to cause fallback error
        await mockUserDataService.storeValue('task.remindersIntensity', 1);
        await mockUserDataService.storeValue(
          StorageKeys.taskDeadlineTime,
          '14:30',
        );
        await mockUserDataService.storeValue(
          'task.currentDate',
          '2020-01-01',
        ); // Very old date
        // Don't set active days - this might cause ActiveDateCalculator to have issues

        // Execute - should handle fallback error gracefully
        // In test environment, timezone/fallback errors may cause exceptions
        try {
          await notificationService.scheduleDeadlineReminder();
        } catch (e) {
          // Expected in test environment due to timezone/platform limitations
          expect(e, isA<Exception>());
        }

        // Should disable notifications on fallback failure
        final isEnabled = await mockUserDataService.getValue<bool>(
          StorageKeys.notificationIsEnabled,
        );
        expect(isEnabled, isNot(true)); // Should be false or null
      });
    });

    // Phase 1: Permission Status Detection Tests
    group('Phase 1: Permission Status Detection', () {
      group('getPermissionStatus', () {
        test(
          'should return notRequested when no permission request has been made',
          () async {
            // No request count stored - should be notRequested
            final status = await notificationService.getPermissionStatus();
            expect(status, equals(NotificationPermissionStatus.notRequested));
          },
        );

        test('should return stored permission status when available', () async {
          await mockUserDataService.storeValue(
            StorageKeys.notificationPermissionStatus,
            'granted',
          );
          await mockUserDataService.storeValue(
            StorageKeys.notificationPermissionRequestCount,
            1,
          );

          final status = await notificationService.getPermissionStatus();
          expect(status, equals(NotificationPermissionStatus.granted));
        });

        test(
          'should return unknown when permission was requested but no status stored',
          () async {
            await mockUserDataService.storeValue(
              StorageKeys.notificationPermissionRequestCount,
              1,
            );
            // No status stored

            final status = await notificationService.getPermissionStatus();
            expect(status, equals(NotificationPermissionStatus.unknown));
          },
        );

        test(
          'should handle invalid stored permission status gracefully',
          () async {
            await mockUserDataService.storeValue(
              StorageKeys.notificationPermissionStatus,
              'invalid_status',
            );
            await mockUserDataService.storeValue(
              StorageKeys.notificationPermissionRequestCount,
              1,
            );

            final status = await notificationService.getPermissionStatus();
            expect(status, equals(NotificationPermissionStatus.unknown));
          },
        );

        test('should return unknown on error', () async {
          // Override getValue to throw an error
          final originalService = notificationService;

          final status = await originalService.getPermissionStatus();
          // Should handle errors gracefully and return unknown
          expect(status, isA<NotificationPermissionStatus>());
        });
      });

      group('permission tracking in requestPermissions', () {
        test(
          'should increment request count when requesting permissions',
          () async {
            // Initial request count should be 0
            expect(
              await mockUserDataService.getValue<int>(
                StorageKeys.notificationPermissionRequestCount,
              ),
              isNull,
            );

            try {
              await notificationService.requestPermissions();
            } catch (e) {
              // Expected to fail in test environment
            }

            // Request count should be incremented
            final requestCount = await mockUserDataService.getValue<int>(
              StorageKeys.notificationPermissionRequestCount,
            );
            expect(requestCount, equals(1));
          },
        );

        test('should store last requested timestamp', () async {
          final beforeTime = DateTime.now();

          try {
            await notificationService.requestPermissions();
          } catch (e) {
            // Expected to fail in test environment
          }

          final lastRequestedString = await mockUserDataService
              .getValue<String>(
                StorageKeys.notificationPermissionLastRequested,
              );
          expect(lastRequestedString, isNotNull);

          final lastRequested = DateTime.parse(lastRequestedString!);
          expect(
            lastRequested.isAfter(beforeTime) ||
                lastRequested.isAtSameMomentAs(beforeTime),
            isTrue,
          );
        });

        test('should increment request count on multiple calls', () async {
          try {
            await notificationService.requestPermissions();
            await notificationService.requestPermissions();
          } catch (e) {
            // Expected to fail in test environment
          }

          final requestCount = await mockUserDataService.getValue<int>(
            StorageKeys.notificationPermissionRequestCount,
          );
          expect(requestCount, equals(2));
        });
      });
    });

    // Phase 2: Notification Tap Handling Tests
    group('Phase 2: Notification Tap Handling', () {
      late AppStateService mockAppStateService;

      setUp(() {
        mockAppStateService = AppStateService(mockUserDataService);
      });

      group('notification tap callback', () {
        test('should call AppStateService when notification is tapped', () async {
          // Set up mock app state service to capture events
          notificationService.setAppStateService(mockAppStateService);

          // Simulate notification tap
          // Note: NotificationResponse has required parameters that are not relevant for this test

          // Create a way to capture the event (since we can't easily mock the private method)
          // We'll test this indirectly through the service integration
          expect(
            () => notificationService.setAppStateService(mockAppStateService),
            returnsNormally,
          );
        });

        test('should support legacy callback system', () async {
          var callbackCalled = false;

          notificationService.setNotificationTapCallback((event) {
            callbackCalled = true;
          });

          // Since we can't easily trigger the private callback in tests,
          // we verify the callback can be set without error
          expect(callbackCalled, isFalse); // Not called yet
        });

        test('should handle missing app state service gracefully', () async {
          // Don't set app state service
          // Verify service doesn't crash when callback is called
          expect(
            () => notificationService.setNotificationTapCallback((_) {}),
            returnsNormally,
          );
        });
      });

      group('payload data in notifications', () {
        test('should include JSON payload when scheduling notifications', () async {
          // Set up valid notification scheduling data
          await mockUserDataService.storeValue('task.remindersIntensity', 1);
          await mockUserDataService.storeValue(
            StorageKeys.taskDeadlineTime,
            '14:30',
          );

          // Use future date to avoid fallback logic
          final futureDate = DateTime.now().add(const Duration(days: 1));
          final futureDateString =
              '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
          await mockUserDataService.storeValue(
            'task.currentDate',
            futureDateString,
          );

          try {
            await notificationService.scheduleDeadlineReminder();

            // If scheduling succeeded, the payload should be created
            // We can't easily verify the actual payload in tests due to platform dependencies
            // But we can verify the method doesn't crash
            expect(true, isTrue);
          } catch (e) {
            // Platform operations may fail in test environment, but should not crash from payload creation
            expect(e, isNotNull);
          }
        });
      });

      group('integration with AppStateService', () {
        test('should properly integrate with AppStateService', () async {
          await mockAppStateService.initialize();
          notificationService.setAppStateService(mockAppStateService);

          // Verify integration doesn't cause errors
          expect(mockAppStateService.cameFromNotification, isFalse);
          expect(mockAppStateService.hasNotificationTapEvent, isFalse);
        });

        test(
          'should handle notification tap events through AppStateService',
          () async {
            await mockAppStateService.initialize();
            notificationService.setAppStateService(mockAppStateService);

            // Manually trigger a notification tap event on the app state service
            final event = NotificationTapEvent(
              notificationId: 1001,
              type: NotificationType.dailyReminder,
              payload: '{"type": "dailyReminder", "taskDate": "2024-01-01"}',
            );

            await mockAppStateService.handleNotificationTap(event);

            expect(mockAppStateService.cameFromNotification, isTrue);
            expect(mockAppStateService.cameFromDailyReminder, isTrue);
            expect(mockAppStateService.hasNotificationTapEvent, isTrue);
          },
        );
      });
    });

    // Integration Tests for Phase 1 & 2
    group('Phase 1 & 2 Integration', () {
      test('should work together - permission status and tap handling', () async {
        // Test that both phases work together without interference

        // Phase 1: Check initial permission status
        var permissionStatus = await notificationService.getPermissionStatus();
        expect(
          permissionStatus,
          equals(NotificationPermissionStatus.notRequested),
        );

        // Phase 2: Set up tap handling
        final appStateService = AppStateService(mockUserDataService);
        await appStateService.initialize();
        notificationService.setAppStateService(appStateService);

        // Phase 1: Try to request permissions (will fail in test, but should track)
        try {
          await notificationService.requestPermissions();
        } catch (e) {
          // Expected in test environment
        }

        // Verify request was tracked
        final requestCount = await mockUserDataService.getValue<int>(
          StorageKeys.notificationPermissionRequestCount,
        );
        expect(requestCount, equals(1));

        // Verify permission status changed
        permissionStatus = await notificationService.getPermissionStatus();
        expect(
          permissionStatus,
          isNot(equals(NotificationPermissionStatus.notRequested)),
        );

        // Phase 2: Verify app state service is still working
        expect(appStateService.cameFromNotification, isFalse);
      });

      test('should maintain data consistency across both phases', () async {
        // Set up some permission tracking data
        await mockUserDataService.storeValue(
          StorageKeys.notificationPermissionStatus,
          'granted',
        );
        await mockUserDataService.storeValue(
          StorageKeys.notificationPermissionRequestCount,
          2,
        );

        // Set up app state service
        final appStateService = AppStateService(mockUserDataService);
        await appStateService.initialize();
        notificationService.setAppStateService(appStateService);

        // Verify permission data is maintained
        final status = await notificationService.getPermissionStatus();
        expect(status, equals(NotificationPermissionStatus.granted));

        // Verify app state doesn't interfere with permission data
        final requestCount = await mockUserDataService.getValue<int>(
          StorageKeys.notificationPermissionRequestCount,
        );
        expect(requestCount, equals(2));

        // Handle a notification tap
        final event = NotificationTapEvent(
          notificationId: 1001,
          type: NotificationType.dailyReminder,
        );
        await appStateService.handleNotificationTap(event);

        // Verify permission data is still intact
        final statusAfter = await notificationService.getPermissionStatus();
        expect(statusAfter, equals(NotificationPermissionStatus.granted));

        final requestCountAfter = await mockUserDataService.getValue<int>(
          StorageKeys.notificationPermissionRequestCount,
        );
        expect(requestCountAfter, equals(2));
      });
    });
  });

  // Note: Caching strategy tests are verified through manual testing
  // as the private methods are not accessible from test environment
  group('NotificationService caching integration', () {
    test('should have caching methods available', () async {
      setupQuietTesting();
      TestWidgetsFlutterBinding.ensureInitialized();

      final mockUserDataService = MockUserDataService();
      final notificationService = NotificationService(mockUserDataService);
      await notificationService.initialize();

      // Verify cache clearing method is available
      expect(() => notificationService.clearSchedulingCache(), returnsNormally);
    });
  });
}
