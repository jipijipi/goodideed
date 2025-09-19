# API Reference

## Core Services

### ChatService
Main orchestrator for conversation flows and user interactions.

#### Methods
```dart
Future<void> loadSequence(String sequenceId)
Future<void> processMessage(ChatMessage message)
Future<void> handleUserInput(String input)
void resetConversation()
```

#### Properties
```dart
Stream<List<ChatMessage>> get messageStream
List<ChatMessage> get currentMessages
String? get currentSequenceId
bool get isProcessing
```

### UserDataService
Local data storage and retrieval using SharedPreferences.

#### Methods
```dart
Future<void> setValue(String key, dynamic value)
Future<T?> getValue<T>(String key)
Future<void> removeValue(String key)
Future<void> clearAllData()
Future<List<String>> getAllKeys()
Future<Map<String, dynamic>> getAllData()
```

#### Template Integration
```dart
Future<String> resolveTemplate(String template)
Future<Map<String, dynamic>> getTemplateContext()
```

### SessionService
Session tracking with daily reset functionality.

#### Methods
```dart
Future<void> initializeSession()
Future<void> resetSession()
Future<void> updateSessionData()
Future<void> recalculateActiveDay()
Future<void> recalculatePastDeadline()
```

#### Properties
```dart
int get visitCount
int get totalVisitCount
DateTime get lastVisitDate
bool get isWeekend
int get timeOfDay
```

### NotificationService
Platform notification management with permission handling.

#### Methods
```dart
Future<NotificationPermissionStatus> getPermissionStatus()
Future<bool> requestPermissions()
Future<void> scheduleNotification(NotificationRequest request)
Future<void> cancelNotification(int id)
Future<void> cancelAllNotifications()
```

#### Properties
```dart
bool get shouldRequestPermissions
bool get needsManualSettings
Stream<NotificationTapEvent> get notificationTaps
```

### AppStateService
Cross-session state management and notification tap event handling.

#### Methods
```dart
Future<void> storeNotificationTapEvent(NotificationTapEvent event)
Future<NotificationTapEvent?> consumePendingNotification()
Future<void> clearPendingNotifications()
Future<void> trackAppLaunch()
```

### SemanticContentService
Dynamic content resolution with graceful fallbacks.

#### Methods
```dart
Future<String> resolveContent(String contentKey, [String? fallback])
Future<List<String>> getAvailableVariants(String contentKey)
Future<void> preloadContent()
void clearCache()
```

#### Fallback Chain
1. Exact match: `bot.acknowledge.completion.positive`
2. Drop segments: `bot.acknowledge.completion`
3. Continue dropping: `bot.acknowledge`
4. Base level: `bot`
5. Generic content
6. Legacy variants
7. Hardcoded defaults
8. Error state

### LoggerService
Centralized logging system with component-specific methods.

#### Methods
```dart
void debug(String message, [Map<String, dynamic>? context])
void info(String message, [Map<String, dynamic>? context])
void warning(String message, [Map<String, dynamic>? context])
void error(String message, [Map<String, dynamic>? context])
void critical(String message, [Map<String, dynamic>? context])
```

#### Component Methods
```dart
void route(String message, [Map<String, dynamic>? context])
void semantic(String message, [Map<String, dynamic>? context])
void ui(String message, [Map<String, dynamic>? context])
void notification(String message, [Map<String, dynamic>? context])
```

## Data Models

### ChatMessage
Core message model with multi-text support.

#### Properties
```dart
String id
MessageType type
String text
String? contentKey
Map<String, dynamic>? animation
List<Choice>? choices
Map<String, dynamic>? action
DateTime timestamp
```

#### Methods
```dart
List<String> getTextBubbles()  // Splits on '|||'
bool hasAnimation()
bool hasChoices()
Map<String, dynamic> toJson()
static ChatMessage fromJson(Map<String, dynamic> json)
```

### Choice
User interaction choice with optional data persistence.

#### Properties
```dart
String text
dynamic value
String? key
String? sequenceId
bool? disabled
Map<String, dynamic>? metadata
```

#### Methods
```dart
Future<void> execute(UserDataService userDataService)
bool get hasDataAction
Map<String, dynamic> toJson()
```

### NotificationTapEvent
Rich notification tap event with JSON payload parsing.

#### Properties
```dart
int notificationId
DateTime timestamp
Map<String, dynamic> payload
NotificationType type
String? userInput
```

#### Methods
```dart
T? getPayloadValue<T>(String key)
bool hasSchedulingContext()
DateTime? getScheduledDate()
static NotificationTapEvent fromJson(Map<String, dynamic> json)
```

## Enums

### MessageType
```dart
enum MessageType {
  bot,       // Bot responses
  user,      // User text input
  choice,    // Multiple choice interactions
  textInput, // Free text input
  autoroute, // Automatic routing
  dataAction // Data modification
}
```

### NotificationPermissionStatus
```dart
enum NotificationPermissionStatus {
  granted,      // Notifications enabled
  denied,       // User explicitly denied
  notRequested, // Ready to request permissions
  restricted,   // System policy prevents notifications
  unknown       // Unable to determine status
}
```

### NotificationType
```dart
enum NotificationType {
  dailyReminder, // Task deadline notifications (ID: 1001)
  achievement,   // Milestone notifications
  warning,       // Alert notifications
  system,        // Maintenance notifications
  unknown        // Unrecognized type
}
```

## Constants

### AppConstants
Application-wide configuration values.

#### Notification IDs
```dart
static const int DAILY_REMINDER_ID = 1001;
static const int ACHIEVEMENT_BASE_ID = 2000;
static const int WARNING_BASE_ID = 3000;
static const int SYSTEM_BASE_ID = 4000;
```

#### Available Sequences
```dart
static const List<String> availableSequences = [
  'welcome_seq',
  'onboarding_seq',
  'taskChecking_seq',
  'taskSetting_seq',
  'sendoff_seq',
  'success_seq',
  'failure_seq',
];
```

#### Time Constants
```dart
static const int MORNING = 1;
static const int AFTERNOON = 2;
static const int EVENING = 3;
static const int NIGHT = 4;
```

## Template Functions

### Available Functions
```dart
TODAY_DATE              // Current date (YYYY-MM-DD)
NEXT_ACTIVE_DATE       // Next date matching user's active days
NEXT_ACTIVE_WEEKDAY    // Weekday number of next active date
```

### Formatters
```dart
timeOfDay              // Format time periods (1→"morning")
activeDays             // Format weekday arrays ([1,2,3,4,5]→"weekdays")
intensity              // Format intensity levels (0→"off", 3→"maximum")
timePeriod             // Format time strings ("10:00"→"morning deadline")
```

### Case Transformations
```dart
upper                  // ALL UPPERCASE
lower                  // all lowercase
proper                 // First Letter Of Each Word Capitalized
sentence               // First letter only capitalized
```

## Error Handling

### Exception Types
```dart
class SequenceNotFoundException extends Exception
class InvalidMessageTypeException extends Exception
class TemplateResolutionException extends Exception
class NotificationPermissionException extends Exception
class ContentResolutionException extends Exception
```

### Error Recovery
- All services implement graceful degradation
- Fallback content for missing resources
- Logging of all errors for debugging
- Continuation of core functionality despite errors

## Testing Support

### Mock Services
```dart
MockUserDataService     // For isolated unit testing
MockNotificationService // Platform-independent testing
MockSemanticContent     // Content resolution testing
```

### Test Helpers
```dart
setupQuietTesting()     // Reduces log noise during TDD
createTestMessage()     // Factory for test messages
createTestChoice()      // Factory for test choices
setupMockServices()     // Configure mock service suite
```

## Integration Points

### Flutter Framework
- StatefulWidget integration for reactive UI
- SharedPreferences for data persistence
- Platform channels for notifications

### External Packages
- `rive: ^0.14.0-dev.5` - Animation rendering
- `shared_preferences` - Local storage
- Platform-specific notification packages

### Asset Integration
- JSON sequence files in `assets/sequences/`
- Semantic content in `assets/content/`
- Rive animations in `assets/animations/`

## Performance Considerations

### Caching
- Semantic content cached after first load
- Template compilation results cached
- Notification permission status cached

### Memory Management
- Message history pruning after display
- Animation asset cleanup
- Service instance reuse

### Async Operations
- All storage operations are async
- Non-blocking UI updates
- Background processing for notifications

## Security

### Data Validation
- All user inputs validated before storage
- Template injection protection
- JSON parsing with error handling

### Privacy
- Local-first data storage
- No cloud synchronization
- Anonymous usage patterns only

## See Also

- **[Architecture Overview](../architecture/overview.md)** - System design
- **[Chat System](../architecture/chat-system.md)** - Message processing
- **[Template Syntax](template-syntax.md)** - Template system reference
- **[Testing Guide](../getting-started/testing-guide.md)** - Testing services