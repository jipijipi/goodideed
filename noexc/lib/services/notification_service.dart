import 'dart:io';
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

  // App state service for tracking notification taps
  AppStateService? _appStateService;

  // Callback for notification tap events (for backward compatibility)
  Function(NotificationTapEvent)? _onNotificationTap;

  static const int _dailyReminderNotificationId = 1001;
  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily Task Reminders';
  static const String _channelDescription =
      'Notifications to remind you about your daily task';

  NotificationService(this._userDataService);

  Future<void> initialize() async {
    _logger.info(
      'Initializing NotificationService for platform: ${Platform.operatingSystem}',
    );

    // Skip initialization in test environment
    if (_isTestEnvironment()) {
      _logger.info('Detected test environment - skipping platform initialization');
      return;
    }

    try {
      // Initialize timezone data with validation
      _logger.info('Initializing timezone data...');
      tz.initializeTimeZones();

      // Validate timezone initialization
      try {
        final currentZone = tz.local;
        final now = tz.TZDateTime.now(tz.local);
        _logger.info(
          'Timezone initialized successfully: ${currentZone.name}, current time: $now',
        );
      } catch (e) {
        _logger.error('Timezone validation failed: $e');
        throw Exception('Timezone initialization failed: $e');
      }

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

        // Store permission status
        final status = NotificationPermissionStatus.fromBoolean(result, true);
        await _userDataService.storeValue(
          StorageKeys.notificationPermissionStatus,
          status.name,
        );

        return result ?? false;
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

  Future<void> scheduleDeadlineReminder() async {
    _logger.info('=== SCHEDULING DAILY PLAN ===');
    _logger.info('Platform: ${Platform.operatingSystem}');
    if (Platform.isIOS) {
      _logger.info('iOS Simulator: ${_isIOSSimulator()}');
    }

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification scheduling');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      // Check intensity
      final remindersIntensity =
          await _userDataService.getValue<int>('task.remindersIntensity') ?? 0;
      _logger.info('Reminders intensity: $remindersIntensity');
      if (remindersIntensity <= 0) {
        _logger.info('Reminders disabled, canceling notifications');
        await cancelAllNotifications();
        return;
      }

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
      _logger.info('Start=$startTimeString, Deadline=$deadlineTimeString');

      // Validate timezone
      final nowTz = tz.TZDateTime.now(tz.local);
      _logger.info('Timezone OK: ${tz.local.name}, now=$nowTz');

      // Sweep stale notifications for past task days
      await _cancelBeforeTaskDate(currentDateString);

      // If scripts requested to keep only final today, enforce it
      final onlyFinalToday = await _userDataService.getValue<bool>(
            '${StorageKeys.notificationPrefix}onlyFinalToday',
          ) ??
          false;
      if (onlyFinalToday) {
        await _keepOnlyFinalForDate(_todayDateString());
        await _userDataService.removeValue(
          '${StorageKeys.notificationPrefix}onlyFinalToday',
        );
      }

      // Prime activeDays cache
      await _primeActiveDaysCache();

      // Build day-plan horizon from currentDate to endDate (inclusive)
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

        for (var d = startDate;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          if (_isActiveDay(d)) {
            datesToPlan.add(_fmtDate(d));
          }
        }
      } catch (e) {
        _logger.warning('Failed building horizon: $e');
        datesToPlan.clear();
        datesToPlan.add(currentDateString);
      }

      // Schedule multi-stage per planned day
      int scheduledCount = 0;
      for (final dateStr in datesToPlan) {
        scheduledCount += await _scheduleDaySlots(
          dateStr,
          startTimeString,
          deadlineTimeString,
          remindersIntensity,
        );
      }

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

      _logger.info('=== SCHEDULING COMPLETED: $scheduledCount notifications ===');
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

  // Compute and schedule one day’s slots (start/mid/deadline)
  Future<int> _scheduleDaySlots(
    String dateStr,
    String startTime,
    String deadlineTime,
    int intensity,
  ) async {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final isToday = _sameDate(date, now);

      final start = _composeLocal(date, startTime);
      final end = _composeLocal(date, deadlineTime);
      if (end.isBefore(start)) {
        // Guard: if misconfigured, schedule only deadline
        return await _scheduleSlot(
          dateStr,
          'deadline',
          end,
          title: 'Task Reminder',
          body: 'Time to check in on your task!',
        );
      }

      int count = 0;
      // Start encouragement (skip if today and in the past)
      if (!(isToday && start.isBefore(now))) {
        count += await _scheduleSlot(
          dateStr,
          'start',
          start,
          title: 'Let’s get it started',
          body: 'Quick nudge: your task window opens now.',
        );
      }

      // Mid-window reminders based on intensity
      final window = end.difference(start).inMinutes;
      if (window > 0 && intensity > 0) {
        final midFractions = _fractionsForIntensity(intensity);
        var idx = 0;
        for (final f in midFractions) {
          idx += 1;
          final minutesFromStart = (window * f).round();
          final midTime = start.add(Duration(minutes: minutesFromStart));
          if (isToday && midTime.isBefore(now)) continue;
          count += await _scheduleSlot(
            dateStr,
            'mid$idx',
            midTime,
            title: 'Stay on track',
            body: 'Quick check-in toward your goal.',
          );
        }
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
        shots.add(t);
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
      final first = _composeLocal(_nextActiveDateAfter(DateTime.parse(endDateStr)), startTime);
      if (first.isBefore(DateTime.now())) return;

      final id = _buildId(_fmtDate(first), 'comeback_weekly');
      final payload = json.encode({
        'type': 'comeBack',
        'slot': 'weekly',
        'taskDate': _fmtDate(first),
        'scheduledDate': first.toIso8601String(),
      });

      const details = NotificationDetails(
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
        id,
        'Check back in',
        'It’s a great day to restart.',
        tz.TZDateTime.from(first, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      _logger.warning('Failed scheduling weekly fallback: $e');
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

  Future<int> _scheduleSlot(
    String taskDate,
    String slot,
    DateTime whenLocal,
    {required String title, required String body}
  ) async {
    try {
      final id = _buildId(taskDate, slot);
      final payload = json.encode({
        'type': slot == 'deadline' ? 'dailyReminder' : 'dailyNudge',
        'slot': slot,
        'taskDate': taskDate,
        'scheduledDate': whenLocal.toIso8601String(),
      });

      const details = NotificationDetails(
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
        id,
        title,
        body,
        tz.TZDateTime.from(whenLocal, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return 1;
    } catch (e) {
      _logger.warning('Slot schedule failed ($taskDate/$slot): $e');
      return 0;
    }
  }

  int _buildId(String dateStr, String slot) {
    final base = int.tryParse(dateStr.replaceAll('-', '')) ?? 0;
    final code = () {
      if (slot == 'start') return 1;
      if (slot.startsWith('mid')) {
        final raw = int.tryParse(slot.substring(3)) ?? 1;
        final idx = raw < 1 ? 1 : (raw > 7 ? 7 : raw);
        return 2 + idx; // 3..9
      }
      if (slot == 'deadline') return 9;
      if (slot.startsWith('comeback')) return 6; // series
      if (slot == 'comeback_weekly') return 7; // weekly fallback
      return 5;
    }();
    return base * 10 + code;
  }

  String _todayDateString() => _fmtDate(DateTime.now());
  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _composeLocal(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    return DateTime(day.year, day.month, day.day, h, m);
    }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _cancelBeforeTaskDate(String cutoffDate) async {
    try {
      final pending = await getPendingNotifications();
      for (final p in pending) {
        final payload = p.payload;
        if (payload == null || payload.isEmpty) continue;
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          final taskDate = data['taskDate'] as String?;
          if (taskDate != null && taskDate.compareTo(cutoffDate) < 0) {
            await _notifications.cancel(p.id);
          }
        } catch (_) {}
      }
    } catch (e) {
      _logger.warning('Cancel-before sweep failed: $e');
    }
  }

  Future<void> _keepOnlyFinalForDate(String dateStr) async {
    try {
      final pending = await getPendingNotifications();
      for (final p in pending) {
        final payload = p.payload;
        if (payload == null || payload.isEmpty) continue;
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          if (data['taskDate'] == dateStr) {
            final slot = data['slot'] as String?;
            if (slot != 'deadline') {
              await _notifications.cancel(p.id);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      _logger.warning('Keep-final sweep failed: $e');
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
    final explicit = await _userDataService.getValue<String>(
      StorageKeys.taskStartTime,
    );
    if (explicit != null && explicit.contains(':')) return explicit;
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

  String _convertIntegerToTimeString(int intValue) {
    switch (intValue) {
      case SessionConstants.timeOfDayMorning:
        return SessionConstants.morningDeadlineTime;
      case SessionConstants.timeOfDayAfternoon:
        return SessionConstants.afternoonDeadlineTime;
      case SessionConstants.timeOfDayEvening:
        return SessionConstants.eveningDeadlineTime;
      case SessionConstants.timeOfDayNight:
        return SessionConstants.nightDeadlineTime;
      default:
        return SessionConstants.defaultDeadlineTime;
    }
  }

  Future<void> cancelAllNotifications() async {
    _logger.info('Canceling all notifications');

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification cancellation');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      await _notifications.cancelAll();
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
      _logger.info('All notifications canceled');
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
    _logger.info('Canceling deadline reminder');

    if (_isTestEnvironment()) {
      _logger.info('Test environment - skipping notification cancellation');
      await _userDataService.storeValue(StorageKeys.notificationIsEnabled, false);
      return;
    }

    try {
      await _notifications.cancel(_dailyReminderNotificationId);
      await _userDataService.storeValue(
        StorageKeys.notificationIsEnabled,
        false,
      );
      _logger.info('Deadline reminder canceled');
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
    _logger.info(
      'Notification tapped: ID=${response.id}, payload=${response.payload}',
    );

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
      final pendingCount = (await getPendingNotifications()).length;

      // Get fallback information
      final fallbackDate = await _userDataService.getValue<String>(
        '${StorageKeys.notificationPrefix}fallbackDate',
      );
      final fallbackReason = await _userDataService.getValue<String>(
        '${StorageKeys.notificationPrefix}fallbackReason',
      );

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
              } else if (slot.startsWith('comeback')) {
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
        info['simulatorLimitations'] =
            _isIOSSimulator()
                ? 'Notifications may not work properly in iOS Simulator'
                : 'Running on real iOS device';
        info['permissionNote'] =
            'Check iOS Settings > Notifications > Your App';
      } else if (Platform.isAndroid) {
        info['permissionNote'] =
            'Check Android Settings > Apps > Your App > Notifications';
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
      return {'platform': 'unknown', 'error': e.toString()};
    }
  }
}
