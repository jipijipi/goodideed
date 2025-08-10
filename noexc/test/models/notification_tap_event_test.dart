import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/notification_tap_event.dart';

void main() {
  group('NotificationTapEvent', () {
    group('constructor', () {
      test('should create event with required parameters', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          payload: 'test payload',
        );

        expect(event.notificationId, equals(123));
        expect(event.payload, equals('test payload'));
        expect(event.actionId, isNull);
        expect(event.input, isNull);
        expect(event.tapTime, isA<DateTime>());
        expect(event.type, equals(NotificationType.unknown));
        expect(event.platformData, isNull);
      });

      test('should use provided tapTime and type', () {
        final customTime = DateTime(2024, 1, 1, 12, 0);
        final event = NotificationTapEvent(
          notificationId: 123,
          tapTime: customTime,
          type: NotificationType.dailyReminder,
        );

        expect(event.tapTime, equals(customTime));
        expect(event.type, equals(NotificationType.dailyReminder));
      });

      test('should determine type from notificationId when not provided', () {
        final event = NotificationTapEvent(notificationId: 1001);
        expect(event.type, equals(NotificationType.dailyReminder));
      });
    });

    group('fromResponse factory', () {
      test('should create event from basic response data', () {
        final event = NotificationTapEvent.fromResponse(
          456,
          'response payload',
          'action1',
          'user input',
          {'key': 'value'},
        );

        expect(event.notificationId, equals(456));
        expect(event.payload, equals('response payload'));
        expect(event.actionId, equals('action1'));
        expect(event.input, equals('user input'));
        expect(event.platformData, equals({'key': 'value'}));
        expect(event.tapTime, isA<DateTime>());
      });

      test('should parse type from JSON payload', () {
        final payloadData = {
          'type': 'dailyReminder',
          'scheduledDate': '2024-01-01T10:00:00.000Z',
        };
        final payload = json.encode(payloadData);

        final event = NotificationTapEvent.fromResponse(999, payload, null, null, null);

        expect(event.type, equals(NotificationType.dailyReminder));
        expect(event.payload, equals(payload));
      });

      test('should fallback to ID-based type detection when payload is invalid JSON', () {
        final event = NotificationTapEvent.fromResponse(1001, 'invalid json', null, null, null);

        expect(event.type, equals(NotificationType.dailyReminder));
      });

      test('should use unknown type when no type info available', () {
        final event = NotificationTapEvent.fromResponse(999, null, null, null, null);

        expect(event.type, equals(NotificationType.unknown));
      });

      test('should handle empty payload gracefully', () {
        final event = NotificationTapEvent.fromResponse(123, '', null, null, null);

        expect(event.type, equals(NotificationType.unknown));
        expect(event.payload, equals(''));
      });
    });

    group('convenience getters', () {
      test('isFromDailyReminder should return true for daily reminder type', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          type: NotificationType.dailyReminder,
        );

        expect(event.isFromDailyReminder, isTrue);
      });

      test('isFromDailyReminder should return false for other types', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          type: NotificationType.achievement,
        );

        expect(event.isFromDailyReminder, isFalse);
      });

      test('isActionTap should return true when actionId is present', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          actionId: 'dismiss',
        );

        expect(event.isActionTap, isTrue);
      });

      test('isActionTap should return false when actionId is null or empty', () {
        final event1 = NotificationTapEvent(notificationId: 123, actionId: null);
        final event2 = NotificationTapEvent(notificationId: 123, actionId: '');

        expect(event1.isActionTap, isFalse);
        expect(event2.isActionTap, isFalse);
      });

      test('hasUserInput should return true when input is present', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          input: 'user response',
        );

        expect(event.hasUserInput, isTrue);
      });

      test('hasUserInput should return false when input is null or empty', () {
        final event1 = NotificationTapEvent(notificationId: 123, input: null);
        final event2 = NotificationTapEvent(notificationId: 123, input: '');

        expect(event1.hasUserInput, isFalse);
        expect(event2.hasUserInput, isFalse);
      });
    });

    group('payload data parsing', () {
      test('payloadData should return null for null payload', () {
        final event = NotificationTapEvent(notificationId: 123, payload: null);
        expect(event.payloadData, isNull);
      });

      test('payloadData should return null for empty payload', () {
        final event = NotificationTapEvent(notificationId: 123, payload: '');
        expect(event.payloadData, isNull);
      });

      test('payloadData should return null for invalid JSON', () {
        final event = NotificationTapEvent(notificationId: 123, payload: 'invalid json');
        expect(event.payloadData, isNull);
      });

      test('payloadData should parse valid JSON', () {
        final data = {'key': 'value', 'number': 42};
        final payload = json.encode(data);
        final event = NotificationTapEvent(notificationId: 123, payload: payload);

        expect(event.payloadData, equals(data));
      });

      test('getPayloadValue should return typed values from payload', () {
        final data = {
          'stringValue': 'test',
          'intValue': 42,
          'boolValue': true,
        };
        final payload = json.encode(data);
        final event = NotificationTapEvent(notificationId: 123, payload: payload);

        expect(event.getPayloadValue<String>('stringValue'), equals('test'));
        expect(event.getPayloadValue<int>('intValue'), equals(42));
        expect(event.getPayloadValue<bool>('boolValue'), isTrue);
      });

      test('getPayloadValue should return null for missing keys', () {
        final event = NotificationTapEvent(notificationId: 123, payload: '{"key": "value"}');
        expect(event.getPayloadValue<String>('missingKey'), isNull);
      });

      test('getPayloadValue should return null for wrong type', () {
        final event = NotificationTapEvent(notificationId: 123, payload: '{"key": "value"}');
        expect(event.getPayloadValue<int>('key'), isNull);
      });

      test('getPayloadValue should return null when no payload data', () {
        final event = NotificationTapEvent(notificationId: 123, payload: null);
        expect(event.getPayloadValue<String>('key'), isNull);
      });
    });

    group('equality and toString', () {
      test('should be equal when all properties match', () {
        final event1 = NotificationTapEvent(
          notificationId: 123,
          payload: 'test',
          actionId: 'action1',
          input: 'input',
          type: NotificationType.dailyReminder,
        );

        final event2 = NotificationTapEvent(
          notificationId: 123,
          payload: 'test',
          actionId: 'action1',
          input: 'input',
          type: NotificationType.dailyReminder,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final event1 = NotificationTapEvent(notificationId: 123, payload: 'test1');
        final event2 = NotificationTapEvent(notificationId: 123, payload: 'test2');

        expect(event1, isNot(equals(event2)));
      });

      test('toString should include key information', () {
        final event = NotificationTapEvent(
          notificationId: 123,
          type: NotificationType.dailyReminder,
          actionId: 'dismiss',
          payload: 'test payload',
        );

        final result = event.toString();
        expect(result, contains('123'));
        expect(result, contains('dailyReminder'));
        expect(result, contains('dismiss'));
        expect(result, contains('true')); // hasPayload
      });
    });
  });

  group('NotificationType', () {
    group('fromString', () {
      test('should parse daily reminder variants correctly', () {
        expect(NotificationType.fromString('dailyReminder'), equals(NotificationType.dailyReminder));
        expect(NotificationType.fromString('daily_reminder'), equals(NotificationType.dailyReminder));
        expect(NotificationType.fromString('DAILYREMINDER'), equals(NotificationType.dailyReminder));
      });

      test('should parse other types correctly', () {
        expect(NotificationType.fromString('achievement'), equals(NotificationType.achievement));
        expect(NotificationType.fromString('warning'), equals(NotificationType.warning));
        expect(NotificationType.fromString('system'), equals(NotificationType.system));
      });

      test('should return unknown for unrecognized types', () {
        expect(NotificationType.fromString('invalid'), equals(NotificationType.unknown));
        expect(NotificationType.fromString(''), equals(NotificationType.unknown));
      });
    });

    group('fromNotificationId', () {
      test('should return dailyReminder for ID 1001', () {
        expect(NotificationType.fromNotificationId(1001), equals(NotificationType.dailyReminder));
      });

      test('should return unknown for other IDs', () {
        expect(NotificationType.fromNotificationId(999), equals(NotificationType.unknown));
        expect(NotificationType.fromNotificationId(0), equals(NotificationType.unknown));
        expect(NotificationType.fromNotificationId(-1), equals(NotificationType.unknown));
      });
    });

    group('value getter', () {
      test('should return correct string values', () {
        expect(NotificationType.dailyReminder.value, equals('dailyReminder'));
        expect(NotificationType.achievement.value, equals('achievement'));
        expect(NotificationType.warning.value, equals('warning'));
        expect(NotificationType.system.value, equals('system'));
        expect(NotificationType.unknown.value, equals('unknown'));
      });
    });
  });
}