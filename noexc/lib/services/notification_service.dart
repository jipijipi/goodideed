import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'user_data_service.dart';
import 'logger_service.dart';
import '../constants/storage_keys.dart';
import '../utils/active_date_calculator.dart';
import '../models/notification_permission_status.dart';
import '../models/notification_tap_event.dart';
import 'app_state_service.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final UserDataService _userDataService;
  final LoggerService _logger = LoggerService.instance;
  late final ActiveDateCalculator _activeDateCalculator;
  
  // App state service for tracking notification taps
  AppStateService? _appStateService;
  
  // Callback for notification tap events (for backward compatibility)
  Function(NotificationTapEvent)? _onNotificationTap;
  
  static const int _dailyReminderNotificationId = 1001;
  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily Task Reminders';
  static const String _channelDescription = 'Notifications to remind you about your daily task';

  NotificationService(this._userDataService) {
    _activeDateCalculator = ActiveDateCalculator(_userDataService);
  }

  Future<void> initialize() async {
    _logger.info('Initializing NotificationService for platform: ${Platform.operatingSystem}');
    
    try {
      // Initialize timezone data with validation
      _logger.info('Initializing timezone data...');
      tz.initializeTimeZones();
      
      // Validate timezone initialization
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        _logger.info('Timezone initialized successfully: ${currentZone.name}, current time: $now');
      } catch (e) {
        _logger.error('Timezone validation failed: $e');
        throw Exception('Timezone initialization failed: $e');
      }
      
      // Detect iOS simulator
      final isIOSSimulator = Platform.isIOS && _isIOSSimulator();
      if (isIOSSimulator) {
        _logger.warning('Running on iOS Simulator - notifications may have limited functionality');
      }
      
      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization - Do NOT auto-request permissions on launch
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      _logger.info('Initializing flutter_local_notifications plugin...');
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create notification channel for Android
      if (Platform.isAndroid) {
        _logger.info('Creating Android notification channel...');
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

  /// Set the AppStateService for tracking notification taps
  void setAppStateService(AppStateService appStateService) {
    _appStateService = appStateService;
  }

  /// Set callback for notification tap events (for backward compatibility)
  void setNotificationTapCallback(Function(NotificationTapEvent) callback) {
    _onNotificationTap = callback;
  }

  /// Get current notification permission status without requesting permissions
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    _logger.info('Checking notification permission status');
    
    try {
      // Check if we've ever requested permissions
      final requestCount = await _userDataService.getValue<int>(StorageKeys.notificationPermissionRequestCount) ?? 0;
      final hasBeenRequested = requestCount > 0;
      
      // Get stored permission status if available
      final storedStatus = await _userDataService.getValue<String>(StorageKeys.notificationPermissionStatus);
      if (storedStatus != null) {
        try {
          final index = NotificationPermissionStatus.values.indexWhere((status) => status.name == storedStatus);
          if (index != -1) {
            final status = NotificationPermissionStatus.values[index];
            _logger.info('Found stored permission status: $status');
            return status;
          }
        } catch (e) {
          _logger.warning('Failed to parse stored permission status: $e');
        }
      }
      
      if (Platform.isIOS) {
        // On iOS, we can't check permission status without requesting
        // So we rely on stored status or assume not requested if never stored
        if (!hasBeenRequested) {
          return NotificationPermissionStatus.notRequested;
        }
        
        // If we have requested before but no stored status, it's unknown
        return NotificationPermissionStatus.unknown;
      }
      
      if (Platform.isAndroid) {
        // On Android, we can't easily check permission status without requesting
        // Similar approach - rely on stored status
        if (!hasBeenRequested) {
          return NotificationPermissionStatus.notRequested;
        }
        
        return NotificationPermissionStatus.unknown;
      }
      
      // Other platforms (including macOS)
      if (!hasBeenRequested) {
        return NotificationPermissionStatus.notRequested;
      }
      
      return NotificationPermissionStatus.unknown;
    } catch (e) {
      _logger.error('Failed to get permission status: $e');
      return NotificationPermissionStatus.unknown;
    }
  }

  Future<bool> requestPermissions() async {
    _logger.info('=== REQUESTING NOTIFICATION PERMISSIONS ===');
    _logger.info('Platform: ${Platform.operatingSystem}');
    
    // Update request tracking
    final requestCount = await _userDataService.getValue<int>(StorageKeys.notificationPermissionRequestCount) ?? 0;
    await _userDataService.storeValue(StorageKeys.notificationPermissionRequestCount, requestCount + 1);
    await _userDataService.storeValue(StorageKeys.notificationPermissionLastRequested, DateTime.now().toIso8601String());
    
    try {
      if (Platform.isIOS) {
        _logger.info('iOS permissions - requesting alert, badge, and sound');
        if (_isIOSSimulator()) {
          _logger.warning('Running on iOS Simulator - permissions may behave differently');
        }
        
        final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation == null) {
          _logger.error('iOS implementation not found');
          return false;
        }
        
        final result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        _logger.info('iOS permissions result: $result');
        _logger.info('Alert: ${result != null ? "granted" : "denied/unknown"}');
        
        // Store permission status
        final status = NotificationPermissionStatus.fromBoolean(result, true);
        await _userDataService.storeValue(StorageKeys.notificationPermissionStatus, status.name);
        
        return result ?? false;
      }
      
      if (Platform.isAndroid) {
        _logger.info('Android permissions - requesting notification permission');
        final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation == null) {
          _logger.error('Android implementation not found');
          return false;
        }
        
        final result = await androidImplementation.requestNotificationsPermission();
        _logger.info('Android permissions result: $result');
        
        // Store permission status
        final status = NotificationPermissionStatus.fromBoolean(result, true);
        await _userDataService.storeValue(StorageKeys.notificationPermissionStatus, status.name);
        
        return result ?? false;
      }
      
      _logger.info('Unknown platform - defaulting to true');
      return true; // Default to true for other platforms
    } catch (e) {
      _logger.error('=== PERMISSION REQUEST FAILED ===');
      _logger.error('Error: $e');
      _logger.error('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> scheduleDeadlineReminder() async {
    _logger.info('=== SCHEDULING DEADLINE REMINDER ===');
    _logger.info('Platform: ${Platform.operatingSystem}');
    if (Platform.isIOS) {
      _logger.info('iOS Simulator: ${_isIOSSimulator()}');
    }
    
    try {
      // Check if reminders are enabled via intensity setting
      final remindersIntensity = await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      _logger.info('Reminders intensity: $remindersIntensity');
      
      if (remindersIntensity <= 0) {
        _logger.info('Reminders disabled (intensity: $remindersIntensity), canceling notifications');
        await cancelAllNotifications();
        return;
      }
      
      // Get deadline time
      final deadlineTimeString = await _userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
      _logger.info('Deadline time string: $deadlineTimeString');
      
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
      
      _logger.info('Parsed time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      
      // Get task current date (next due date)
      final currentDateString = await _userDataService.getValue<String>('task.currentDate');
      _logger.info('Task current date: $currentDateString');
      
      if (currentDateString == null || currentDateString.isEmpty) {
        _logger.warning('No task current date set, cannot schedule reminder');
        return;
      }
      
      // Validate timezone before scheduling
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        _logger.info('Current timezone: ${currentZone.name}');
        _logger.info('Current time: $now');
        
        // Parse task.currentDate (expected format: YYYY-MM-DD or similar)
        DateTime taskDate;
        try {
          taskDate = DateTime.parse(currentDateString);
          _logger.info('Parsed task date: $taskDate');
        } catch (e) {
          _logger.error('Failed to parse task current date "$currentDateString": $e');
          return;
        }
        
        // Schedule notification for task date at deadline time
        var scheduledDate = tz.TZDateTime(tz.local, taskDate.year, taskDate.month, taskDate.day, hour, minute);
        _logger.info('Notification scheduled for task date: $scheduledDate');
        
        // Check if scheduled date is in the past - use next active date as fallback
        if (scheduledDate.isBefore(now)) {
          _logger.warning('Scheduled date $scheduledDate is in the past (current: $now)');
          _logger.info('Falling back to next active date for notification scheduling');
          
          try {
            // Get next active date and combine with deadline time
            final nextActiveDate = await _activeDateCalculator.getNextActiveDate();
            final nextActiveDateTime = DateTime.parse(nextActiveDate);
            scheduledDate = tz.TZDateTime(tz.local, nextActiveDateTime.year, nextActiveDateTime.month, nextActiveDateTime.day, hour, minute);
            
            _logger.info('Rescheduled to next active date: $scheduledDate');
            
            // Store fallback information for debugging
            await _userDataService.storeValue('${StorageKeys.notificationPrefix}fallbackDate', nextActiveDate);
            await _userDataService.storeValue('${StorageKeys.notificationPrefix}fallbackReason', 'task.currentDate was in the past');
            
            // Verify the new date isn't also in the past (edge case)
            if (scheduledDate.isBefore(now)) {
              _logger.error('Next active date $scheduledDate is also in the past - this should not happen');
              await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
              return;
            }
          } catch (e) {
            _logger.error('Failed to calculate fallback date: $e');
            await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
            return;
          }
        } else {
          // Clear any previous fallback information
          await _userDataService.removeValue('${StorageKeys.notificationPrefix}fallbackDate');
          await _userDataService.removeValue('${StorageKeys.notificationPrefix}fallbackReason');
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
        
        // Create payload with tracking information
        final payload = json.encode({
          'type': 'dailyReminder',
          'scheduledDate': scheduledDate.toIso8601String(),
          'taskDate': currentDateString,
          'deadlineTime': deadlineTimeString,
          'notificationId': _dailyReminderNotificationId,
        });
        
        _logger.info('Calling zonedSchedule with:');
        _logger.info('  ID: $_dailyReminderNotificationId');
        _logger.info('  Title: Task Reminder');
        _logger.info('  Body: Time to check in on your task!');
        _logger.info('  Scheduled date: $scheduledDate');
        _logger.info('  Payload: $payload');
        _logger.info('  No repeat - single notification for this task date');
        
        await _notifications.zonedSchedule(
          _dailyReminderNotificationId,
          'Task Reminder',
          'Time to check in on your task!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
          // No matchDateTimeComponents - single notification for specific date
        );
        
        _logger.info('zonedSchedule call completed successfully');
        
        // Verify the notification was scheduled
        final pendingNotifications = await _notifications.pendingNotificationRequests();
        _logger.info('Pending notifications after scheduling: ${pendingNotifications.length}');
        for (final notification in pendingNotifications) {
          _logger.info('  - ID: ${notification.id}, Title: ${notification.title}');
        }
        
        // Store when we last scheduled the notification and the target date/time
        await _userDataService.storeValue(StorageKeys.notificationLastScheduled, DateTime.now().toIso8601String());
        await _userDataService.storeValue(StorageKeys.notificationScheduledFor, scheduledDate.toIso8601String());
        await _userDataService.storeValue(StorageKeys.notificationIsEnabled, true);
        
        _logger.info('=== SCHEDULING COMPLETED SUCCESSFULLY ===');
        
      } catch (timezoneError) {
        _logger.error('Timezone error during scheduling: $timezoneError');
        throw Exception('Timezone error: $timezoneError');
      }
      
    } catch (e) {
      _logger.error('=== SCHEDULING FAILED ===');
      _logger.error('Error: $e');
      _logger.error('Stack trace: ${StackTrace.current}');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      rethrow;
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
    _logger.info('Notification tapped: ID=${response.id}, payload=${response.payload}');
    
    try {
      // Create notification tap event
      final tapEvent = NotificationTapEvent.fromResponse(
        response.id ?? 0,
        response.payload,
        response.actionId,
        response.input,
        response.data,
      );
      
      _logger.info('Created NotificationTapEvent: $tapEvent');
      
      // Track the event using AppStateService if available
      if (_appStateService != null) {
        _appStateService!.handleNotificationTap(tapEvent);
        _logger.info('Notification tap event tracked by AppStateService');
      } else {
        _logger.warning('AppStateService not set - tap event not tracked');
      }
      
      // Fire callback if set (for backward compatibility)
      if (_onNotificationTap != null) {
        _onNotificationTap!(tapEvent);
        _logger.info('Notification tap event fired to callback');
      }
    } catch (e) {
      _logger.error('Failed to process notification tap: $e');
    }
  }

  /// Detect if running on iOS simulator
  bool _isIOSSimulator() {
    try {
      // This is a simple heuristic - iOS simulators typically have different device identifiers
      // In a real app, you might use a more sophisticated detection method
      // For now, we'll assume any iOS environment during development is likely a simulator
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Format DateTime for display
  Map<String, String> _formatDateTime(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      String dayLabel;
      if (dateOnly == today) {
        dayLabel = 'Today';
      } else if (dateOnly == tomorrow) {
        dayLabel = 'Tomorrow';
      } else {
        // Format as weekday, month day
        final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final weekday = weekdays[dateTime.weekday - 1];
        final month = months[dateTime.month - 1];
        dayLabel = '$weekday, $month ${dateTime.day}';
      }
      
      // Format time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      final timeLabel = '$displayHour:$minute $period';
      
      return {
        'formatted': '$dayLabel at $timeLabel',
        'day': dayLabel,
        'time': timeLabel,
      };
    } catch (e) {
      return {'formatted': 'Invalid date'};
    }
  }

  /// Format Duration for "time until" display
  String _formatDuration(Duration duration) {
    try {
      if (duration.inDays > 0) {
        final days = duration.inDays;
        final hours = duration.inHours % 24;
        if (days == 1) {
          return hours > 0 ? 'in 1 day, $hours hours' : 'in 1 day';
        } else {
          return hours > 0 ? 'in $days days, $hours hours' : 'in $days days';
        }
      } else if (duration.inHours > 0) {
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        if (hours == 1) {
          return minutes > 0 ? 'in 1 hour, $minutes min' : 'in 1 hour';
        } else {
          return minutes > 0 ? 'in $hours hours, $minutes min' : 'in $hours hours';
        }
      } else if (duration.inMinutes > 0) {
        final minutes = duration.inMinutes;
        return 'in $minutes minutes';
      } else {
        return 'very soon';
      }
    } catch (e) {
      return 'unknown time';
    }
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
      
      // Get fallback information
      final fallbackDate = await _userDataService.getValue<String>('${StorageKeys.notificationPrefix}fallbackDate');
      final fallbackReason = await _userDataService.getValue<String>('${StorageKeys.notificationPrefix}fallbackReason');
      
      // Add timezone information
      String timezoneInfo = 'Unknown';
      String currentTime = 'Unknown';
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        timezoneInfo = currentZone.name;
        currentTime = now.toString();
      } catch (e) {
        timezoneInfo = 'Error: $e';
      }
      
      // Add permission status (basic check)
      String permissionStatus = 'Unknown';
      if (Platform.isIOS) {
        permissionStatus = 'iOS (check device settings)';
        if (_isIOSSimulator()) {
          permissionStatus += ' - Simulator detected';
        }
      } else if (Platform.isAndroid) {
        permissionStatus = 'Android (check device settings)';
      }
      
      return {
        'isEnabled': isEnabled,
        'lastScheduled': lastScheduled,
        'remindersIntensity': remindersIntensity,
        'deadlineTime': deadlineTime,
        'pendingCount': pendingCount,
        'timezone': timezoneInfo,
        'currentTime': currentTime,
        'permissions': permissionStatus,
        'platform': Platform.operatingSystem,
        'isIOSSimulator': Platform.isIOS ? _isIOSSimulator() : false,
        'fallbackDate': fallbackDate,
        'fallbackReason': fallbackReason,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.error('Failed to get notification status: $e');
      return {
        'isEnabled': false,
        'error': e.toString(),
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Get formatted details of all scheduled notifications
  Future<List<Map<String, dynamic>>> getScheduledNotificationDetails() async {
    try {
      final pending = await getPendingNotifications();
      
      // Get the stored scheduled date/time if available
      final scheduledForString = await _userDataService.getValue<String>(StorageKeys.notificationScheduledFor);
      DateTime? scheduledFor;
      if (scheduledForString != null && scheduledForString.isNotEmpty) {
        try {
          scheduledFor = DateTime.parse(scheduledForString);
        } catch (e) {
          _logger.warning('Failed to parse stored scheduled date: $e');
        }
      }
      
      return pending.map((notification) {
        String scheduledTime = 'Unknown';
        String timeUntil = '';
        
        if (scheduledFor != null) {
          // Format the scheduled date/time
          final formatter = _formatDateTime(scheduledFor);
          scheduledTime = formatter['formatted'] ?? 'Unknown';
          
          // Calculate time until notification
          final now = DateTime.now();
          if (scheduledFor.isAfter(now)) {
            final difference = scheduledFor.difference(now);
            timeUntil = _formatDuration(difference);
          } else {
            timeUntil = 'Past due';
          }
        } else {
          // Fallback if we can't get the stored date
          scheduledTime = 'Check task.currentDate + deadlineTime';
        }
        
        return {
          'id': notification.id,
          'title': notification.title ?? 'No title',
          'body': notification.body ?? 'No body',
          'payload': notification.payload ?? 'No payload',
          'scheduledTime': scheduledTime,
          'timeUntil': timeUntil,
          'type': 'Task reminder',
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
      final info = {
        'platform': Platform.operatingSystem,
        'supportsScheduled': true,
        'supportsRepeating': true,
        'channelId': _channelId,
        'channelName': _channelName,
        'dailyReminderNotificationId': _dailyReminderNotificationId,
      };
      
      // Add iOS-specific information
      if (Platform.isIOS) {
        info['isIOSSimulator'] = _isIOSSimulator();
        info['simulatorLimitations'] = _isIOSSimulator() 
            ? 'Notifications may not work properly in iOS Simulator'
            : 'Running on real iOS device';
        info['permissionNote'] = 'Check iOS Settings > Notifications > Your App';
      } else if (Platform.isAndroid) {
        info['permissionNote'] = 'Check Android Settings > Apps > Your App > Notifications';
      }
      
      // Add timezone information
      try {
        final currentZone = tz.local;
        info['timezone'] = currentZone.name;
        info['timezoneStatus'] = 'OK';
      } catch (e) {
        info['timezone'] = 'Error';
        info['timezoneStatus'] = 'Failed: $e';
      }
      
      return info;
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }
}