import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'user_data_service.dart';
import 'logger_service.dart';
import '../constants/storage_keys.dart';
import '../models/notification_permission_status.dart';
import '../models/notification_tap_event.dart';
import 'app_state_service.dart';
import 'dart:convert';
import '../constants/session_constants.dart';
import 'service_locator.dart';
import 'semantic_content_service.dart';
import '../constants/notification_constants.dart';


/// Simple test environment detection
/// Returns true if we're running in a test environment
bool _isTestEnvironment() {
  // Check environment variables that are typically set during testing
  return const String.fromEnvironment('FLUTTER_TEST') == 'true' ||
         Platform.environment['FLUTTER_TEST'] == 'true' ||
         // Check for dart test runner
         Platform.script.path.contains('test') ||
         // Check if the current working directory contains test
         Platform.script.toString().contains('test');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final UserDataService _userDataService;
  final LoggerService _logger = LoggerService.instance;
  final SemanticContentService _semanticContentService;

  // App state service for tracking notification taps
  AppStateService? _appStateService;

  // Callback for notification tap events (for backward compatibility)
  Function(NotificationTapEvent)? _onNotificationTap;

  // Timezone synchronization
  static bool _timezoneInitialized = false;
  static bool _timezoneInitializing = false;
  static final List<Completer<void>> _timezoneInitWaiters = [];

  // Scheduling synchronization to prevent concurrent notification scheduling
  static Completer<void>? _schedulingCompleter;
  static bool _isScheduling = false;

  // Notification caching to prevent unnecessary recalculation
  String? _lastSchedulingHash;
  DateTime? _lastSchedulingTime;


  NotificationService(
    this._userDataService, {
    SemanticContentService? semanticContentService,
  }) : _semanticContentService = semanticContentService ?? SemanticContentService.instance;

  /// Safely initialize timezone data with synchronization to prevent race conditions
  static Future<void> _ensureTimezoneInitialized() async {
    if (_timezoneInitialized) return;

    if (_timezoneInitializing) {
      // Another thread is already initializing, wait for it
      final completer = Completer<void>();
      _timezoneInitWaiters.add(completer);
      return completer.future;
    }

    _timezoneInitializing = true;
    
    try {
      if (!_timezoneInitialized) {
        tz.initializeTimeZones();
        
        // Validate timezone initialization
        final currentZone = tz.local;
        // Ensure we can create timezone date objects for validation
        
        // Basic validation - ensure we can create timezone date objects
        if (currentZone.name.isEmpty) {
          throw Exception('Timezone name is empty after initialization');
        }
        
        _timezoneInitialized = true;
      }
    } finally {
      _timezoneInitializing = false;
      
      // Complete all waiting futures
      final waiters = List<Completer<void>>.from(_timezoneInitWaiters);
      _timezoneInitWaiters.clear();
      
      if (_timezoneInitialized) {
        for (final waiter in waiters) {
          if (!waiter.isCompleted) {
            waiter.complete();
          }
        }
      } else {
        for (final waiter in waiters) {
          if (!waiter.isCompleted) {
            waiter.completeError(Exception('Timezone initialization failed'));
          }
        }
      }
    }
  }

  Future<void> initialize() async {
    _logger.info(
      'Initializing NotificationService for platform: ${Platform.operatingSystem}',
    );
    _logger.info('Flutter version: ${Platform.version}');
    _logger.info('Is test environment: ${_isTestEnvironment()}');

    // Skip initialization in test environment
    if (_isTestEnvironment()) {
      _logger.info('Detected test environment - skipping platform initialization');
      return;
    }

    try {
      // Log platform version compatibility information
      final versionInfo = _getPlatformVersionInfo();
      _logger.info('Platform version: ${versionInfo['version']}');
      _logger.info('Major version: ${versionInfo['majorVersion']}');
      _logger.info('Requires notification permission: ${_requiresNotificationPermission()}');
      _logger.info('Supports exact alarms: ${_supportsExactAlarms()}');
      
      final limitations = _getPlatformLimitations();
      if (limitations.isNotEmpty) {
        _logger.info('Platform limitations:');
        for (final limitation in limitations) {
          _logger.info('  - $limitation');
        }
      }
      
      // Initialize timezone data with synchronization
      _logger.info('Initializing timezone data...');
      await _ensureTimezoneInitialized();
      
      final currentZone = tz.local;
      final now = tz.TZDateTime.now(tz.local);
      _logger.info(
        'Timezone initialized successfully: ${currentZone.name}, current time: $now',
      );

      // Detect iOS simulator
      final isIOSSimulator = Platform.isIOS && _isIOSSimulator();
      if (isIOSSimulator) {
        _logger.warning(
          'Running on iOS Simulator - notifications may have limited functionality',
        );
      }

      // Android initialization
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

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
      _logger.info('iOS Settings: requestAlertPermission=false, requestBadgePermission=false, requestSoundPermission=false');
      _logger.info('Android Settings: icon=@mipmap/ic_launcher');
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _logger.info('flutter_local_notifications plugin initialized successfully');

      // Create notification channel for Android
      if (Platform.isAndroid) {
        _logger.info('Creating Android notification channel...');
        await _createNotificationChannel();
      }

      // Check if app was launched from a notification
      await _checkAppLaunchFromNotification();

      _logger.info('NotificationService initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      NotificationConfig.channelId,
      NotificationConfig.channelName,
      description: NotificationConfig.channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
      final requestCount =
          await _userDataService.getValue<int>(
            StorageKeys.notificationPermissionRequestCount,
          ) ??
          0;
      final hasBeenRequested = requestCount > 0;

      // Get stored permission status if available
      final storedStatus = await _userDataService.getValue<String>(
        StorageKeys.notificationPermissionStatus,
      );
      if (storedStatus != null) {
        try {
          final index = NotificationPermissionStatus.values.indexWhere(
            (status) => status.name == storedStatus,
          );
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

        // iOS-specific logic for handling permission status after request
        // Try to get a better status indication by checking if we can schedule notifications
        try {
          // Check if we have any successful notification scheduling history
          final notificationEnabled = await _userDataService.getValue<bool>(
            StorageKeys.notificationIsEnabled,
          ) ?? false;
          
          // Check if notifications were successfully scheduled recently
          final lastScheduled = await _userDataService.getValue<String>(
            StorageKeys.notificationLastScheduled,
          );
          
          if (notificationEnabled && lastScheduled != null) {
            final lastScheduledTime = DateTime.tryParse(lastScheduled);
            if (lastScheduledTime != null && 
                DateTime.now().difference(lastScheduledTime).inDays < 7) {
              // If we successfully scheduled notifications recently, assume granted
              _logger.info('Inferring granted status from recent successful scheduling');
              
              // Update stored status for future calls
              await _userDataService.storeValue(
                StorageKeys.notificationPermissionStatus,
                NotificationPermissionStatus.granted.name,
              );
              
              return NotificationPermissionStatus.granted;
            }
          }
          
          // Check if we've attempted to schedule but couldn't (indication of denial)
          if (!notificationEnabled && hasBeenRequested) {
            // We requested permissions but can't schedule - likely denied
            _logger.info('Inferring denied status from inability to schedule after permission request');
            
            // Update stored status
            await _userDataService.storeValue(
              StorageKeys.notificationPermissionStatus,
              NotificationPermissionStatus.denied.name,
            );
            
            return NotificationPermissionStatus.denied;
          }
          
        } catch (e) {
          _logger.warning('Error inferring iOS permission status: $e');
        }

        // If we have requested before but no stored status and can't infer, it's unknown
        _logger.info('Unable to determine iOS permission status, returning unknown');
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

    if (_isTestEnvironment()) {
      _logger.info('Test environment - simulating permission grant');
      // Update request tracking for test environment
      final requestCount =
          await _userDataService.getValue<int>(
            StorageKeys.notificationPermissionRequestCount,
          ) ?? 0;
      await _userDataService.storeValue(
        StorageKeys.notificationPermissionRequestCount, 
        requestCount + 1
      );
      await _userDataService.storeValue(
        StorageKeys.notificationPermissionLastRequested,
        DateTime.now().toIso8601String(),
      );
      await _userDataService.storeValue(
        StorageKeys.notificationPermissionStatus,
        'granted',
      );
      return true;
    }

    // Update request tracking
    final requestCount =
        await _userDataService.getValue<int>(
          StorageKeys.notificationPermissionRequestCount,
        ) ??
        0;
    await _userDataService.storeValue(
      StorageKeys.notificationPermissionRequestCount,
      requestCount + 1,
    );
    await _userDataService.storeValue(
      StorageKeys.notificationPermissionLastRequested,
      DateTime.now().toIso8601String(),
    );

    try {
      if (Platform.isIOS) {
        _logger.info('iOS permissions - requesting alert, badge, and sound');
        if (_isIOSSimulator()) {
          _logger.warning(
            'Running on iOS Simulator - permissions may behave differently',
          );
        }

        final iosImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();
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

        // iOS permission handling is tricky because:
        // - result can be null even when permissions are granted
        // - iOS doesn't let us reliably check permission status after request
        // 
        // Strategy: Don't immediately store 'unknown' status for null results
        // Instead, let the permission status inference logic handle it
        
        if (result == true) {
          // Definitely granted - store it
          _logger.info('iOS permissions definitively granted');
          await _userDataService.storeValue(
            StorageKeys.notificationPermissionStatus,
            NotificationPermissionStatus.granted.name,
          );
          return true;
        } else if (result == false) {
          // Definitely denied - store it
          _logger.info('iOS permissions definitively denied');
          await _userDataService.storeValue(
            StorageKeys.notificationPermissionStatus,
            NotificationPermissionStatus.denied.name,
          );
          return false;
        } else {
          // result is null - don't store unknown status immediately
          // Let the system try to infer the actual status through usage patterns
          _logger.info('iOS permissions result is null - will infer status through usage patterns');
          
          // Return true optimistically - many iOS apps work this way
          // The actual permission status will be determined when scheduling is attempted
          return true;
        }
      }

      if (Platform.isAndroid) {
        _logger.info(
          'Android permissions - requesting notification permission',
        );
        final androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation == null) {
          _logger.error('Android implementation not found');
          return false;
        }

        final result =
            await androidImplementation.requestNotificationsPermission();
        _logger.info('Android permissions result: $result');

        // Store permission status
        final status = NotificationPermissionStatus.fromBoolean(result, true);
        await _userDataService.storeValue(
          StorageKeys.notificationPermissionStatus,
          status.name,
        );

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

  Future<void> scheduleDeadlineReminder({String? caller}) async {
    final callerInfo = caller ?? 'unknown';
    _logger.info('Scheduling request from: $callerInfo (waiting for lock...)');
    
    // Wait for any ongoing scheduling to complete
    while (_isScheduling) {
      if (_schedulingCompleter != null) {
        await _schedulingCompleter!.future;
      }
    }
    
    // Acquire the lock
    _isScheduling = true;
    _schedulingCompleter = Completer<void>();
    
    _logger.info('Scheduling lock acquired by: $callerInfo');
    final startTime = DateTime.now();
    
    try {
      await _scheduleDeadlineReminderImpl(caller: caller);
      final duration = DateTime.now().difference(startTime);
      _logger.info('Scheduling completed by: $callerInfo in ${duration.inMilliseconds}ms');
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _logger.error('Scheduling failed by: $callerInfo after ${duration.inMilliseconds}ms - $e');
      rethrow;
    } finally {
      // Release the lock
      _isScheduling = false;
      if (_schedulingCompleter != null && !_schedulingCompleter!.isCompleted) {
        _schedulingCompleter!.complete();
      }
      _schedulingCompleter = null;
    }
  }

  Future<void> _scheduleDeadlineReminderImpl({String? caller}) async {
    final callerInfo = caller != null ? ' (called by: $caller)' : '';
    _logger.info('=== SCHEDULING DAILY PLAN$callerInfo ===');
    _logger.info('Platform: ${Platform.operatingSystem}');
    if (Platform.isIOS) {
      _logger.info('iOS Simulator: ${_isIOSSimulator()}');
    }

    // Log existing notifications before scheduling
    try {
      final existingNotifications = await getPendingNotifications();
      _logger.info('Found ${existingNotifications.length} existing notifications before scheduling');
    } catch (e) {
      _logger.warning('Failed to check existing notifications before scheduling: $e');
    }

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification scheduling');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      // Check intensity first before doing expensive cache work
      final remindersIntensity =
          await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      _logger.info('Reminders intensity: $remindersIntensity');
      if (remindersIntensity <= 0) {
        _logger.info('Reminders disabled, canceling notifications');
        await cancelAllNotifications();
        return;
      }

      // Now check if we can skip scheduling due to caching (only for actual work)
      _logger.info('CACHE: Checking if scheduling can be skipped...');
      if (await _shouldSkipScheduling()) {
        _logger.info('CACHE: Scheduling skipped due to cache hit');
        return;
      }
      _logger.info('CACHE: Cache miss - proceeding with scheduling');

      // Resolve times and dates
      final currentDateString = await _userDataService.getValue<String>(
        StorageKeys.taskCurrentDate,
      );
      if (currentDateString == null || currentDateString.isEmpty) {
        _logger.warning('No task.currentDate set, cannot schedule');
        return;
      }

      final deadlineTimeString = await _getDeadlineTimeAsString();
      final startTimeString = await _getStartTimeAsString();
      _logger.info('Retrieved times - Start=$startTimeString, Deadline=$deadlineTimeString');
      
      // Validate time format before proceeding
      if (!_isValidTimeFormat(startTimeString)) {
        _logger.error('Invalid start time format: "$startTimeString"');
      }
      if (!_isValidTimeFormat(deadlineTimeString)) {
        _logger.error('Invalid deadline time format: "$deadlineTimeString"');
      }

      // Ensure timezone is initialized before scheduling
      await _ensureTimezoneInitialized();
      final nowTz = tz.TZDateTime.now(tz.local);
      _logger.info('Timezone OK: ${tz.local.name}, now=$nowTz');

      // Comprehensive notification cleanup - can be enabled via feature flag
      final enableCompleteCleanup = await _userDataService.getValue<bool>(
        'feature.completeNotificationCleanup',
      ) ?? true; // Default to true for better reliability
      
      if (enableCompleteCleanup) {
        _logger.info('Complete notification cleanup enabled - canceling ALL notifications');
        final pendingBefore = await getPendingNotifications();
        _logger.info('Found ${pendingBefore.length} notifications before complete cleanup');
        
        await cancelAllNotifications();
        
        final pendingAfter = await getPendingNotifications();
        _logger.info('Cleanup verification: ${pendingAfter.length} notifications remain after complete cleanup');
        
        if (pendingAfter.isNotEmpty) {
          _logger.warning('Complete cleanup failed - ${pendingAfter.length} notifications still exist');
          for (final remaining in pendingAfter) {
            _logger.warning('Surviving notification ID:${remaining.id} title:"${remaining.title}"');
          }
        } else {
          _logger.info('Complete cleanup successful - all notifications removed');
        }
      } else {
        _logger.info('Using legacy cleanup - only removing stale notifications');
        // Legacy cleanup: only sweep stale notifications for past task days
        await _cancelBeforeTaskDate(currentDateString);
      }

      // If scripts requested to keep only final today (date-scoped), enforce it
      final onlyFinalOnDate = await _userDataService.getValue<String>(
        '${StorageKeys.notificationPrefix}onlyFinalOnDate',
      );
      final todayStr = _todayDateString();
      final onlyFinalTodayFlag = (onlyFinalOnDate != null && onlyFinalOnDate == todayStr);
      if (onlyFinalTodayFlag) {
        await _keepOnlyFinalForDate(todayStr);
      }

      // Prime activeDays cache
      await _primeActiveDaysCache();

      // Build day-plan horizon from currentDate to endDate (inclusive) - Limited to 2 days maximum
      final endDate = await _userDataService.getValue<String>(
        StorageKeys.taskEndDate,
      );

      final datesToPlan = <String>[];
      try {
        final startDate = DateTime.parse(currentDateString);
        DateTime end = endDate != null && endDate.isNotEmpty
            ? DateTime.parse(endDate)
            : startDate; // fallback: only current day
        if (end.isBefore(startDate)) end = startDate;

        // Limit to maximum 2 days for task notifications
        int daysAdded = 0;
        for (var d = startDate;
            !d.isAfter(end) && daysAdded < NotificationConfig.maxTaskDays;
            d = d.add(const Duration(days: 1))) {
          if (_isActiveDay(d)) {
            datesToPlan.add(_fmtDate(d));
            daysAdded++;
          }
        }
        
        _logger.info('Task scheduling limited to ${datesToPlan.length} days (max ${NotificationConfig.maxTaskDays})');
      } catch (e) {
        _logger.warning('Failed building horizon: $e');
        datesToPlan.clear();
        datesToPlan.add(currentDateString);
      }

      // Log notification budget information
      final availableBudget = _calculateNotificationBudget();
      final budgetPerDay = availableBudget ~/ datesToPlan.length;
      _logger.info('Notification budget: $availableBudget total ($NotificationConfig.maxIOSNotifications iOS limit - ${NotificationConfig.defaultDailyComebackCount + NotificationConfig.defaultWeeklyComebackCount} comeback notifications)');
      _logger.info('Budget per day: $budgetPerDay notifications across ${datesToPlan.length} days');

      // Schedule multi-stage per planned day
      int scheduledCount = 0;
      int failedDays = 0;
      for (final dateStr in datesToPlan) {
        _logger.info('Processing date: $dateStr');
        final dayCount = await _scheduleDaySlots(
          dateStr,
          startTimeString,
          deadlineTimeString,
          remindersIntensity,
          onlyFinalTodayGlobal: onlyFinalTodayFlag,
          totalDaysCount: datesToPlan.length,
        );
        
        if (dayCount > 0) {
          scheduledCount += dayCount;
          _logger.info('Successfully scheduled $dayCount notifications for $dateStr');
        } else {
          failedDays++;
          _logger.warning('Failed to schedule any notifications for $dateStr');
        }
      }
      
      _logger.info('Scheduling summary: $scheduledCount notifications across ${datesToPlan.length - failedDays} successful days, $failedDays failed days');

      // Post-end come-back nudges (three one-shots on consecutive active days after endDate)
      if (endDate != null && endDate.isNotEmpty) {
        scheduledCount += await _scheduleComeBackSeries(
          endDate,
          startTimeString,
          maxShots: 3,
        );

        // Weekly repeating fallback after the series (light touch)
        await _scheduleWeeklyComeBackFallback(endDate, startTimeString);
      }

      await _userDataService.storeValue(
        StorageKeys.notificationLastScheduled,
        DateTime.now().toIso8601String(),
      );
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        scheduledCount > 0,
      );

      // Verify final notification count
      try {
        final finalNotifications = await getPendingNotifications();
        _logger.info('=== SCHEDULING COMPLETED ===');
        _logger.info('Scheduled: $scheduledCount new notifications');
        _logger.info('Total pending: ${finalNotifications.length} notifications');
        _logger.info('Notifications enabled: ${scheduledCount > 0}');
        
        // Log breakdown by type for debugging
        final typeBreakdown = <String, int>{};
        for (final notification in finalNotifications) {
          if (notification.payload != null) {
            try {
              final data = json.decode(notification.payload!) as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'unknown';
              typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
            } catch (_) {
              typeBreakdown['invalid'] = (typeBreakdown['invalid'] ?? 0) + 1;
            }
          } else {
            typeBreakdown['no-payload'] = (typeBreakdown['no-payload'] ?? 0) + 1;
          }
        }
        _logger.info('Notification types: $typeBreakdown');
      } catch (e) {
        _logger.warning('Failed to verify final notification count: $e');
        _logger.info('=== SCHEDULING COMPLETED: $scheduledCount notifications (verification failed) ===');
      }
      
      // Update scheduling cache after successful completion
      try {
        final finalHash = await _generateSchedulingHash();
        _updateSchedulingCache(finalHash);
      } catch (e) {
        _logger.warning('Failed to update scheduling cache after completion: $e');
      }
    } catch (e) {
      _logger.error('=== SCHEDULING FAILED ===');
      _logger.error('Error: $e');
      _logger.error('Stack trace: ${StackTrace.current}');
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
      rethrow;
    }
  }


  // Compute and schedule one day's slots (start/mid/deadline)
  Future<int> _scheduleDaySlots(
    String dateStr,
    String startTime,
    String deadlineTime,
    int intensity,
    {bool onlyFinalTodayGlobal = false,
    int totalDaysCount = 1}
  ) async {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final isToday = _sameDate(date, now);

      final start = _composeLocal(date, startTime);
      final end = _composeLocal(date, deadlineTime);
      
      // Handle time parsing failures
      if (start == null || end == null) {
        _logger.warning('Failed to parse times for $dateStr: start=$startTime, deadline=$deadlineTime');
        return 0; // Skip this day entirely rather than scheduling fallback
      }
      
      if (end.isBefore(start)) {
        // Guard: if misconfigured, schedule only deadline
        _logger.warning('Invalid time configuration for $dateStr: deadline ($deadlineTime) before start ($startTime)');
        return await _scheduleSlot(
          dateStr,
          'deadline',
          end,
          title: 'Task Reminder',
          body: 'Time to check in on your task!',
        );
      }

      int count = 0;
      // Start encouragement (skip if today and in the past, or if only-final-today is set)
      if (!(onlyFinalTodayGlobal && isToday)) {
        if (!(isToday && start.isBefore(now))) {
          count += await _scheduleSlot(
            dateStr,
            'start',
            start,
            title: 'Let’s get it started',
            body: 'Quick nudge: your task window opens now.',
          );
        }
      }

      // Mid-window reminders based on intensity using new distribution system
      final window = end.difference(start).inMinutes;
      
      _logger.info('Scheduling $dateStr: ${(window / 60).toStringAsFixed(1)}h window (${_formatNotificationTime(start)} to ${_formatNotificationTime(end)}), intensity $intensity');
      
      if (window > 0 && intensity > 0 && !(onlyFinalTodayGlobal && isToday)) {
        final windowHours = (window / 60).round(); // Move this outside the intensity check
        List<double> midFractions;
        
        if (intensity == 1) {
          // Level 1: Keep legacy behavior (1 mid at 50%)
          midFractions = _fractionsForIntensity(intensity);
        } else {
          // Level 2 & 3: Use new quadratic distribution
          final availableBudget = _calculateNotificationBudget();
          final midNotificationCount = _getNotificationCountForIntensity(intensity, availableBudget, totalDaysCount);
          
          midFractions = _generateQuadraticDistribution(midNotificationCount, windowHours);
          
          _logger.info('Generated ${midFractions.length} quadratic fractions for intensity $intensity ($windowHours hour window)');
          
          // Debug: Show notification spread
          if (midFractions.isNotEmpty) {
            final referenceWindow = _calculateReferenceWindowMinutes(windowHours);
            final firstTime = (referenceWindow * midFractions.first).round();
            final lastTime = (referenceWindow * midFractions.last).round();
            _logger.info('Notification spread: ${firstTime}min to ${lastTime}min');
          }
        }
        
        _logger.info('Scheduling ${midFractions.length} mid notifications');
        
        var idx = 0;
        var skippedCount = 0;
        var scheduledCount = 0;
        
        for (final f in midFractions) {
          idx += 1;
          
          // Calculate minutes from start using helper method for reference window calculation
          final referenceWindow = _calculateReferenceWindowMinutes(windowHours);
          final minutesFromStart = (referenceWindow * f).round();
          
          final midTime = start.add(Duration(minutes: minutesFromStart));
          
          _logger.info('  SCHEDULING - notification time ${_formatNotificationTime(midTime)} (${minutesFromStart}min from start)');
          
          if (isToday && midTime.isBefore(now)) {
            skippedCount++;
            _logger.info('  SKIPPED - notification time ${_formatNotificationTime(midTime)} is before current time ${_formatNotificationTime(now)}');
            continue;
          }
          
          if (midTime.isAfter(end)) {
            skippedCount++;
            _logger.info('  SKIPPED - notification time ${_formatNotificationTime(midTime)} is after deadline ${_formatNotificationTime(end)}');
            continue;
          }
          
          _logger.info('  VALID - notification time ${_formatNotificationTime(midTime)} is valid');
          final result = await _scheduleSlot(
            dateStr,
            'mid$idx',
            midTime,
            title: 'Stay on track',
            body: 'Quick check-in toward your goal.',
          );
          
          if (result > 0) {
            scheduledCount++;
            _logger.info('  SUCCESS - notification mid$idx scheduled');
          } else {
            _logger.info('  FAILED - notification mid$idx scheduling failed');
          }
          
          count += result;
        }
        
        _logger.info('=== SCHEDULING LOOP SUMMARY ===');
        _logger.info('Total fractions processed: ${midFractions.length}');
        _logger.info('Successfully scheduled: $scheduledCount');
        _logger.info('Skipped (past time): $skippedCount');
        _logger.info('Failed to schedule: ${midFractions.length - scheduledCount - skippedCount}');
      }

      // Deadline completion check (skip only if in the past today)
      if (!(isToday && end.isBefore(now))) {
        count += await _scheduleSlot(
          dateStr,
          'deadline',
          end,
          title: 'Deadline check',
          body: 'Did you complete your task today?',
        );
      }
      return count;
    } catch (e) {
      _logger.warning('Failed scheduling day $dateStr: $e');
      return 0;
    }
  }

  Future<int> _scheduleComeBackSeries(
    String endDateStr,
    String startTime,
    {int maxShots = 3}
  ) async {
    try {
      final shots = <DateTime>[];
      DateTime cursor = DateTime.parse(endDateStr);
      for (int i = 0; i < maxShots; i++) {
        cursor = _nextActiveDateAfter(cursor);
        final t = _composeLocal(cursor, startTime);
        if (t != null) {
          shots.add(t);
        } else {
          _logger.warning('Failed to parse comeback start time "$startTime" for date ${_fmtDate(cursor)}');
        }
      }
      int count = 0;
      var i = 0;
      for (final t in shots) {
        i += 1;
        if (t.isBefore(DateTime.now())) continue;
        count += await _scheduleSlot(
          _fmtDate(t),
          'comeback$i',
          t,
          title: 'Come back to your habit',
          body: 'Pick it back up today.',
        );
      }
      return count;
    } catch (e) {
      _logger.warning('Failed scheduling comeback series: $e');
      return 0;
    }
  }

  Future<void> _scheduleWeeklyComeBackFallback(
    String endDateStr,
    String startTime,
  ) async {
    try {
      // Skip the first 3 active dates used by comeback series to avoid collision
      DateTime cursor = DateTime.parse(endDateStr);
      for (int i = 0; i < NotificationConfig.defaultDailyComebackCount; i++) {
        cursor = _nextActiveDateAfter(cursor);
      }
      
      // Schedule weekly comeback notifications
      final weeklyDates = <DateTime>[];
      for (int week = 0; week < NotificationConfig.defaultWeeklyComebackCount; week++) {
        // Find next active date that's 7 days after previous
        cursor = _nextActiveDateAfter(cursor.add(const Duration(days: 6))); // 6 days + 1 from nextActiveDateAfter = 7 days
        weeklyDates.add(cursor);
      }
      
      _logger.info('Scheduling ${weeklyDates.length} weekly comeback notifications starting ${_fmtDate(weeklyDates.first)}');

      for (int i = 0; i < weeklyDates.length; i++) {
        final weeklyDate = weeklyDates[i];
        final weeklyTime = _composeLocal(weeklyDate, startTime);
        
        if (weeklyTime == null) {
          _logger.warning('Failed to parse weekly comeback start time "$startTime" for week ${i + 1}');
          continue;
        }
        
        if (weeklyTime.isBefore(DateTime.now())) {
          _logger.info('Skipping past weekly comeback notification for week ${i + 1}');
          continue;
        }

        final id = _buildId(_fmtDate(weeklyDate), 'comeback_weekly_${i + 1}');
        
        // Create payload data
        final payloadData = {
          'type': 'comeBack',
          'slot': 'weekly_${i + 1}',
          'taskDate': _fmtDate(weeklyDate),
          'scheduledDate': weeklyTime.toIso8601String(),
        };
        
        final payload = json.encode(payloadData);

        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationConfig.channelId,
            NotificationConfig.channelName,
            channelDescription: NotificationConfig.channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        // Resolve comeback notification text using semantic content
        const fallbackTitle = 'Check back in';
        const fallbackBody = 'It\'s a great day to restart.';
        final resolvedText = await _getNotificationText('app.remind.comeback', fallbackBody);
        final resolvedTitle = fallbackTitle; // Keep original title for now
        final resolvedBody = resolvedText;

        await _notifications.zonedSchedule(
          id,
          resolvedTitle,
          resolvedBody,
          tz.TZDateTime.from(weeklyTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        
        _logger.info('Scheduled weekly comeback notification ${i + 1} ID:$id for ${_fmtDate(weeklyDate)}');
      }
    } catch (e) {
      _logger.error('Failed scheduling weekly comeback notifications: $e');
    }
  }

  List<double> _fractionsForIntensity(int intensity) {
    switch (intensity) {
      case 1:
        return [0.5];
      case 2:
        return [1 / 3, 2 / 3];
      case 3:
      default:
        return [0.25, 0.5, 0.75];
    }
  }

  /// Calculate available notification budget after accounting for comeback notifications
  int _calculateNotificationBudget() {
    final dailyComebackCount = NotificationConfig.defaultDailyComebackCount;
    final weeklyComebackCount = NotificationConfig.defaultWeeklyComebackCount;
    final totalComebackNotifications = dailyComebackCount + weeklyComebackCount;
    return NotificationConfig.maxIOSNotifications - totalComebackNotifications;
  }

  /// Calculate the reference window duration for notification distribution.
  /// 
  /// **Logic**: 
  /// - Windows ≤4 hours: Use 4-hour reference (240 minutes) for consistent frequency
  /// - Windows ≥5 hours: Use actual window duration
  /// 
  /// This ensures short windows maintain the same notification frequency as the 
  /// beginning portion of a 4-hour window, preventing compressed/rushed scheduling.
  /// 
  /// [windowHours] The actual notification window duration in hours
  /// Returns reference window duration in minutes for fraction-to-time conversion
  int _calculateReferenceWindowMinutes(int windowHours) {
    return windowHours <= NotificationConfig.minTimeWindowHours ? NotificationConfig.minTimeWindowHours * 60 : windowHours * 60;
  }

  /// Check if a window should use the 4-hour reference pattern.
  /// 
  /// Returns true for windows ≤4 hours, false for longer windows.
  /// Used for conditional logic and logging throughout the scheduling system.
  bool _usesFourHourReference(int windowHours) {
    return windowHours <= NotificationConfig.minTimeWindowHours;
  }

  /// Format DateTime to HH:MM string for consistent time logging.
  /// 
  /// Provides uniform time formatting across all notification logging,
  /// ensuring consistent display format (e.g., "09:05" not "9:5").
  String _formatNotificationTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Generate quadratic distribution for notifications with smart window handling.
  /// 
  /// This method creates a quadratic distribution of notification times that:
  /// - Places more notifications early in the time window (higher density)
  /// - Places fewer notifications toward the deadline (lower density)
  /// - Uses a 4-hour reference pattern for windows ≤4 hours to maintain consistent frequency
  /// - Uses actual window duration for longer windows (≥5 hours)
  /// 
  /// **Quadratic Formula**: Each notification position is transformed using x² where x is the
  /// uniform position (0-1). This creates smaller gaps early and larger gaps later.
  /// 
  /// **Window Strategy**:
  /// - Short windows (≤4h): Generate using 4-hour reference, filter during scheduling
  /// - Long windows (≥5h): Generate for actual window duration
  /// 
  /// **Example**: 2-hour window gets same early frequency as first 2 hours of 4-hour window
  /// 
  /// [notificationCount] Number of notifications to distribute
  /// [windowHours] Duration of the notification window in hours
  /// Returns list of fractions (0.0-1.0) representing positions within reference window
  List<double> _generateQuadraticDistribution(int notificationCount, int windowHours) {
    _logger.info('Generating quadratic distribution: $notificationCount notifications for ${windowHours}h window');
    
    if (notificationCount <= 1) {
      _logger.info('NotificationCount <= 1, returning [0.5]');
      return [0.5];
    }
    
    final fractions = <double>[];
    
    // Determine which window duration to use for generation
    final generationWindowHours = windowHours <= NotificationConfig.minTimeWindowHours ? NotificationConfig.minTimeWindowHours : windowHours;
    _logger.info('Using $generationWindowHours hours for quadratic generation (actual window: $windowHours hours)');
    
    // Use quadratic formula to create decreasing density (more notifications early, fewer later)
    // We want smaller intervals early (more frequent) and larger intervals later (less frequent)
    
    for (int i = 0; i < notificationCount; i++) {
      // Calculate uniform position from 0 to 1 (0 = start, 1 = deadline)
      // Using (i+1)/(n+1) ensures no notifications exactly at start/end boundaries
      final uniformPosition = (i + 1) / (notificationCount + 1);
      
      // Apply quadratic transformation for decreasing density over time
      // Formula: f(x) = x² where x ∈ [0,1]
      // 
      // Mathematical effect:
      // - Early positions (x < 0.5) become even earlier (x² < x)
      // - Later positions (x > 0.7) become much later (x² >> x)
      // - Creates exponentially increasing gaps between notifications
      // 
      // Example with 4 notifications:
      // Uniform:   [0.20, 0.40, 0.60, 0.80]
      // Quadratic: [0.04, 0.16, 0.36, 0.64] → More notifications in first half
      final transformedPosition = uniformPosition * uniformPosition;
      
      fractions.add(transformedPosition);
    }
    
    _logger.info('Generated ${fractions.length} quadratic fractions');
    
    // For shorter windows (<=4 hours), we use the 4-hour reference pattern and filter during scheduling
    // For longer windows (>4 hours), we use the actual window distribution
    _logger.info('Using ${_usesFourHourReference(windowHours) ? '4h reference' : 'actual window'} distribution');
    return fractions;
  }

  /// Get notification count for given intensity level and available budget
  int _getNotificationCountForIntensity(int intensity, int availableBudget, int daysCount) {
    final budgetPerDay = availableBudget ~/ daysCount;
    
    _logger.info('=== NOTIFICATION COUNT CALCULATION ===');
    _logger.info('Total available budget: $availableBudget');
    _logger.info('Days count: $daysCount');
    _logger.info('Budget per day: $budgetPerDay');
    _logger.info('Intensity level: $intensity');
    
    int midNotificationCount;
    switch (intensity) {
      case 1:
        // Level 1: 3 total (start + 1 mid + deadline)
        midNotificationCount = (budgetPerDay >= 3) ? 1 : 0; // 1 mid notification
        _logger.info('Level 1: Using $midNotificationCount mid notification');
        break;
      case 2:
        // Level 2: Half of level 3 capacity
        final level3Count = _calculateLevel3NotificationCount(budgetPerDay);
        midNotificationCount = level3Count ~/ 2;
        _logger.info('Level 2: Level 3 would be $level3Count, using half = $midNotificationCount');
        break;
      case 3:
      default:
        // Level 3: Use all available capacity
        midNotificationCount = _calculateLevel3NotificationCount(budgetPerDay);
        _logger.info('Level 3: Using all available capacity = $midNotificationCount mid notifications');
        break;
    }
    
    final totalPerDay = midNotificationCount + 2; // +2 for start and deadline
    _logger.info('Total notifications per day: $totalPerDay ($midNotificationCount mid + 1 start + 1 deadline)');
    
    return midNotificationCount;
  }
  
  int _calculateLevel3NotificationCount(int budgetPerDay) {
    // Reserve 2 slots for start and deadline notifications
    final availableForMid = budgetPerDay - 2;
    final result = availableForMid > 0 ? availableForMid : 0;
    _logger.info('Level 3 calculation: $budgetPerDay budget - 2 reserved = $availableForMid available for mid = $result');
    return result;
  }

  Future<int> _scheduleSlot(
    String taskDate,
    String slot,
    DateTime whenLocal,
    {required String title, required String body}
  ) async {
    try {
      final id = _buildId(taskDate, slot);
      
      _logger.info('=== _scheduleSlot DEBUG ===');
      _logger.info('Scheduling slot: $slot for date: $taskDate');
      _logger.info('Notification ID: $id');
      _logger.info('Scheduled time: ${whenLocal.hour}:${whenLocal.minute.toString().padLeft(2, '0')} on ${whenLocal.day}/${whenLocal.month}');
      
      // Resolve notification text using semantic content based on slot type
      String semanticKey;
      if (slot == 'start') {
        semanticKey = 'app.remind.start';
      } else if (slot.startsWith('mid')) {
        semanticKey = 'app.remind.progress';
      } else if (slot == 'deadline') {
        semanticKey = 'app.remind.deadline';
      } else if (slot.startsWith('comeback')) {
        semanticKey = 'app.remind.comeback';
      } else {
        semanticKey = 'app.remind.generic';
      }
      
      _logger.info('Using semantic key: $semanticKey');
      
      // Resolve notification text using semantic content (use same key for both title and body)
      final resolvedText = await _getNotificationText(semanticKey, body);
      final resolvedTitle = title; // Keep original title for now
      final resolvedBody = resolvedText;
      
      _logger.info('Resolved title: "$resolvedTitle"');
      _logger.info('Resolved body: "$resolvedBody"');
      
      // Create payload data
      final payloadData = {
        'type': slot == 'deadline' ? 'dailyReminder' : 'dailyNudge',
        'slot': slot,
        'taskDate': taskDate,
        'scheduledDate': whenLocal.toIso8601String(),
      };
      
      final payload = json.encode(payloadData);

      _logger.info('Scheduling notification: ID:$id slot:$slot date:$taskDate time:${whenLocal.toString().substring(11, 16)} title:"$resolvedTitle"');
      _logger.info('Notification payload: $payload');
      _logger.info('Payload data structure: $payloadData');

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationConfig.channelId,
          NotificationConfig.channelName,
          channelDescription: NotificationConfig.channelDescription,
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
        id,
        resolvedTitle,
        resolvedBody,
        tz.TZDateTime.from(whenLocal, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      _logger.info('Successfully scheduled notification ID:$id for $taskDate/$slot');
      
      // Immediately check if the notification appears in pending requests (debug)
      try {
        final pending = await _notifications.pendingNotificationRequests();
        final found = pending.any((req) => req.id == id);
        _logger.debug('Notification ID:$id immediate pending check: ${found ? "FOUND" : "NOT FOUND"} (${pending.length} total pending)');
      } catch (e) {
        _logger.debug('Failed to check immediate pending status for ID:$id: $e');
      }
      
      return 1;
    } catch (e) {
      _logger.error('Failed to schedule notification ID:${_buildId(taskDate, slot)} ($taskDate/$slot): $e');
      return 0;
    }
  }


  /// Generate a notification ID based on date and slot
  int _buildId(String dateStr, String slot) {
    // Validate date string format
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      _logger.warning('Invalid date format for ID generation: $dateStr, using fallback');
      dateStr = DateTime.now().toIso8601String().substring(0, 10);
    }
    
    final base = int.tryParse(dateStr.replaceAll('-', '')) ?? 0;
    
    final code = () {
      if (slot == 'start') return 1;
      if (slot.startsWith('mid')) {
        final raw = int.tryParse(slot.substring(3)) ?? 1;
        final idx = raw < 1 ? 1 : raw; // Remove the upper limit to prevent collisions
        return 100 + idx; // 101, 102, 103, etc.
      }
      if (slot == 'deadline') return 2; // Keep simple
      if (slot.startsWith('comeback')) return 3; // series
      if (slot == 'comeback_weekly') return 4; // weekly fallback
      return 5; // default
    }();
    
    // Validate that base doesn't overflow when multiplied by 1000
    if (base > 2147483) { // Int32 max / 1000
      _logger.warning('Date base too large for ID generation: $base, using modulo');
      // Use modulo to keep within safe range
      final safeBase = base % 100000; // Keep last 5 digits to fit in Int32 when multiplied by 1000
      _logger.info('Using safe base: $safeBase for date: $dateStr');
      final finalId = safeBase * 1000 + code;
      return finalId;
    }
    
    final finalId = base * 1000 + code; // Use 1000 multiplier to have room for larger codes
    
    // Validate final ID is positive and not too large
    if (finalId <= 0) {
      _logger.error('Generated invalid notification ID: $finalId for $dateStr/$slot');
      // Generate a fallback ID using current timestamp
      final fallbackId = DateTime.now().millisecondsSinceEpoch.abs() % 2147483647 + code;
      _logger.warning('Using fallback ID: $fallbackId for $dateStr/$slot');
      return fallbackId;
    }
    
    return finalId;
  }


  
  /// Cancel a notification with retry mechanism and verification
  /// Uses exponential backoff and verifies cancellation was successful
  Future<bool> _cancelNotificationWithRetry(
    int notificationId, {
    int maxRetries = 3,
    String? reason,
  }) async {
    const baseDelayMs = 100; // Start with 100ms delay
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        
        // Attempt to cancel the notification
        await _notifications.cancel(notificationId);
        
        // Brief delay to allow cancellation to process
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Verify cancellation was successful
        final pendingNotifications = await getPendingNotifications();
        final stillExists = pendingNotifications.any((n) => n.id == notificationId);
        
        if (!stillExists) {
          // Success!
          if (attempt > 1) {
            _logger.info('Notification ID:$notificationId canceled successfully on attempt $attempt${reason != null ? " - $reason" : ""}');
          } else {
            _logger.info('Canceled notification ID:$notificationId${reason != null ? " - $reason" : ""}');
          }
          return true;
        }
        
        // Cancellation didn't work, log and potentially retry
        if (attempt < maxRetries) {
          final delay = baseDelayMs * (1 << (attempt - 1)); // Exponential backoff: 100, 200, 400ms
          _logger.warning('Notification ID:$notificationId still exists after cancel attempt $attempt, retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          _logger.error('Notification ID:$notificationId still exists after $maxRetries cancel attempts');
        }
        
      } catch (e) {
        if (attempt < maxRetries) {
          final delay = baseDelayMs * (1 << (attempt - 1));
          _logger.warning('Cancel attempt $attempt failed for notification ID:$notificationId: $e, retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          _logger.error('All cancel attempts failed for notification ID:$notificationId: $e');
        }
      }
    }
    
    return false; // All attempts failed
  }
  

  String _todayDateString() => _fmtDate(DateTime.now());
  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Resolve notification text using semantic content service
  /// Falls back to provided fallback text if semantic resolution fails
  Future<String> _getNotificationText(String semanticKey, String fallbackText) async {
    try {
      final resolvedText = await _semanticContentService.getContent(semanticKey, fallbackText, randomize: true);
      _logger.info('Resolved notification text for key "$semanticKey": "$resolvedText"');
      return resolvedText;
    } catch (e) {
      _logger.warning('Failed to resolve semantic key "$semanticKey", using fallback: $e');
      return fallbackText;
    }
  }

  /// Validates time format without throwing exceptions
  bool _isValidTimeFormat(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return false;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      if (hour == null || minute == null) return false;
      if (hour < 0 || hour > 23) return false;
      if (minute < 0 || minute > 59) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  DateTime? _composeLocal(DateTime day, String hhmm) {
    try {
      final p = hhmm.split(':');
      if (p.length != 2) {
        _logger.warning('Invalid time format "$hhmm": expected HH:MM format');
        return null;
      }
      
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      
      if (h == null || m == null) {
        _logger.warning('Invalid time format "$hhmm": non-numeric hour or minute');
        return null;
      }
      
      if (h < 0 || h > 23 || m < 0 || m > 59) {
        _logger.warning('Invalid time format "$hhmm": hour must be 0-23, minute must be 0-59');
        return null;
      }
      
      return DateTime(day.year, day.month, day.day, h, m);
    } catch (e) {
      _logger.warning('Failed to parse time "$hhmm" for date ${day.toString().substring(0, 10)}: $e');
      return null;
    }
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _cancelBeforeTaskDate(String cutoffDate) async {
    try {
      final pending = await getPendingNotifications();
      int canceledCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      
      _logger.info('Starting cleanup: found ${pending.length} pending notifications, cutoff date: $cutoffDate');
      
      for (final p in pending) {
        final payload = p.payload;
        if (payload == null || payload.isEmpty) {
          skippedCount++;
          continue;
        }
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          final taskDate = data['taskDate'] as String?;
          if (taskDate != null && taskDate.compareTo(cutoffDate) < 0) {
            final success = await _cancelNotificationWithRetry(
              p.id,
              reason: 'stale date: $taskDate (before cutoff: $cutoffDate)',
            );
            if (success) {
              canceledCount++;
            } else {
              errorCount++;
            }
          }
        } catch (e) {
          errorCount++;
          _logger.warning('Failed to process notification ID:${p.id} payload during cleanup: $e');
        }
      }
      
      _logger.info('Cleanup completed: canceled=$canceledCount, skipped=$skippedCount, errors=$errorCount');
    } catch (e) {
      _logger.error('Cancel-before sweep failed: $e');
    }
  }

  Future<void> _keepOnlyFinalForDate(String dateStr) async {
    try {
      final pending = await getPendingNotifications();
      int canceledCount = 0;
      int keptCount = 0;
      int errorCount = 0;
      
      _logger.info('Keeping only final notifications for date: $dateStr (found ${pending.length} pending)');
      
      for (final p in pending) {
        final payload = p.payload;
        if (payload == null || payload.isEmpty) continue;
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          if (data['taskDate'] == dateStr) {
            final slot = data['slot'] as String?;
            if (slot != 'deadline') {
              final success = await _cancelNotificationWithRetry(
                p.id,
                reason: 'non-final slot: $slot for date: $dateStr',
              );
              if (success) {
                canceledCount++;
              } else {
                errorCount++;
              }
            } else {
              keptCount++;
              _logger.info('Kept final notification ID:${p.id} slot:$slot for date:$dateStr');
            }
          }
        } catch (e) {
          errorCount++;
          _logger.warning('Failed to process notification ID:${p.id} payload in keep-final sweep: $e');
        }
      }
      
      _logger.info('Keep-final completed for $dateStr: canceled=$canceledCount, kept=$keptCount, errors=$errorCount');
    } catch (e) {
      _logger.error('Keep-final sweep failed: $e');
    }
  }

  // ACTIVE DAY helpers
  bool _isActiveDay(DateTime date) {
    try {
      // Use configured active days; default to Mon-Fri if unset
      // Accept both List and JSON string formats
      // Reusing parser approach as in ActiveDateCalculator
    } catch (_) {}
    return _activeDaysSet().contains(date.weekday);
  }

  Set<int> _activeDaysSet() {
    final raw = _activeDaysRawSync;
    final parsed = <int>{};
    if (raw == null) {
      // default: Mon-Fri
      return {1, 2, 3, 4, 5};
    }
    if (raw is List) {
      for (final e in raw) {
        final v = e is int ? e : int.tryParse(e.toString());
        if (v != null) parsed.add(v);
      }
      return parsed.isEmpty ? {1, 2, 3, 4, 5} : parsed;
    }
    if (raw is String && raw.trim().startsWith('[')) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            final v = e is int ? e : int.tryParse(e.toString());
            if (v != null) parsed.add(v);
          }
          return parsed.isEmpty ? {1, 2, 3, 4, 5} : parsed;
        }
      } catch (_) {}
    }
    return {1, 2, 3, 4, 5};
  }

  dynamic get _activeDaysRawSync => _activeDaysCache;
  dynamic _activeDaysCache;

  DateTime _nextActiveDateAfter(DateTime date) {
    var d = date.add(const Duration(days: 1));
    for (int i = 0; i < 370; i++) {
      if (_isActiveDay(d)) return d;
      d = d.add(const Duration(days: 1));
    }
    return date.add(const Duration(days: 1));
  }

  Future<void> _primeActiveDaysCache() async {
    _activeDaysCache = await _userDataService.getValue<dynamic>(
      StorageKeys.taskActiveDays,
    );
  }

  Future<String> _getStartTimeAsString() async {
    final s = await _userDataService.getValue<String>(
      StorageKeys.taskStartTime,
    );
    if (s != null) {
      if (s.contains(':')) return s;
      final asInt = int.tryParse(s);
      if (asInt != null) return _convertIntegerToTimeString(asInt);
    }
    final i = await _userDataService.getValue<int>(StorageKeys.taskStartTime);
    if (i != null) return _convertIntegerToTimeString(i);
    return SessionConstants.defaultStartTime;
  }

  Future<String> _getDeadlineTimeAsString() async {
    final s = await _userDataService.getValue<String>(
      StorageKeys.taskDeadlineTime,
    );
    if (s != null) {
      if (s.contains(':')) return s;
      final asInt = int.tryParse(s);
      if (asInt != null) return _convertIntegerToTimeString(asInt);
    }
    final i = await _userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
    if (i != null) return _convertIntegerToTimeString(i);
    return SessionConstants.defaultDeadlineTime;
  }

  // No deadline-based default start time mapping anymore.

  String _convertIntegerToTimeString(int hour) {
    // Handle special "end of day" case
    if (hour == 24) {
      return '23:59';
    }
    
    // Handle direct hour values (0-23)
    if (hour >= 0 && hour <= 23) {
      return '${hour.toString().padLeft(2, '0')}:00';
    }
    
    // Fallback to default for invalid values
    return SessionConstants.defaultDeadlineTime;
  }

  Future<void> cancelAllNotifications() async {
    _logger.info('=== CANCELING ALL NOTIFICATIONS ===');

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification cancellation');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      // Check how many notifications we're about to cancel
      final pendingBefore = await getPendingNotifications();
      _logger.info('Found ${pendingBefore.length} pending notifications to cancel');
      
      await _notifications.cancelAll();
      
      // Verify cancellation was successful
      final pendingAfter = await getPendingNotifications();
      final actualCanceled = pendingBefore.length - pendingAfter.length;
      
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
      
      _logger.info('All notifications canceled successfully: $actualCanceled removed, ${pendingAfter.length} remaining');
      
      // Log any remaining notifications as potential issues
      if (pendingAfter.isNotEmpty) {
        _logger.warning('${pendingAfter.length} notifications still pending after cancelAll() - this may indicate platform issues');
        for (final remaining in pendingAfter) {
          _logger.warning('Remaining notification ID:${remaining.id} title:"${remaining.title}"');
        }
      }
    } catch (e) {
      _logger.error('Failed to cancel notifications: $e');
      // Still mark as disabled even if cancellation fails
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
    }
  }

  Future<void> cancelDeadlineReminder() async {
    _logger.info('=== CANCELING DEADLINE REMINDER ===');

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification cancellation');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      // Check if the specific deadline reminder exists
      final pendingBefore = await getPendingNotifications();
      final deadlineReminder = pendingBefore.where((n) => n.id == NotificationConfig.dailyReminderNotificationId).firstOrNull;
      
      if (deadlineReminder != null) {
        _logger.info('Found deadline reminder notification ID:$NotificationConfig.dailyReminderNotificationId to cancel');
      } else {
        _logger.info('No deadline reminder notification found with ID:$NotificationConfig.dailyReminderNotificationId');
      }
      
      await _notifications.cancel(NotificationConfig.dailyReminderNotificationId);
      
      // Verify specific cancellation
      final pendingAfter = await getPendingNotifications();
      final stillExists = pendingAfter.any((n) => n.id == NotificationConfig.dailyReminderNotificationId);
      
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
      
      if (!stillExists && deadlineReminder != null) {
        _logger.info('Deadline reminder canceled successfully (ID:$NotificationConfig.dailyReminderNotificationId)');
      } else if (stillExists) {
        _logger.warning('Deadline reminder ID:$NotificationConfig.dailyReminderNotificationId still exists after cancellation - platform may not have processed the request');
      } else {
        _logger.info('Deadline reminder cancellation completed (notification was not found)');
      }
    } catch (e) {
      _logger.error('Failed to cancel deadline reminder: $e');
      // Still mark as disabled even if cancellation fails
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (_isTestEnvironment()) {
      _logger.info('Test environment - returning empty pending notifications');
      return [];
    }
    
    try {
      final pendingRequests = await _notifications.pendingNotificationRequests();
      _logger.debug('Platform returned ${pendingRequests.length} pending notifications');
      
      // Group by type for detailed logging
      final byType = <String, int>{};
      for (final req in pendingRequests) {
        String type = 'unknown';
        try {
          if (req.payload != null && req.payload!.isNotEmpty) {
            final data = json.decode(req.payload!) as Map<String, dynamic>;
            final slot = data['slot'] as String?;
            if (slot != null) {
              if (slot == 'start') {
                type = 'start';
              } else if (slot.startsWith('mid')) {
                type = 'mid';
              } else if (slot == 'deadline') {
                type = 'deadline';
              } else if (slot.startsWith('comeback') || slot.startsWith('weekly_')) {
                type = 'comeback';
              } else {
                type = slot;
              }
            }
          }
        } catch (_) {}
        byType[type] = (byType[type] ?? 0) + 1;
      }
      
      _logger.debug('Platform pending notifications by type: $byType');
      
      return pendingRequests;
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
    _logger.info(
      'Notification tapped: ID=${response.id}, payload=${response.payload}',
    );
    _logger.info('Response details: actionId=${response.actionId}, input=${response.input}, data=${response.data}');
    _logger.info('Platform: ${Platform.operatingSystem}');

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

  /// Check if the app was launched from a notification tap
  /// This handles the case when the app is not running and user taps a notification
  Future<void> _checkAppLaunchFromNotification() async {
    try {
      _logger.info('Checking if app was launched from notification...');
      
      final launchDetails = await _notifications.getNotificationAppLaunchDetails();
      
      if (launchDetails == null) {
        _logger.info('No notification app launch details available');
        return;
      }
      
      _logger.info('App launch details: didNotificationLaunchApp=${launchDetails.didNotificationLaunchApp}');
      
      if (launchDetails.didNotificationLaunchApp) {
        final response = launchDetails.notificationResponse;
        if (response != null) {
          _logger.info('App launched from notification: ID=${response.id}, payload=${response.payload}');
          _logger.info('Launch response details: actionId=${response.actionId}, input=${response.input}, data=${response.data}');
          _logger.info('Platform: ${Platform.operatingSystem}');
          
          // Create notification tap event for app launch
          final tapEvent = NotificationTapEvent.fromResponse(
            response.id ?? 0,
            response.payload,
            response.actionId,
            response.input,
            response.data,
          );
          
          _logger.info('Created NotificationTapEvent from app launch: $tapEvent');
          
          // Track the event using AppStateService if available
          if (_appStateService != null) {
            await _appStateService!.handleNotificationTap(tapEvent);
            _logger.info('App launch notification tap event tracked by AppStateService');
          } else {
            _logger.warning('AppStateService not set - cannot track app launch tap event');
          }
          
          // Fire callback if set (for backward compatibility)
          if (_onNotificationTap != null) {
            _onNotificationTap!(tapEvent);
            _logger.info('App launch notification tap event fired to callback');
          }
        } else {
          _logger.warning('App launched from notification but no response details available');
        }
      } else {
        _logger.info('App was not launched from a notification');
      }
    } catch (e) {
      _logger.error('Failed to check app launch from notification: $e');
      // Don't rethrow - this is not critical for app functionality
    }
  }

  /// Get platform version information for compatibility checks
  Map<String, dynamic> _getPlatformVersionInfo() {
    try {
      final info = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      };
      
      // Parse version numbers for compatibility checks
      if (Platform.isAndroid) {
        // Android version string format: "Android 13 (API level 33)"
        final versionMatch = RegExp(r'Android (\d+)').firstMatch(Platform.operatingSystemVersion);
        if (versionMatch != null) {
          final androidVersion = int.tryParse(versionMatch.group(1) ?? '') ?? 0;
          info['majorVersion'] = androidVersion;
          info['requiresNotificationPermission'] = androidVersion >= 13;
          info['requiresExactAlarmPermission'] = androidVersion >= 12;
          info['supportsNotificationChannels'] = androidVersion >= 8;
        }
      } else if (Platform.isIOS) {
        // iOS version string format varies, but try to extract version
        final versionMatch = RegExp(r'(\d+)\.(\d+)\.?(\d*)').firstMatch(Platform.operatingSystemVersion);
        if (versionMatch != null) {
          final majorVersion = int.tryParse(versionMatch.group(1) ?? '') ?? 0;
          final minorVersion = int.tryParse(versionMatch.group(2) ?? '') ?? 0;
          info['majorVersion'] = majorVersion;
          info['minorVersion'] = minorVersion;
          info['supportsProvisionalAuthorization'] = majorVersion >= 12;
          info['supportsNotificationSummary'] = majorVersion >= 15;
          info['hasFocusModes'] = majorVersion >= 15;
        }
      }
      
      return info;
    } catch (e) {
      _logger.warning('Failed to get platform version info: $e');
      return {
        'platform': Platform.operatingSystem,
        'version': 'unknown',
        'majorVersion': 0,
      };
    }
  }

  /// Check if current platform version supports exact alarm scheduling
  bool _supportsExactAlarms() {
    if (!Platform.isAndroid) return true; // iOS always supports exact scheduling
    
    final versionInfo = _getPlatformVersionInfo();
    final androidVersion = versionInfo['majorVersion'] as int? ?? 0;
    
    // Android 12+ may require special permission for exact alarms
    if (androidVersion >= 12) {
      _logger.info('Android $androidVersion detected - exact alarms may require special permission');
      return true; // We'll attempt scheduling and handle failures gracefully
    }
    
    return true;
  }

  /// Check if current platform version requires explicit notification permissions
  bool _requiresNotificationPermission() {
    if (Platform.isIOS) return true; // iOS always requires permission
    
    if (Platform.isAndroid) {
      final versionInfo = _getPlatformVersionInfo();
      final androidVersion = versionInfo['majorVersion'] as int? ?? 0;
      
      // Android 13+ requires explicit notification permission
      return androidVersion >= 13;
    }
    
    return false; // Other platforms
  }

  /// Get platform-specific notification limitations and recommendations
  List<String> _getPlatformLimitations() {
    final limitations = <String>[];
    final versionInfo = _getPlatformVersionInfo();
    
    if (Platform.isIOS) {
      final majorVersion = versionInfo['majorVersion'] as int? ?? 0;
      
      limitations.add('iOS limits apps to 64 scheduled notifications');
      limitations.add('Notifications may be delayed in Low Power Mode');
      
      if (majorVersion >= 15) {
        limitations.add('Focus Modes may block notifications');
        limitations.add('Notification summaries may group messages');
      }
      
      if (_isIOSSimulator()) {
        limitations.add('iOS Simulator may not display notifications reliably');
      }
    } else if (Platform.isAndroid) {
      final androidVersion = versionInfo['majorVersion'] as int? ?? 0;
      
      if (androidVersion >= 13) {
        limitations.add('Android 13+ requires explicit notification permission');
      }
      
      if (androidVersion >= 12) {
        limitations.add('Android 12+ may require special permission for exact alarms');
      }
      
      limitations.add('Battery optimization settings may affect notification delivery');
      limitations.add('Do Not Disturb mode may block notifications');
      limitations.add('Some devices have aggressive battery management');
    }
    
    return limitations;
  }

  /// Detect if running on iOS simulator
  bool _isIOSSimulator() {
    try {
      if (!Platform.isIOS) return false;
      
      // Check if running on simulator architecture
      // iOS Simulator runs on x86_64 (Intel Macs) or arm64 (Apple Silicon Macs)
      // but the target architecture is always iOS simulator-specific
      
      // Method 1: Check environment variables that are set in iOS Simulator
      const simulatorEnvVars = [
        'SIMULATOR_DEVICE_NAME',
        'SIMULATOR_ROOT',
        'SIMULATOR_UDID',
        'SIMULATOR_RUNTIME_VERSION'
      ];
      
      for (final envVar in simulatorEnvVars) {
        final value = Platform.environment[envVar];
        if (value != null && value.isNotEmpty) {
          _logger.info('iOS Simulator detected via environment variable: $envVar');
          return true;
        }
      }
      
      // Method 2: Check if we can access simulator-specific paths
      // This is a fallback method, less reliable but still useful
      try {
        // Simulator typically runs from paths containing 'CoreSimulator'
        final executablePath = Platform.resolvedExecutable;
        if (executablePath.contains('CoreSimulator') || 
            executablePath.contains('Simulator')) {
          _logger.info('iOS Simulator detected via executable path analysis');
          return true;
        }
      } catch (_) {
        // Ignore path analysis failures
      }
      
      // Method 3: Platform environment check (least reliable, kept as last resort)
      // Some CI/testing environments might not have the env vars
      if (Platform.environment['FLUTTER_TEST'] == 'true') {
        // If we're in a test environment, assume real device for safety
        _logger.info('Test environment detected, assuming real iOS device');
        return false;
      }
      
      // If none of the above methods detect simulator, assume real device
      _logger.info('iOS device detection: Real device (no simulator indicators found)');
      return false;
      
    } catch (e) {
      _logger.warning('Error during iOS simulator detection: $e, assuming real device');
      return false; // Default to real device for safety
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
        final weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
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
          return minutes > 0
              ? 'in $hours hours, $minutes min'
              : 'in $hours hours';
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
      final isEnabled =
          await _userDataService.getValue<bool>(
            StorageKeys.notificationIsEnabled,
          ) ??
          false;
      final lastScheduled = await _userDataService.getValue<String>(
        StorageKeys.notificationLastScheduled,
      );
      final remindersIntensity =
          await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      final deadlineTime = await _userDataService.getValue<String>(
        StorageKeys.taskDeadlineTime,
      );
      final startTime = await _userDataService.getValue<String>(
        StorageKeys.taskStartTime,
      );
      final currentDate = await _userDataService.getValue<String>(
        StorageKeys.taskCurrentDate,
      );
      final endDate = await _userDataService.getValue<String>(
        StorageKeys.taskEndDate,
      );
      final activeDays = await _userDataService.getValue<dynamic>(
        StorageKeys.taskActiveDays,
      );

      // Get current pending notifications with detailed info
      final pendingNotifications = await getPendingNotifications();
      final pendingCount = pendingNotifications.length;
      
      // Analyze pending notifications by type and date
      final notificationBreakdown = <String, dynamic>{};
      final dateBreakdown = <String, int>{};
      final slotBreakdown = <String, int>{};
      
      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload!.isNotEmpty) {
          try {
            final data = json.decode(notification.payload!) as Map<String, dynamic>;
            final type = data['type'] as String? ?? 'unknown';
            final slot = data['slot'] as String? ?? 'unknown';
            final taskDate = data['taskDate'] as String? ?? 'unknown';
            
            notificationBreakdown[type] = (notificationBreakdown[type] ?? 0) + 1;
            dateBreakdown[taskDate] = (dateBreakdown[taskDate] ?? 0) + 1;
            slotBreakdown[slot] = (slotBreakdown[slot] ?? 0) + 1;
          } catch (_) {
            notificationBreakdown['invalid-payload'] = (notificationBreakdown['invalid-payload'] ?? 0) + 1;
          }
        } else {
          notificationBreakdown['no-payload'] = (notificationBreakdown['no-payload'] ?? 0) + 1;
        }
      }

      // Get fallback information
      final fallbackDate = await _userDataService.getValue<String>(
        '${StorageKeys.notificationPrefix}fallbackDate',
      );
      final fallbackReason = await _userDataService.getValue<String>(
        '${StorageKeys.notificationPrefix}fallbackReason',
      );

      // Get permission tracking info
      final permissionRequestCount = await _userDataService.getValue<int>(
        StorageKeys.notificationPermissionRequestCount,
      ) ?? 0;
      final lastPermissionRequest = await _userDataService.getValue<String>(
        StorageKeys.notificationPermissionLastRequested,
      );
      final storedPermissionStatus = await _userDataService.getValue<String>(
        StorageKeys.notificationPermissionStatus,
      );

      // Add timezone information with validation
      String timezoneInfo = 'Unknown';
      String currentTime = 'Unknown';
      bool timezoneValid = false;
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        timezoneInfo = currentZone.name;
        currentTime = now.toString();
        timezoneValid = true;
      } catch (e) {
        timezoneInfo = 'Error: $e';
      }

      // Enhanced platform detection
      String platformInfo = Platform.operatingSystem;
      if (Platform.isIOS && _isIOSSimulator()) {
        platformInfo += ' (Simulator - notifications may not work)';
      } else if (Platform.isIOS) {
        platformInfo += ' (Real device)';
      }

      // Service health check
      final serviceHealthy = _appStateService != null && ServiceLocator.instance.isInitialized;

      return {
        'isEnabled': isEnabled,
        'lastScheduled': lastScheduled,
        'remindersIntensity': remindersIntensity,
        'deadlineTime': deadlineTime,
        'startTime': startTime,
        'currentDate': currentDate,
        'endDate': endDate,
        'activeDays': activeDays?.toString(),
        'pendingCount': pendingCount,
        'notificationTypes': notificationBreakdown,
        'notificationDates': dateBreakdown,
        'notificationSlots': slotBreakdown,
        'timezone': timezoneInfo,
        'timezoneValid': timezoneValid,
        'currentTime': currentTime,
        'platform': platformInfo,
        'isIOSSimulator': Platform.isIOS ? _isIOSSimulator() : false,
        'fallbackDate': fallbackDate,
        'fallbackReason': fallbackReason,
        'permissionRequestCount': permissionRequestCount,
        'lastPermissionRequest': lastPermissionRequest,
        'storedPermissionStatus': storedPermissionStatus,
        'serviceHealthy': serviceHealthy,
        'appStateServiceConnected': _appStateService != null,
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
      _logger.debug('getScheduledNotificationDetails: Converting ${pending.length} platform notifications to debug format');
      
      return pending.map((notification) {
        String scheduledTime = 'Unknown';
        String? timeUntil;
        String type = 'Task reminder';
        try {
          final payload = notification.payload;
          if (payload != null && payload.isNotEmpty) {
            final data = json.decode(payload) as Map<String, dynamic>;
            final schedStr = data['scheduledDate'] as String?;
            final slot = data['slot'] as String?;
            final typeStr = data['type'] as String?;
            if (schedStr != null) {
              final dt = DateTime.parse(schedStr).toLocal();
              final fmt = _formatDateTime(dt);
              scheduledTime = fmt['formatted'] ?? 'Unknown';
              final now = DateTime.now();
              timeUntil = dt.isAfter(now) ? _formatDuration(dt.difference(now)) : 'passed';
            }
            if (slot != null) {
              if (slot == 'start') {
                type = 'Start nudge';
              } else if (slot.startsWith('mid')) {
                type = 'Mid reminder';
              } else if (slot == 'deadline') {
                type = 'Deadline check';
              } else if (slot.startsWith('comeback') || slot.startsWith('weekly_')) {
                type = 'Come back';
              }
            } else if (typeStr != null) {
              type = typeStr;
            }
          }
        } catch (_) {}

        return {
          'id': notification.id,
          'title': notification.title ?? 'No title',
          'body': notification.body ?? 'No body',
          'payload': notification.payload ?? 'No payload',
          'scheduledTime': scheduledTime,
          if (timeUntil != null) 'timeUntil': timeUntil,
          'type': type,
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
      final versionInfo = _getPlatformVersionInfo();
      final limitations = _getPlatformLimitations();
      
      final info = {
        'platform': Platform.operatingSystem,
        'version': versionInfo['version'],
        'majorVersion': versionInfo['majorVersion'] ?? 0,
        'supportsScheduled': true,
        'supportsRepeating': true,
        'supportsExactAlarms': _supportsExactAlarms(),
        'requiresNotificationPermission': _requiresNotificationPermission(),
        'channelId': NotificationConfig.channelId,
        'channelName': NotificationConfig.channelName,
        'channelDescription': NotificationConfig.channelDescription,
        'dailyReminderNotificationId': NotificationConfig.dailyReminderNotificationId,
        'isTestEnvironment': _isTestEnvironment(),
        'platformLimitations': limitations,
      };

      // Add iOS-specific information
      if (Platform.isIOS) {
        final isSimulator = _isIOSSimulator();
        info['isIOSSimulator'] = isSimulator;
        info['simulatorLimitations'] =
            isSimulator
                ? 'Notifications may not work properly in iOS Simulator'
                : 'Running on real iOS device - full notification support';
        info['permissionNote'] =
            'Check iOS Settings > Notifications > Your App';
        info['platformSpecificNotes'] = [
          'iOS requires explicit permission requests',
          'Cannot check permission status without requesting',
          'Notifications may be delayed or not delivered in Low Power Mode',
        ];
      } else if (Platform.isAndroid) {
        info['permissionNote'] =
            'Check Android Settings > Apps > Your App > Notifications';
        info['platformSpecificNotes'] = [
          'Android 13+ requires notification permission',
          'Exact alarms may require special permission on Android 12+',
          'Battery optimization may affect notification delivery',
          'Do Not Disturb settings can block notifications',
        ];
        info['androidScheduleMode'] = 'exactAllowWhileIdle';
      } else {
        info['permissionNote'] = 'Platform-specific settings may apply';
        info['platformSpecificNotes'] = [
          'Notification behavior may vary on this platform',
        ];
      }

      // Add timezone information with detailed validation
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        info['timezone'] = currentZone.name;
        info['timezoneOffset'] = currentZone.timeZone(now.millisecondsSinceEpoch);
        info['timezoneStatus'] = 'OK';
        info['currentTZDateTime'] = now.toString();
        info['localDateTime'] = DateTime.now().toString();
      } catch (e) {
        info['timezone'] = 'Error';
        info['timezoneStatus'] = 'Failed: $e';
        info['timezoneError'] = e.toString();
      }

      // Add notification scheduling capability checks
      info['capabilities'] = {
        'canScheduleExact': Platform.isAndroid || Platform.isIOS,
        'canScheduleRepeating': Platform.isAndroid || Platform.isIOS,
        'canUsePayload': true,
        'canUseActions': Platform.isAndroid || Platform.isIOS,
        'maxScheduledNotifications': Platform.isIOS ? 64 : 'unlimited',
      };

      // Add service integration info
      info['serviceIntegration'] = {
        'serviceLocatorInitialized': ServiceLocator.instance.isInitialized,
        'appStateServiceConnected': _appStateService != null,
        'notificationServiceInitialized': true, // Since we're running this method
      };

      return info;
    } catch (e) {
      return {
        'platform': 'unknown', 
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate a hash of key scheduling parameters to detect when rescheduling is needed
  @visibleForTesting
  Future<String> _generateSchedulingHash() async {
    try {
      // Collect all parameters that affect notification scheduling
      final intensity = await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      final currentDate = (await _userDataService.getValue<String>(StorageKeys.taskCurrentDate) ?? '').trim();
      final startTime = (await _getStartTimeAsString()).trim();
      final deadlineTime = (await _getDeadlineTimeAsString()).trim(); 
      // Handle activeDays with flexible parsing (could be List<dynamic> or List<String>)
      List<String> activeDaysList = [];
      try {
        final rawActiveDays = await _userDataService.getValue('task.activeDays');
        if (rawActiveDays != null) {
          if (rawActiveDays is List) {
            // Convert any list to List<String>
            activeDaysList = rawActiveDays.map((e) => e.toString()).toList();
          } else if (rawActiveDays is String && rawActiveDays.isNotEmpty) {
            // Handle as string representation
            activeDaysList = [rawActiveDays];
          }
        }
      } catch (e) {
        _logger.warning('Failed to parse activeDays for hash generation: $e');
        activeDaysList = [];
      }
      
      // Sort active days for consistency and filter out empty/null values
      final sortedActiveDays = activeDaysList
          .where((day) => day.isNotEmpty)
          .map((day) => day.trim())
          .toList()..sort();
      
      // Create a stable hash input with normalized values
      final hashInput = [
        'intensity:$intensity',
        'currentDate:${currentDate.isEmpty ? 'none' : currentDate}',
        'startTime:${startTime.isEmpty ? 'default' : startTime}',
        'deadlineTime:${deadlineTime.isEmpty ? 'default' : deadlineTime}',
        'activeDays:${sortedActiveDays.isEmpty ? 'none' : sortedActiveDays.join(',')}',
      ].join('|');
      
      final hash = hashInput.hashCode.toString();
      
      // Debug logging for cache troubleshooting
      _logger.info('CACHE: Hash input: $hashInput');
      _logger.info('CACHE: Generated hash: $hash');
      
      return hash;
    } catch (e) {
      _logger.warning('Failed to generate scheduling hash: $e');
      // Return timestamp as fallback to force rescheduling on error
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
  
  /// Check if notifications need to be rescheduled based on parameter changes
  @visibleForTesting
  Future<bool> _shouldSkipScheduling() async {
    try {
      final currentHash = await _generateSchedulingHash();
      final now = DateTime.now();
      
      // Skip if hash hasn't changed and we scheduled recently (within last 3 minutes)
      if (_lastSchedulingHash == currentHash && _lastSchedulingTime != null) {
        final timeSinceLastScheduling = now.difference(_lastSchedulingTime!);
        if (timeSinceLastScheduling.inMinutes < 3) {
          _logger.info('CACHE: Skipping notification scheduling - no relevant changes detected (hash: ${currentHash.substring(0, 8)}..., last scheduled: ${timeSinceLastScheduling.inSeconds}s ago)');
          return true;
        } else {
          _logger.info('Hash unchanged but time window expired (${timeSinceLastScheduling.inMinutes}min), proceeding with scheduling');
        }
      } else {
        if (_lastSchedulingHash != null) {
          final oldHash = _lastSchedulingHash!.length > 8 ? _lastSchedulingHash!.substring(0, 8) : _lastSchedulingHash!;
          final newHash = currentHash.length > 8 ? currentHash.substring(0, 8) : currentHash;
          _logger.info('CACHE: Hash changed - Old: $oldHash, New: $newHash - proceeding with scheduling');
        } else {
          _logger.info('CACHE: First scheduling attempt - proceeding (hash: ${currentHash.substring(0, 8)}...)');
        }
      }
      
      return false; // Don't skip - we need to schedule
    } catch (e) {
      _logger.warning('Failed to check scheduling cache: $e - proceeding with scheduling');
      return false;
    }
  }
  
  /// Update the scheduling cache after successful scheduling
  @visibleForTesting
  void _updateSchedulingCache(String hash) {
    _lastSchedulingHash = hash;
    _lastSchedulingTime = DateTime.now();
    _logger.info('CACHE: Updated scheduling cache with hash: ${hash.substring(0, 8)}...');
  }
  
  /// Clear scheduling cache (useful for debugging or manual refresh)
  void clearSchedulingCache() {
    _lastSchedulingHash = null;
    _lastSchedulingTime = null;
    _logger.info('Notification scheduling cache cleared');
  }
}
