import 'user_data_service.dart';
import 'package:flutter/foundation.dart';
import 'text_templating_service.dart';
import 'text_variants_service.dart';
import 'chat_service.dart';
import 'message_queue.dart';
import 'logger_service.dart';
import 'session_service.dart';
import 'display_settings_service.dart';
import 'message_delay_policy.dart';
import 'notification_service.dart';
import 'app_state_service.dart';
import 'rive_overlay_service.dart';

/// Application-level service locator for dependency injection
///
/// Manages service initialization and provides centralized access to services.
/// Replaces UI-layer ServiceManager to maintain proper separation of concerns.
class ServiceLocator {
  static ServiceLocator? _instance;

  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final TextVariantsService _variantsService;
  TextTemplatingService get templatingService {
    _ensureInitialized();
    return _templatingService;
  }
  late final SessionService _sessionService;
  late final ChatService _chatService;
  late final MessageQueue _messageQueue;
  late final DisplaySettingsService _displaySettingsService;
  late final NotificationService _notificationService;
  late final AppStateService _appStateService;
  late final RiveOverlayService _riveOverlayService;
  final logger = LoggerService.instance;

  bool _initialized = false;

  ServiceLocator._internal();

  /// Get the singleton instance
  static ServiceLocator get instance {
    _instance ??= ServiceLocator._internal();
    return _instance!;
  }

  /// Initialize all application services
  /// Should be called once at application startup
  Future<void> initialize() async {
    if (_initialized) {
      logger.warning('ServiceLocator already initialized');
      return;
    }

    final overallStopwatch = Stopwatch()..start();
    final timings = <String, int>{};
    var currentTime = 0;

    logger.info('🔧 ServiceLocator initialization started');

    try {
      // Initialize services in dependency order
      var stepStopwatch = Stopwatch()..start();
      _userDataService = UserDataService();
      timings['UserDataService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['UserDataService']!;
      logger.debug('✓ UserDataService: ${timings['UserDataService']}ms');

      stepStopwatch.reset();
      _templatingService = TextTemplatingService(_userDataService);
      timings['TextTemplatingService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['TextTemplatingService']!;
      logger.debug('✓ TextTemplatingService: ${timings['TextTemplatingService']}ms');

      stepStopwatch.reset();
      _variantsService = TextVariantsService();
      timings['TextVariantsService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['TextVariantsService']!;
      logger.debug('✓ TextVariantsService: ${timings['TextVariantsService']}ms');

      stepStopwatch.reset();
      _sessionService = SessionService(_userDataService);
      timings['SessionService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['SessionService']!;
      logger.debug('✓ SessionService: ${timings['SessionService']}ms');

      stepStopwatch.reset();
      _chatService = ChatService(
        userDataService: _userDataService,
        templatingService: _templatingService,
        variantsService: _variantsService,
        sessionService: _sessionService,
      );
      timings['ChatService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['ChatService']!;
      logger.debug('✓ ChatService: ${timings['ChatService']}ms');

      stepStopwatch.reset();
      _displaySettingsService =
          DisplaySettingsService()
            ..instantDisplay = kDebugMode; // Instant in debug, adaptive in release
      _messageQueue = MessageQueue(
        delayPolicy: MessageDelayPolicy(settings: _displaySettingsService),
      );
      timings['DisplaySettings+MessageQueue'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['DisplaySettings+MessageQueue']!;
      logger.debug('✓ DisplaySettings+MessageQueue: ${timings['DisplaySettings+MessageQueue']}ms');

      // Initialize notification service (async)
      stepStopwatch.reset();
      _notificationService = NotificationService(_userDataService);
      await _notificationService.initialize();
      timings['NotificationService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['NotificationService']!;
      logger.debug('✓ NotificationService: ${timings['NotificationService']}ms');

      // Initialize app state service (async)
      stepStopwatch.reset();
      _appStateService = AppStateService(_userDataService);
      await _appStateService.initialize();
      timings['AppStateService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['AppStateService']!;
      logger.debug('✓ AppStateService: ${timings['AppStateService']}ms');

      // Initialize overlay service
      stepStopwatch.reset();
      _riveOverlayService = RiveOverlayService();
      timings['RiveOverlayService'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['RiveOverlayService']!;
      logger.debug('✓ RiveOverlayService: ${timings['RiveOverlayService']}ms');

      // Connect notification service to app state service
      stepStopwatch.reset();
      _notificationService.setAppStateService(_appStateService);
      timings['ServiceConnections'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['ServiceConnections']!;
      logger.debug('✓ ServiceConnections: ${timings['ServiceConnections']}ms');

      // Check for pending notification taps from previous sessions (async)
      stepStopwatch.reset();
      await _loadPendingNotificationState();
      timings['PendingNotificationState'] = stepStopwatch.elapsedMilliseconds;
      currentTime += timings['PendingNotificationState']!;
      logger.debug('✓ PendingNotificationState: ${timings['PendingNotificationState']}ms');

      _initialized = true;

      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.info('🎯 ServiceLocator initialization completed in ${totalTime}ms');

      // Log detailed timing breakdown
      final topServices = timings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topServicesStr = topServices.take(5).map((e) => '${e.key}=${e.value}ms').join(', ');
      logger.info('🏆 Top timing consumers: $topServicesStr');

    } catch (e) {
      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.error('❌ ServiceLocator initialization failed after ${totalTime}ms: $e');
      rethrow;
    }
  }

  /// Get the user data service
  UserDataService get userDataService {
    _ensureInitialized();
    return _userDataService;
  }

  /// Get the session service
  SessionService get sessionService {
    _ensureInitialized();
    return _sessionService;
  }

  /// Get the chat service
  ChatService get chatService {
    _ensureInitialized();
    return _chatService;
  }

  /// Get the message queue
  MessageQueue get messageQueue {
    _ensureInitialized();
    return _messageQueue;
  }

  /// Get the display settings service
  DisplaySettingsService get displaySettings {
    _ensureInitialized();
    return _displaySettingsService;
  }

  /// Get the notification service
  NotificationService get notificationService {
    _ensureInitialized();
    return _notificationService;
  }

  /// Get the app state service
  AppStateService get appStateService {
    _ensureInitialized();
    return _appStateService;
  }

  /// Get the Rive overlay service
  RiveOverlayService get riveOverlayService {
    _ensureInitialized();
    return _riveOverlayService;
  }

  /// Check if services are initialized
  bool get isInitialized => _initialized;

  /// Dispose of all services
  /// Should be called when the application is shutting down
  void dispose() {
    if (!_initialized) return;

    logger.info('Disposing application services');

    _messageQueue.dispose();
    _riveOverlayService.dispose();
    _initialized = false;

    logger.info('All services disposed');
  }

  /// Reset the service locator (primarily for testing)
  static void reset() {
    _instance?._reset();
    _instance = null;
  }

  void _reset() {
    if (_initialized) {
      dispose();
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
  }

  /// Load any pending notification state from previous sessions
  /// This ensures notification taps are preserved across app restarts
  Future<void> _loadPendingNotificationState() async {
    try {
      logger.info('Checking for pending notification state from previous sessions...');
      
      final pendingEvent = await _appStateService.consumePendingNotification();
      
      if (pendingEvent != null) {
        logger.info('Found pending notification tap from previous session: $pendingEvent');
        logger.info('Notification state restored - user came from notification tap');
      } else {
        logger.info('No pending notification state found');
      }
    } catch (e) {
      logger.error('Failed to load pending notification state: $e');
      // Don't rethrow - this is not critical for app functionality
    }
  }
}
