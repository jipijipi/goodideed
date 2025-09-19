# Logging System Guide

The LoggerService provides centralized, configurable logging to replace scattered print statements throughout the codebase.

## Quick Start

```dart
import '../services/logger_service.dart';

// Basic logging
logger.debug('Processing started');
logger.info('Task completed successfully');
logger.warning('Deprecated method used');
logger.error('Operation failed');
logger.critical('System unstable');
```

## Component-Specific Logging

```dart
// Use convenience methods for common components
logger.route('Evaluating route condition');
logger.condition('Variable check: user.active == true');
logger.scenario('Applied "Returning User" scenario');
logger.semantic('Cache hit for key: bot.acknowledge.completion');

// Or specify component explicitly
logger.debug('Custom message', component: LogComponent.chatService);
```

## Configuration

### Programmatically
```dart
// Set minimum log level
logger.configure(minLevel: LogLevel.warning);

// Filter by specific components
logger.configure(enabledComponents: {
  LogComponent.routeProcessor,
  LogComponent.conditionEvaluator,
});

// Enable timestamps
logger.configure(showTimestamps: true);
```

### Debug Panel
1. Open app debug panel (bug icon)
2. Find "Logger Controls" section
3. Configure:
   - **Log Level**: Choose minimum level to display
   - **Components**: Toggle individual services on/off
   - **Timestamps**: Show/hide message timestamps
4. Use quick presets:
   - **Debug All**: Show everything
   - **Errors Only**: Production-safe logging

## Log Levels

| Level | Emoji | When to Use | Production |
|-------|-------|-------------|------------|
| `debug` | 🔍 | Development details, tracing | Hidden |
| `info` | ℹ️ | Important events, milestones | Hidden |
| `warning` | ⚠️ | Deprecated usage, recoverable issues | Hidden |
| `error` | ❌ | Failures, exceptions | Shown |
| `critical` | 🚨 | System instability, data loss | Shown |

## Components

| Component | Tag | Use For |
|-----------|-----|---------|
| `routeProcessor` | ROUTE | Auto-route evaluations |
| `conditionEvaluator` | CONDITION | Variable condition checks |
| `scenarioManager` | SCENARIO | Test scenario operations |
| `semanticContent` | SEMANTIC | Content resolution |
| `chatService` | CHAT | Main chat flow |
| `userDataService` | USER_DATA | Data storage operations |
| `errorHandler` | ERROR | Error classification |
| `ui` | UI | Interface operations |
| `general` | GENERAL | Miscellaneous logging |

## Best Practices

### ✅ Do
```dart
// Use appropriate levels
logger.info('User completed onboarding');  // Important milestone
logger.debug('Checking condition: user.streak > 5');  // Development detail

// Use component-specific methods
logger.route('No conditions matched, using default');
logger.condition('Boolean check result: true');

// Include context in messages
logger.error('Failed to load sequence "welcome_seq": File not found');
```

### ❌ Don't
```dart
// Don't use print() statements
print('Debug info');  // Use logger.debug() instead

// Don't over-log critical events
logger.critical('Minor validation error');  // Use logger.warning()

// Don't include sensitive data
logger.debug('User password: ' + password);  // Security risk
```

## Migration from print()

### Before
```dart
print('🚏 AUTOROUTE: Processing route ${routeId}');
print('❌ ERROR: Failed to load: $error');
```

### After
```dart
logger.route('Processing route ${routeId}');
logger.error('Failed to load: $error');
```

## Performance

- **Development**: All levels shown, minimal overhead
- **Production**: Only error/critical shown, near-zero overhead
- **Filtering**: Components can be disabled completely
- **Caching**: Logger instance is singleton for efficiency

## Integration

The logger is automatically available throughout the app:
```dart
import '../services/logger_service.dart';

// Global instance ready to use
logger.debug('System ready');
```

No setup required - the service configures itself based on build mode and debug panel settings.