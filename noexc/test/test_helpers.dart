/// Test helper utilities for consistent test setup
///
/// This file provides common test utilities to reduce boilerplate
/// and ensure consistent test configuration across the test suite.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Platform interfaces handled via method channels - no direct imports needed
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


// Platform interface mocks are handled via method channels below
// No explicit platform interface implementation needed

/// Setup mock method call handlers for Flutter platform plugins
/// This prevents LateInitializationError during test execution
void setupPlatformMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure Google Fonts for test environment (avoid network loading)
  GoogleFonts.config.allowRuntimeFetching = false;

  // Platform interface instance is not set explicitly
  // Method channel mocks below handle all platform communication

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

  // Don't mock flutter/assets channel - let all assets load normally
  // Google Fonts is disabled via GoogleFonts.config.allowRuntimeFetching = false above
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
