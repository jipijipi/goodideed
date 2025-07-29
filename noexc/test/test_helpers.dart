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

/// Example test setup patterns:
/// 
/// ```dart
/// setUp(() {
///   setupQuietTesting(); // Minimal output
///   // ... other test setup
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