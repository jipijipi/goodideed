/// Test helper utilities for consistent test setup
///
/// This file provides common test utilities to reduce boilerplate
/// and ensure consistent test configuration across the test suite.
library;

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noexc/services/logger_service.dart';

/// Configure environment for TDD with minimal logging output
/// Call this in setUp() for quiet test runs
void setupQuietTesting() {
  LoggerService.instance.configureForTesting();
}

/// Configure environment for completely silent testing (no output at all)
/// Use this for error-handling tests that generate expected error logs
void setupSilentTesting() {
  LoggerService.instance.configureForSilentTesting();
}

/// Reset logger to default configuration
/// Call this in tearDown() if needed
void resetLoggingDefaults() {
  LoggerService.instance.resetToDefaults();
}

/// Configure logger for specific test scenarios
void configureTestLogging({
  LogLevel? minLevel,
  Set<LogComponent>? enabledComponents,
  bool showTimestamps = false,
}) {
  LoggerService.instance.configure(
    minLevel: minLevel ?? LogLevel.error,
    enabledComponents: enabledComponents,
    showTimestamps: showTimestamps,
  );
}

/// Execute a function while suppressing expected error logs
/// Useful for testing error-handling code paths without noise
T withSuppressedErrors<T>(T Function() testFunction) {
  return LoggerService.instance.withSuppressedErrors(testFunction);
}

/// Execute an async function while suppressing expected error logs
/// Useful for testing async error-handling code paths without noise
Future<T> withSuppressedErrorsAsync<T>(Future<T> Function() testFunction) {
  return LoggerService.instance.withSuppressedErrorsAsync(testFunction);
}

/// Mock implementation of FlutterLocalNotificationsPlatform for testing
class MockFlutterLocalNotificationsPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterLocalNotificationsPlatform {
  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return NotificationAppLaunchDetails(false, notificationResponse: null);
  }

  @override
  Future<bool?> requestPermissions({
    bool? alert,
    bool? badge,
    bool? sound,
    bool? critical,
  }) async {
    return true;
  }

  @override
  Future<void> show(int id, String? title, String? body,
      {String? payload}) async {}

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async {
    return [];
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [];
  }

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {}

  @override
  Future<List<AndroidNotificationChannel>> getNotificationChannels() async {
    return [];
  }
}

/// Setup mock method call handlers for Flutter platform plugins
/// This prevents LateInitializationError during test execution
void setupPlatformMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure Google Fonts for test environment (avoid network loading)
  // This disables Google Fonts HTTP loading in test environment
  GoogleFonts.config.allowRuntimeFetching = false;

  // Register mock platform interface
  FlutterLocalNotificationsPlatform.instance = MockFlutterLocalNotificationsPlatform();

  // Mock flutter_local_notifications platform with all known channels
  final notificationChannels = [
    'dexterous.com/flutter/local_notifications',
    'dexterous.com/flutter/local_notifications_android',
    'dexterous.com/flutter/local_notifications_ios',
    'flutter_local_notifications',
  ];
  
  for (final channel in notificationChannels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel(channel),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'initialize':
            return true;
          case 'getNotificationAppLaunchDetails':
            return {'notificationLaunchedApp': false, 'notificationResponse': null};
          case 'requestPermissions':
            return true;
          case 'show':
            return null;
          case 'cancel':
            return null;
          case 'cancelAll':
            return null;
          case 'getActiveNotifications':
            return [];
          case 'getPendingNotificationRequests':
            return [];
          case 'createNotificationChannel':
            return null;
          case 'resolvePlatformSpecificImplementation':
            return null;
          case 'getNotificationChannels':
            return [];
          default:
            return null;
        }
      },
    );
  }

  // Mock shared_preferences
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAll':
          return <String, dynamic>{};
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList':
          return true;
        case 'remove':
          return true;
        case 'clear':
          return true;
        default:
          return null;
      }
    },
  );

  // Mock flutter assets loading with proper responses for Google Fonts
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter/assets'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'loadString') {
        final String assetKey = methodCall.arguments as String;
        if (assetKey.contains('sequences/welcome_seq.json')) {
          return '{"sequenceId": "welcome_seq", "name": "Welcome", "messages": [{"id": 1, "type": "bot", "text": "Welcome!"}]}';
        } else if (assetKey.contains('AssetManifest.json')) {
          // Proper asset manifest structure for Google Fonts
          return '''
{
  "packages/google_fonts/fonts/Inter-Regular.ttf": ["packages/google_fonts/fonts/Inter-Regular.ttf"]
}''';
        } else if (assetKey.contains('FontManifest.json')) {
          // Proper font manifest structure
          return '''
[
  {
    "family": "Inter",
    "fonts": [
      {
        "asset": "packages/google_fonts/fonts/Inter-Regular.ttf",
        "weight": 400
      }
    ]
  }
]''';
        } else if (assetKey.contains('debug/scenarios.json')) {
          // Mock scenarios for debug panel
          return '{"scenarios": []}';
        }
      } else if (methodCall.method == 'load') {
        // Handle binary asset loading (fonts)
        final String assetKey = methodCall.arguments as String;
        if (assetKey.contains('.ttf') || assetKey.contains('fonts/')) {
          // Return empty byte array for font files
          return Uint8List(0);
        }
      }
      return null;
    },
  );
}

/// Setup comprehensive testing environment with all necessary mocks
/// Call this in setUp() for tests that initialize services or use ServiceLocator
void setupTestingWithMocks() {
  setupPlatformMocks();
  setupQuietTesting();
}

/// Create a test-specific service locator that doesn't initialize notification service
/// Use this for tests that need services but can't handle platform initialization
Future<void> initializeTestServiceLocator() async {
  // Import statement would be needed: import 'package:noexc/services/service_locator.dart';
  // But we'll implement this directly in the test files to avoid circular dependencies
}

/// Example test setup patterns:
///
/// ```dart
/// // Standard quiet testing (shows errors but minimal noise)
/// setUp(() {
///   setupQuietTesting(); // Minimal output
///   // ... other test setup
/// });
/// ```
///
/// ```dart
/// // Silent testing for error-handling tests (no output at all)
/// setUp(() {
///   setupSilentTesting(); // Zero output
/// });
/// ```
///
/// ```dart
/// // Suppress expected errors in specific test blocks
/// test('should handle invalid input gracefully', () async {
///   await withSuppressedErrorsAsync(() async {
///     // Test code that triggers expected errors
///     final result = await service.processInvalidData();
///     expect(result, isA<ErrorResult>());
///   });
/// });
/// ```
///
/// ```dart
/// setUp(() {
///   configureTestLogging(
///     minLevel: LogLevel.warning,
///     enabledComponents: {LogComponent.chatService},
///   );
/// });
/// ```
