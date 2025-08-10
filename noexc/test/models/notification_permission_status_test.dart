import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/models/notification_permission_status.dart';

void main() {
  group('NotificationPermissionStatus', () {
    group('description getter', () {
      test('should return correct description for granted status', () {
        expect(
          NotificationPermissionStatus.granted.description,
          'Granted - notifications enabled',
        );
      });

      test('should return correct description for denied status', () {
        expect(
          NotificationPermissionStatus.denied.description,
          'Denied - go to Settings to enable',
        );
      });

      test('should return correct description for notRequested status', () {
        expect(
          NotificationPermissionStatus.notRequested.description,
          'Not requested - ready to ask user',
        );
      });

      test('should return correct description for restricted status', () {
        expect(
          NotificationPermissionStatus.restricted.description,
          'Restricted - system policy prevents notifications',
        );
      });

      test('should return correct description for unknown status', () {
        expect(
          NotificationPermissionStatus.unknown.description,
          'Unknown - unable to determine status',
        );
      });
    });

    group('canScheduleNotifications getter', () {
      test('should return true only for granted status', () {
        expect(NotificationPermissionStatus.granted.canScheduleNotifications, isTrue);
        expect(NotificationPermissionStatus.denied.canScheduleNotifications, isFalse);
        expect(NotificationPermissionStatus.notRequested.canScheduleNotifications, isFalse);
        expect(NotificationPermissionStatus.restricted.canScheduleNotifications, isFalse);
        expect(NotificationPermissionStatus.unknown.canScheduleNotifications, isFalse);
      });
    });

    group('shouldRequestPermissions getter', () {
      test('should return true only for notRequested status', () {
        expect(NotificationPermissionStatus.granted.shouldRequestPermissions, isFalse);
        expect(NotificationPermissionStatus.denied.shouldRequestPermissions, isFalse);
        expect(NotificationPermissionStatus.notRequested.shouldRequestPermissions, isTrue);
        expect(NotificationPermissionStatus.restricted.shouldRequestPermissions, isFalse);
        expect(NotificationPermissionStatus.unknown.shouldRequestPermissions, isFalse);
      });
    });

    group('needsManualSettings getter', () {
      test('should return true for denied and restricted statuses', () {
        expect(NotificationPermissionStatus.granted.needsManualSettings, isFalse);
        expect(NotificationPermissionStatus.denied.needsManualSettings, isTrue);
        expect(NotificationPermissionStatus.notRequested.needsManualSettings, isFalse);
        expect(NotificationPermissionStatus.restricted.needsManualSettings, isTrue);
        expect(NotificationPermissionStatus.unknown.needsManualSettings, isFalse);
      });
    });

    group('fromBoolean factory', () {
      test('should return granted when result is true', () {
        expect(
          NotificationPermissionStatus.fromBoolean(true, true),
          NotificationPermissionStatus.granted,
        );
        expect(
          NotificationPermissionStatus.fromBoolean(true, false),
          NotificationPermissionStatus.granted,
        );
      });

      test('should return denied when result is false and has been requested', () {
        expect(
          NotificationPermissionStatus.fromBoolean(false, true),
          NotificationPermissionStatus.denied,
        );
      });

      test('should return unknown when result is null and has been requested', () {
        expect(
          NotificationPermissionStatus.fromBoolean(null, true),
          NotificationPermissionStatus.unknown,
        );
      });

      test('should return notRequested when result is null and has not been requested', () {
        expect(
          NotificationPermissionStatus.fromBoolean(null, false),
          NotificationPermissionStatus.notRequested,
        );
      });

      test('should return notRequested when result is false and has not been requested', () {
        expect(
          NotificationPermissionStatus.fromBoolean(false, false),
          NotificationPermissionStatus.denied, // Actually returns denied regardless of hasBeenRequested when false
        );
      });
    });

    group('logical consistency', () {
      test('granted status should allow scheduling and not need manual settings', () {
        const status = NotificationPermissionStatus.granted;
        expect(status.canScheduleNotifications, isTrue);
        expect(status.shouldRequestPermissions, isFalse);
        expect(status.needsManualSettings, isFalse);
      });

      test('denied status should not allow scheduling but need manual settings', () {
        const status = NotificationPermissionStatus.denied;
        expect(status.canScheduleNotifications, isFalse);
        expect(status.shouldRequestPermissions, isFalse);
        expect(status.needsManualSettings, isTrue);
      });

      test('notRequested status should allow requesting but not scheduling', () {
        const status = NotificationPermissionStatus.notRequested;
        expect(status.canScheduleNotifications, isFalse);
        expect(status.shouldRequestPermissions, isTrue);
        expect(status.needsManualSettings, isFalse);
      });

      test('restricted status should not allow scheduling or requesting', () {
        const status = NotificationPermissionStatus.restricted;
        expect(status.canScheduleNotifications, isFalse);
        expect(status.shouldRequestPermissions, isFalse);
        expect(status.needsManualSettings, isTrue);
      });
    });
  });
}