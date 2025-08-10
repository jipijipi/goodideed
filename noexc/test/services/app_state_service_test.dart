import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/app_state_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/models/notification_tap_event.dart';
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
  group('AppStateService', () {
    late MockUserDataService userDataService;
    late AppStateService appStateService;

    setUp(() {
      setupQuietTesting();
      userDataService = MockUserDataService();
      appStateService = AppStateService(userDataService);
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        expect(() => appStateService.initialize(), returnsNormally);
      });

      test('should start with empty state', () {
        expect(appStateService.cameFromNotification, isFalse);
        expect(appStateService.lastNotificationTapEvent, isNull);
        expect(appStateService.hasNotificationTapEvent, isFalse);
        expect(appStateService.cameFromDailyReminder, isFalse);
      });
    });

    group('notification tap handling', () {
      test('should handle notification tap event', () async {
        final event = NotificationTapEvent(
          notificationId: 1001,
          type: NotificationType.dailyReminder,
          payload: '{"type": "dailyReminder"}',
        );

        await appStateService.handleNotificationTap(event);

        expect(appStateService.cameFromNotification, isTrue);
        expect(appStateService.lastNotificationTapEvent, equals(event));
        expect(appStateService.hasNotificationTapEvent, isTrue);
        expect(appStateService.cameFromDailyReminder, isTrue);
      });

      test('should handle non-daily reminder notification', () async {
        final event = NotificationTapEvent(
          notificationId: 999,
          type: NotificationType.achievement,
          payload: '{"type": "achievement"}',
        );

        await appStateService.handleNotificationTap(event);

        expect(appStateService.cameFromNotification, isTrue);
        expect(appStateService.lastNotificationTapEvent, equals(event));
        expect(appStateService.hasNotificationTapEvent, isTrue);
        expect(appStateService.cameFromDailyReminder, isFalse);
      });

      test('should persist notification tap event', () async {
        final event = NotificationTapEvent(
          notificationId: 1001,
          payload: '{"type": "dailyReminder"}',
          actionId: 'open',
          input: 'user input',
        );

        await appStateService.handleNotificationTap(event);

        // Check that event is persisted (by checking we can get notification state)
        final state = await appStateService.getNotificationState();
        expect(state['cameFromNotification'], isTrue);
        expect(state['hasNotificationTapEvent'], isTrue);
        expect(state['cameFromDailyReminder'], isTrue);
      });
    });

    group('state clearing', () {
      test('should clear notification state', () async {
        // Set up initial state
        final event = NotificationTapEvent(
          notificationId: 1001,
          type: NotificationType.dailyReminder,
        );
        await appStateService.handleNotificationTap(event);

        expect(appStateService.cameFromNotification, isTrue);
        expect(appStateService.hasNotificationTapEvent, isTrue);

        // Clear state
        await appStateService.clearNotificationState();

        expect(appStateService.cameFromNotification, isFalse);
        expect(appStateService.lastNotificationTapEvent, isNull);
        expect(appStateService.hasNotificationTapEvent, isFalse);
        expect(appStateService.cameFromDailyReminder, isFalse);
      });

      test('should clear persisted state', () async {
        final event = NotificationTapEvent(notificationId: 1001);
        await appStateService.handleNotificationTap(event);

        // Verify state is persisted
        expect(await appStateService.hasPendingNotificationFromPreviousSession(), isFalse); // False because we're in same session

        await appStateService.clearNotificationState();

        // Verify persisted state is cleared
        expect(await appStateService.hasPendingNotificationFromPreviousSession(), isFalse);
      });
    });

    group('cross-session persistence', () {
      test('should detect pending notification from previous session', () async {
        // Simulate previous session by manually persisting data
        await userDataService.storeValue(
          'notification.lastTapEvent',
          '{"notificationId": 1001, "payload": null, "actionId": null, "input": null, "tapTime": "2024-01-01T12:00:00.000Z", "type": "dailyReminder", "platformData": null}',
        );

        // Create new service instance to simulate app restart
        final newAppStateService = AppStateService(userDataService);
        await newAppStateService.initialize();

        expect(await newAppStateService.hasPendingNotificationFromPreviousSession(), isTrue);
      });

      test('should consume pending notification', () async {
        // Set up persisted event
        await userDataService.storeValue(
          'notification.lastTapEvent',
          '{"notificationId": 1001, "payload": null, "actionId": null, "input": null, "tapTime": "2024-01-01T12:00:00.000Z", "type": "dailyReminder", "platformData": null}',
        );

        final newAppStateService = AppStateService(userDataService);
        await newAppStateService.initialize();

        final pendingEvent = await newAppStateService.consumePendingNotification();

        expect(pendingEvent, isNotNull);
        expect(pendingEvent!.notificationId, equals(1001));
        expect(pendingEvent.type, equals(NotificationType.dailyReminder));

        // Should set current session state
        expect(newAppStateService.cameFromNotification, isTrue);
        expect(newAppStateService.lastNotificationTapEvent, isNotNull);

        // Should clear persisted state after consumption
        expect(await newAppStateService.hasPendingNotificationFromPreviousSession(), isFalse);
      });

      test('should return null when no pending notification', () async {
        final pendingEvent = await appStateService.consumePendingNotification();
        expect(pendingEvent, isNull);
      });
    });

    group('notification state reporting', () {
      test('should return comprehensive notification state', () async {
        final event = NotificationTapEvent(
          notificationId: 1001,
          type: NotificationType.dailyReminder,
          payload: '{"type": "dailyReminder", "data": "test"}',
          actionId: 'open',
        );

        await appStateService.handleNotificationTap(event);

        final state = await appStateService.getNotificationState();

        expect(state['cameFromNotification'], isTrue);
        expect(state['hasNotificationTapEvent'], isTrue);
        expect(state['cameFromDailyReminder'], isTrue);
        expect(state['currentSessionEvent'], isNotNull);
        expect(state['timestamp'], isNotNull);
      });

      test('should handle error in state reporting', () async {
        // This test verifies error handling in getNotificationState
        final state = await appStateService.getNotificationState();

        expect(state, isA<Map<String, dynamic>>());
        expect(state['cameFromNotification'], isFalse);
        expect(state['hasNotificationTapEvent'], isFalse);
        expect(state['timestamp'], isNotNull);
      });
    });

    group('edge cases', () {
      test('should handle multiple notification taps', () async {
        final event1 = NotificationTapEvent(
          notificationId: 1001,
          type: NotificationType.dailyReminder,
        );
        final event2 = NotificationTapEvent(
          notificationId: 2002,
          type: NotificationType.achievement,
        );

        await appStateService.handleNotificationTap(event1);
        expect(appStateService.lastNotificationTapEvent, equals(event1));
        expect(appStateService.cameFromDailyReminder, isTrue);

        await appStateService.handleNotificationTap(event2);
        expect(appStateService.lastNotificationTapEvent, equals(event2));
        expect(appStateService.cameFromDailyReminder, isFalse);
      });

      test('should handle invalid persisted data gracefully', () async {
        // Store invalid JSON
        await userDataService.storeValue('notification.lastTapEvent', 'invalid json');

        final newAppStateService = AppStateService(userDataService);
        await newAppStateService.initialize();

        expect(await newAppStateService.hasPendingNotificationFromPreviousSession(), isFalse);
        expect(await newAppStateService.consumePendingNotification(), isNull);
      });

      test('should handle missing tapTime in persisted data', () async {
        // Store data without tapTime
        await userDataService.storeValue(
          'notification.lastTapEvent',
          '{"notificationId": 1001, "type": "dailyReminder"}',
        );

        final newAppStateService = AppStateService(userDataService);
        await newAppStateService.initialize();

        expect(await newAppStateService.hasPendingNotificationFromPreviousSession(), isFalse);
      });

      test('should handle empty or null state gracefully', () {
        expect(appStateService.cameFromNotification, isFalse);
        expect(appStateService.lastNotificationTapEvent, isNull);
        expect(appStateService.hasNotificationTapEvent, isFalse);
        expect(appStateService.cameFromDailyReminder, isFalse);
      });
    });
  });
}