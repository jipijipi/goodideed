import 'package:flutter/foundation.dart';

/// Log levels for the logger service
enum LogLevel {
  debug(0, '🔍'),
  info(1, 'ℹ️'),
  warning(2, '⚠️'),
  error(3, '❌'),
  critical(4, '🚨');

  const LogLevel(this.value, this.emoji);
  final int value;
  final String emoji;
}

/// Component tags for organized logging
enum LogComponent {
  chatService('CHAT'),
  routeProcessor('ROUTE'),
  conditionEvaluator('CONDITION'),
  scenarioManager('SCENARIO'),
  userDataService('USER_DATA'),
  sessionService('SESSION'),
  messageProcessor('MESSAGE'),
  sequenceLoader('SEQUENCE'),
  dataActionProcessor('DATA_ACTION'),
  errorHandler('ERROR'),
  validation('VALIDATION'),
  semanticContent('SEMANTIC'),
  ui('UI'),
  general('GENERAL');

  const LogComponent(this.tag);
  final String tag;
}

/// Simple but robust logging service to replace scattered print statements
class LoggerService {
  static LoggerService? _instance;
  static LoggerService get instance => _instance ??= LoggerService._();
  
  LoggerService._();

  /// Current minimum log level (configurable)
  LogLevel _minLevel = _getDefaultLogLevel();
  
  /// Component filters - if empty, all components are logged
  final Set<LogComponent> _enabledComponents = {};
  
  /// Whether to show timestamps
  bool _showTimestamps = false;

  /// Configure the logger
  void configure({
    LogLevel? minLevel,
    Set<LogComponent>? enabledComponents,
    bool? showTimestamps,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (enabledComponents != null) {
      _enabledComponents.clear();
      _enabledComponents.addAll(enabledComponents);
    }
    if (showTimestamps != null) _showTimestamps = showTimestamps;
  }

  /// Enable all components (default behavior)
  void enableAllComponents() => _enabledComponents.clear();

  /// Enable specific components only
  void enableComponents(Set<LogComponent> components) {
    _enabledComponents.clear();
    _enabledComponents.addAll(components);
  }

  /// Check if a log should be output
  bool _shouldLog(LogLevel level, LogComponent component) {
    // Check log level
    if (level.value < _minLevel.value) return false;
    
    // Check component filter (empty means all enabled)
    if (_enabledComponents.isNotEmpty && !_enabledComponents.contains(component)) {
      return false;
    }
    
    return true;
  }

  /// Format the log message
  String _formatMessage(LogLevel level, LogComponent component, String message) {
    final buffer = StringBuffer();
    
    // Add timestamp if enabled
    if (_showTimestamps) {
      final now = DateTime.now();
      buffer.write('[${now.hour.toString().padLeft(2, '0')}:'
                  '${now.minute.toString().padLeft(2, '0')}:'
                  '${now.second.toString().padLeft(2, '0')}] ');
    }
    
    // Add level emoji and component tag
    buffer.write('${level.emoji} ${component.tag}: $message');
    
    return buffer.toString();
  }

  /// Generic log method
  void _log(LogLevel level, LogComponent component, String message) {
    if (!_shouldLog(level, component)) return;
    
    final formattedMessage = _formatMessage(level, component, message);
    
    // In debug mode, use debugPrint for better IDE integration
    // In release mode, only critical/error logs should appear
    if (kDebugMode) {
      debugPrint(formattedMessage);
    } else if (level.value >= LogLevel.error.value) {
      print(formattedMessage);
    }
  }

  /// Debug level logging (development only)
  void debug(String message, {LogComponent component = LogComponent.general}) {
    _log(LogLevel.debug, component, message);
  }

  /// Info level logging
  void info(String message, {LogComponent component = LogComponent.general}) {
    _log(LogLevel.info, component, message);
  }

  /// Warning level logging
  void warning(String message, {LogComponent component = LogComponent.general}) {
    _log(LogLevel.warning, component, message);
  }

  /// Error level logging
  void error(String message, {LogComponent component = LogComponent.general}) {
    _log(LogLevel.error, component, message);
  }

  /// Critical level logging (always shown)
  void critical(String message, {LogComponent component = LogComponent.general}) {
    _log(LogLevel.critical, component, message);
  }

  /// Convenience method for route processing logs
  void route(String message, {LogLevel level = LogLevel.debug}) {
    _log(level, LogComponent.routeProcessor, message);
  }

  /// Convenience method for condition evaluation logs
  void condition(String message, {LogLevel level = LogLevel.debug}) {
    _log(level, LogComponent.conditionEvaluator, message);
  }

  /// Convenience method for scenario management logs
  void scenario(String message, {LogLevel level = LogLevel.warning}) {
    _log(level, LogComponent.scenarioManager, message);
  }

  /// Convenience method for semantic content logs
  void semantic(String message, {LogLevel level = LogLevel.debug}) {
    _log(level, LogComponent.semanticContent, message);
  }

  /// Configure for test environment (minimal logging)
  void configureForTesting() {
    configure(
      minLevel: LogLevel.error,  // Only show errors and critical in tests
      enabledComponents: {}, // Enable all components
      showTimestamps: false,
    );
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _minLevel = _getDefaultLogLevel();
    _enabledComponents.clear();
    _showTimestamps = false;
  }

  /// Get default log level based on environment
  static LogLevel _getDefaultLogLevel() {
    // Check if we're in a test environment
    if (isTestEnvironment()) {
      return LogLevel.error;  // Quiet during tests
    }
    return kDebugMode ? LogLevel.debug : LogLevel.error;
  }

  /// Check if we're running in a test environment
  static bool isTestEnvironment() {
    // Flutter test sets FLUTTER_TEST environment variable
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  }

  /// Get current configuration for debug panel
  Map<String, dynamic> getConfiguration() {
    return {
      'minLevel': _minLevel.name,
      'enabledComponents': _enabledComponents.map((c) => c.name).toList(),
      'showTimestamps': _showTimestamps,
      'allComponentsEnabled': _enabledComponents.isEmpty,
    };
  }
}

/// Global logger instance for convenient access
final logger = LoggerService.instance;