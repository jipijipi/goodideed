import 'user_data_service.dart';
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

/// Application-level service locator for dependency injection
///
/// Manages service initialization and provides centralized access to services.
/// Replaces UI-layer ServiceManager to maintain proper separation of concerns.
class ServiceLocator {
  static ServiceLocator? _instance;

  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final TextVariantsService _variantsService;
  late final SessionService _sessionService;
  late final ChatService _chatService;
  late final MessageQueue _messageQueue;
  late final DisplaySettingsService _displaySettingsService;
  late final NotificationService _notificationService;
  late final AppStateService _appStateService;
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

    logger.info('Initializing application services');

    try {
      // Initialize services in dependency order
      _userDataService = UserDataService();
      _templatingService = TextTemplatingService(_userDataService);
      _variantsService = TextVariantsService();
      _sessionService = SessionService(_userDataService);

      _chatService = ChatService(
        userDataService: _userDataService,
        templatingService: _templatingService,
        variantsService: _variantsService,
        sessionService: _sessionService,
      );

      _displaySettingsService =
          DisplaySettingsService()
            ..instantDisplay = true; // Default to instant mode for now
      _messageQueue = MessageQueue(
        delayPolicy: MessageDelayPolicy(settings: _displaySettingsService),
      );

      // Initialize notification service
      _notificationService = NotificationService(_userDataService);
      await _notificationService.initialize();

      // Initialize app state service
      _appStateService = AppStateService(_userDataService);
      await _appStateService.initialize();

      // Connect notification service to app state service
      _notificationService.setAppStateService(_appStateService);

      _initialized = true;
      logger.info('All services initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize services: $e');
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

  /// Check if services are initialized
  bool get isInitialized => _initialized;

  /// Dispose of all services
  /// Should be called when the application is shutting down
  void dispose() {
    if (!_initialized) return;

    logger.info('Disposing application services');

    _messageQueue.dispose();
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
}
