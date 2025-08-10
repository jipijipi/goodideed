/// Test helper utilities for consistent test setup
///
/// This file provides common test utilities to reduce boilerplate
/// and ensure consistent test configuration across the test suite.
library;

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
