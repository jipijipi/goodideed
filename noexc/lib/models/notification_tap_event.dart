import 'dart:convert';

/// Event fired when a user taps on a notification
class NotificationTapEvent {
  /// The unique ID of the notification that was tapped
  final int notificationId;

  /// Optional payload data attached to the notification
  final String? payload;

  /// ID of the specific action that was tapped (for action button notifications)
  final String? actionId;

  /// Any input provided by the user (for input notifications)
  final String? input;

  /// When the notification was tapped
  final DateTime tapTime;

  /// The type of notification (parsed from payload if available)
  final NotificationType type;

  /// Additional data from the platform
  final Map<String, dynamic>? platformData;

  NotificationTapEvent({
    required this.notificationId,
    this.payload,
    this.actionId,
    this.input,
    DateTime? tapTime,
    NotificationType? type,
    this.platformData,
  }) : tapTime = tapTime ?? DateTime.now(),
       type = type ?? NotificationType.fromNotificationId(notificationId);

  /// Creates a NotificationTapEvent from a notification response
  factory NotificationTapEvent.fromResponse(
    int id,
    String? payload,
    String? actionId,
    String? input,
    Map<String, dynamic>? data,
  ) {
    NotificationType type = NotificationType.unknown;

    // Try to parse type from payload
    if (payload != null && payload.isNotEmpty) {
      try {
        final payloadData = json.decode(payload) as Map<String, dynamic>;
        final typeString = payloadData['type'] as String?;
        if (typeString != null) {
          type = NotificationType.fromString(typeString);
        }
      } catch (e) {
        // Payload is not JSON, leave type as unknown
      }
    }

    // Fallback to notification ID-based type detection
    if (type == NotificationType.unknown) {
      type = NotificationType.fromNotificationId(id);
    }

    return NotificationTapEvent(
      notificationId: id,
      payload: payload,
      actionId: actionId,
      input: input,
      type: type,
      platformData: data,
    );
  }

  /// Returns true if this was a daily reminder notification
  bool get isFromDailyReminder => type == NotificationType.dailyReminder;

  /// Returns true if this was an action button tap
  bool get isActionTap => actionId != null && actionId!.isNotEmpty;

  /// Returns true if user provided input
  bool get hasUserInput => input != null && input!.isNotEmpty;

  /// Parses the payload as JSON and returns the data
  Map<String, dynamic>? get payloadData {
    if (payload == null || payload!.isEmpty) return null;

    try {
      return json.decode(payload!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Gets a specific value from the payload data
  T? getPayloadValue<T>(String key) {
    final data = payloadData;
    if (data == null) return null;

    final value = data[key];
    return value is T ? value : null;
  }

  @override
  String toString() {
    return 'NotificationTapEvent(id: $notificationId, type: $type, actionId: $actionId, hasPayload: ${payload != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationTapEvent &&
        other.notificationId == notificationId &&
        other.payload == payload &&
        other.actionId == actionId &&
        other.input == input &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(notificationId, payload, actionId, input, type);
  }
}

/// Enum representing different types of notifications in the app
enum NotificationType {
  /// Daily task reminder notifications
  dailyReminder,

  /// Achievement or milestone notifications
  achievement,

  /// Warning or alert notifications
  warning,

  /// System or maintenance notifications
  system,

  /// Unknown or unrecognized notification type
  unknown;

  /// Creates NotificationType from string representation
  static NotificationType fromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'dailyreminder':
      case 'daily_reminder':
        return NotificationType.dailyReminder;
      case 'achievement':
        return NotificationType.achievement;
      case 'warning':
        return NotificationType.warning;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.unknown;
    }
  }

  /// Creates NotificationType from notification ID
  static NotificationType fromNotificationId(int id) {
    switch (id) {
      case 1001: // Daily reminder notification ID
        return NotificationType.dailyReminder;
      default:
        return NotificationType.unknown;
    }
  }

  /// Returns the string representation of this notification type
  String get value {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'dailyReminder';
      case NotificationType.achievement:
        return 'achievement';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.system:
        return 'system';
      case NotificationType.unknown:
        return 'unknown';
    }
  }
}
