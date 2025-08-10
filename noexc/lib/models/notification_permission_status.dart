/// Enum representing the current status of notification permissions
enum NotificationPermissionStatus {
  /// User has granted notification permissions
  granted,

  /// User has explicitly denied notification permissions
  denied,

  /// Permissions have not been requested yet
  notRequested,

  /// Permissions are restricted by system policy (e.g., parental controls)
  restricted,

  /// Unable to determine permission status
  unknown;

  /// Returns a user-friendly description of the permission status
  String get description {
    switch (this) {
      case NotificationPermissionStatus.granted:
        return 'Granted - notifications enabled';
      case NotificationPermissionStatus.denied:
        return 'Denied - go to Settings to enable';
      case NotificationPermissionStatus.notRequested:
        return 'Not requested - ready to ask user';
      case NotificationPermissionStatus.restricted:
        return 'Restricted - system policy prevents notifications';
      case NotificationPermissionStatus.unknown:
        return 'Unknown - unable to determine status';
    }
  }

  /// Returns true if notifications can be scheduled
  bool get canScheduleNotifications {
    return this == NotificationPermissionStatus.granted;
  }

  /// Returns true if we should show UI to request permissions
  bool get shouldRequestPermissions {
    return this == NotificationPermissionStatus.notRequested;
  }

  /// Returns true if user needs to manually enable in device Settings
  bool get needsManualSettings {
    return this == NotificationPermissionStatus.denied ||
        this == NotificationPermissionStatus.restricted;
  }

  /// Creates NotificationPermissionStatus from a boolean result
  /// Used for backward compatibility with existing permission APIs
  static NotificationPermissionStatus fromBoolean(
    bool? result,
    bool hasBeenRequested,
  ) {
    if (result == null) {
      return hasBeenRequested
          ? NotificationPermissionStatus.unknown
          : NotificationPermissionStatus.notRequested;
    }
    return result
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }
}
