import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'user_data_service.dart';
import 'logger_service.dart';
import '../constants/storage_keys.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final UserDataService _userDataService;
  final LoggerService _logger = LoggerService.instance;
  
  static const int _dailyReminderNotificationId = 1001;
  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily Task Reminders';
  static const String _channelDescription = 'Notifications to remind you about your daily task';

  NotificationService(this._userDataService);

  Future<void> initialize() async {
    _logger.info('Initializing NotificationService');
    
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization  
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }
      
      _logger.info('NotificationService initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<bool> requestPermissions() async {
    _logger.info('Requesting notification permissions');
    
    try {
      if (Platform.isIOS) {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        _logger.info('iOS permissions result: $result');
        return result ?? false;
      }
      
      if (Platform.isAndroid) {
        final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final result = await androidImplementation?.requestNotificationsPermission();
        _logger.info('Android permissions result: $result');
        return result ?? false;
      }
      
      return true; // Default to true for other platforms
    } catch (e) {
      _logger.error('Failed to request notification permissions: $e');
      return false;
    }
  }

  Future<void> scheduleDeadlineReminder() async {
    _logger.info('Scheduling deadline reminder');
    
    try {
      // Check if reminders are enabled via intensity setting
      final remindersIntensity = await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      
      if (remindersIntensity <= 0) {
        _logger.info('Reminders disabled (intensity: $remindersIntensity), canceling notifications');
        await cancelAllNotifications();
        return;
      }
      
      // Get deadline time
      final deadlineTimeString = await _userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
      if (deadlineTimeString == null || deadlineTimeString.isEmpty) {
        _logger.warning('No deadline time set, cannot schedule reminder');
        return;
      }
      
      // Parse deadline time
      final timeParts = deadlineTimeString.split(':');
      if (timeParts.length != 2) {
        _logger.error('Invalid deadline time format: $deadlineTimeString');
        return;
      }
      
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      
      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        _logger.error('Invalid deadline time values: $deadlineTimeString');
        return;
      }
      
      // Schedule notification for today at deadline time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _notifications.zonedSchedule(
        _dailyReminderNotificationId,
        'Task Reminder',
        'Time to check in on your task!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      );
      
      // Store when we last scheduled the notification
      await _userDataService.storeValue(StorageKeys.notificationLastScheduled, DateTime.now().toIso8601String());
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, true);
      
      _logger.info('Deadline reminder scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      _logger.error('Failed to schedule deadline reminder: $e');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
    }
  }

  Future<void> cancelAllNotifications() async {
    _logger.info('Canceling all notifications');
    
    try {
      await _notifications.cancelAll();
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      _logger.info('All notifications canceled');
    } catch (e) {
      _logger.error('Failed to cancel notifications: $e');
      // Still mark as disabled even if cancellation fails
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
    }
  }

  Future<void> cancelDeadlineReminder() async {
    _logger.info('Canceling deadline reminder');
    
    try {
      await _notifications.cancel(_dailyReminderNotificationId);
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      _logger.info('Deadline reminder canceled');
    } catch (e) {
      _logger.error('Failed to cancel deadline reminder: $e');
      // Still mark as disabled even if cancellation fails
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      _logger.error('Failed to get pending notifications: $e');
      return [];
    }
  }

  Future<bool> hasScheduledNotifications() async {
    final pending = await getPendingNotifications();
    return pending.isNotEmpty;
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    // App will automatically open when notification is tapped
    // Additional handling can be added here if needed
  }

  // Debug helper methods
  
  /// Get detailed notification status for debugging
  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final isEnabled = await _userDataService.getValue<bool>(StorageKeys.notificationIsEnabled) ?? false;
      final lastScheduled = await _userDataService.getValue<String>(StorageKeys.notificationLastScheduled);
      final remindersIntensity = await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      final deadlineTime = await _userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
      final pendingCount = (await getPendingNotifications()).length;
      
      return {
        'isEnabled': isEnabled,
        'lastScheduled': lastScheduled,
        'remindersIntensity': remindersIntensity,
        'deadlineTime': deadlineTime,
        'pendingCount': pendingCount,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.error('Failed to get notification status: $e');
      return {
        'isEnabled': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Get formatted details of all scheduled notifications
  Future<List<Map<String, dynamic>>> getScheduledNotificationDetails() async {
    try {
      final pending = await getPendingNotifications();
      
      return pending.map((notification) {
        return {
          'id': notification.id,
          'title': notification.title ?? 'No title',
          'body': notification.body ?? 'No body',
          'payload': notification.payload ?? 'No payload',
          'scheduledTime': 'Daily repeat',
          'type': 'Daily reminder',
        };
      }).toList();
    } catch (e) {
      _logger.error('Failed to get scheduled notification details: $e');
      return [];
    }
  }
  
  /// Force reschedule notifications (for debug purposes)
  Future<void> forceReschedule() async {
    _logger.info('Force rescheduling notifications (debug)');
    await scheduleDeadlineReminder();
  }
  
  /// Get platform-specific notification capabilities info
  Map<String, dynamic> getPlatformInfo() {
    try {
      return {
        'platform': Platform.operatingSystem,
        'supportsScheduled': true,
        'supportsRepeating': true,
        'channelId': _channelId,
        'channelName': _channelName,
        'dailyReminderNotificationId': _dailyReminderNotificationId,
      };
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }
}