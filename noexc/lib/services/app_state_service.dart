import '../models/notification_tap_event.dart';
import 'user_data_service.dart';
import 'logger_service.dart';
import '../constants/storage_keys.dart';
import 'dart:convert';

/// Service for tracking application state related to notification interactions
class AppStateService {
  final UserDataService _userDataService;
  final LoggerService _logger = LoggerService.instance;

  // In-memory state for current session
  NotificationTapEvent? _lastNotificationTapEvent;
  bool _cameFromNotification = false;

  AppStateService(this._userDataService);

  /// Initialize the service - call on app startup
  Future<void> initialize() async {
    _logger.info('Initializing AppStateService');

    try {
      // Load any persisted notification state from previous session
      await _loadPersistedState();
      _logger.info('AppStateService initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize AppStateService: $e');
    }
  }

  /// Handle a notification tap event
  Future<void> handleNotificationTap(NotificationTapEvent event) async {
    _logger.info('Handling notification tap event: $event');

    try {
      // Update in-memory state
      _lastNotificationTapEvent = event;
      _cameFromNotification = true;

      // Persist the event for cross-session tracking
      await _persistNotificationTap(event);

      _logger.info('Notification tap event processed successfully');
    } catch (e) {
      _logger.error('Failed to handle notification tap: $e');
    }
  }

  /// Returns true if the user came from a notification tap in this session
  bool get cameFromNotification => _cameFromNotification;

  /// Returns the last notification tap event from this session
  NotificationTapEvent? get lastNotificationTapEvent =>
      _lastNotificationTapEvent;

  /// Returns true if there is a notification tap event available
  bool get hasNotificationTapEvent => _lastNotificationTapEvent != null;

  /// Returns true if the last notification tap was from a daily reminder
  bool get cameFromDailyReminder =>
      _lastNotificationTapEvent?.isFromDailyReminder ?? false;

  /// Clear the current notification state (typically called after handling the notification)
  Future<void> clearNotificationState() async {
    _logger.info('Clearing notification state');

    try {
      // Clear in-memory state
      _lastNotificationTapEvent = null;
      _cameFromNotification = false;

      // Clear persisted state
      await _clearPersistedState();

      _logger.info('Notification state cleared');
    } catch (e) {
      _logger.error('Failed to clear notification state: $e');
    }
  }

  /// Get detailed notification state for debugging
  Future<Map<String, dynamic>> getNotificationState() async {
    try {
      final persistedEvent = await _getPersistedNotificationTap();

      return {
        'cameFromNotification': _cameFromNotification,
        'hasNotificationTapEvent': hasNotificationTapEvent,
        'cameFromDailyReminder': cameFromDailyReminder,
        'currentSessionEvent': _lastNotificationTapEvent?.toString(),
        'persistedEvent': persistedEvent?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.error('Failed to get notification state: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Returns true if there's a notification event from a previous session that hasn't been handled
  Future<bool> hasPendingNotificationFromPreviousSession() async {
    try {
      final persistedEvent = await _getPersistedNotificationTap();
      return persistedEvent != null && !_cameFromNotification;
    } catch (e) {
      _logger.warning('Failed to check for pending notification: $e');
      return false;
    }
  }

  /// Get and clear any pending notification from previous session
  Future<NotificationTapEvent?> consumePendingNotification() async {
    try {
      final persistedEvent = await _getPersistedNotificationTap();
      if (persistedEvent != null) {
        // Set up current session state
        _lastNotificationTapEvent = persistedEvent;
        _cameFromNotification = true;

        // Clear the persisted state since we've now consumed it
        await _clearPersistedState();

        _logger.info(
          'Consumed pending notification from previous session: $persistedEvent',
        );
        return persistedEvent;
      }
      return null;
    } catch (e) {
      _logger.error('Failed to consume pending notification: $e');
      return null;
    }
  }

  // Private helper methods

  Future<void> _loadPersistedState() async {
    final persistedEvent = await _getPersistedNotificationTap();
    if (persistedEvent != null) {
      _logger.info(
        'Found persisted notification tap event from previous session',
      );
      // Don't automatically set _cameFromNotification here - let the app decide when to consume it
    }
  }

  Future<void> _persistNotificationTap(NotificationTapEvent event) async {
    final eventData = {
      'notificationId': event.notificationId,
      'payload': event.payload,
      'actionId': event.actionId,
      'input': event.input,
      'tapTime': event.tapTime.toIso8601String(),
      'type': event.type.value,
      'platformData': event.platformData,
    };

    await _userDataService.storeValue(
      '${StorageKeys.notificationPrefix}lastTapEvent',
      json.encode(eventData),
    );
    await _userDataService.storeValue(
      '${StorageKeys.notificationPrefix}lastTapTime',
      event.tapTime.toIso8601String(),
    );
  }

  Future<NotificationTapEvent?> _getPersistedNotificationTap() async {
    final eventJson = await _userDataService.getValue<String>(
      '${StorageKeys.notificationPrefix}lastTapEvent',
    );
    if (eventJson == null || eventJson.isEmpty) return null;

    try {
      final eventData = json.decode(eventJson) as Map<String, dynamic>;
      final tapTime = DateTime.parse(eventData['tapTime'] as String);
      final type = NotificationType.fromString(eventData['type'] as String);

      return NotificationTapEvent(
        notificationId: eventData['notificationId'] as int,
        payload: eventData['payload'] as String?,
        actionId: eventData['actionId'] as String?,
        input: eventData['input'] as String?,
        tapTime: tapTime,
        type: type,
        platformData: eventData['platformData'] as Map<String, dynamic>?,
      );
    } catch (e) {
      _logger.warning('Failed to parse persisted notification tap event: $e');
      return null;
    }
  }

  Future<void> _clearPersistedState() async {
    await _userDataService.removeValue(
      '${StorageKeys.notificationPrefix}lastTapEvent',
    );
    await _userDataService.removeValue(
      '${StorageKeys.notificationPrefix}lastTapTime',
    );
  }
}
