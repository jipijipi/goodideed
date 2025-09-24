# CLAUDE.md

This file provides guidance to Claude Code when working with this Flutter chat app repository.

## Commands

### Essential Commands
- `flutter run` - Run the app
- `flutter test` - Run all tests  
- `flutter analyze` - Static analysis and linting
- `flutter build apk/ios/web` - Build for platforms
- `cd noexc-authoring-tool && npm start` - Run React Flow authoring tool

### TDD-Optimized Test Commands
For reduced verbosity during Test-Driven Development:

#### Quick TDD Testing (Minimal Output)
- `dart tool/tdd_runner.dart --quiet test/services/specific_test.dart` - Single file, minimal output
- `dart tool/tdd_runner.dart -q test/models/` - Directory testing with minimal noise
- `dart tool/tdd_runner.dart --name "specific test pattern"` - Target specific tests
- `flutter test --reporter compact test/specific_test.dart` - Built-in compact reporter

#### Focused Testing Strategies
- `flutter test test/services/logger_service_test.dart` - Single service test
- `flutter test test/models/ --concurrency=2` - Directory with limited concurrency
- `flutter test --name "should handle errors"` - Pattern-based test selection
- `flutter test --tags tdd` - Run only TDD-tagged tests

#### Traditional Commands (More Verbose)
- `flutter test` - Full test suite (high verbosity)
- `flutter test --verbose` - Maximum output for debugging

## Architecture Overview

### Core Architecture
Flutter chat app with a **sequence-based conversation system**:
- **Dynamic message sequences** loaded from JSON files
- **User data storage** with template substitution (`{key|fallback}`)
- **Multi-text messages** with `|||` separator
- **Conditional routing** based on user attributes
- **Choice-based interactions** with data persistence
- **Semantic content system** for dynamic text variants

### React Flow Authoring Tool
Visual tool in `noexc-authoring-tool/` for creating conversation sequences:
- **Drag-and-drop interface** for building conversation flows
- **Group system** - organize nodes into sequences
- **Cross-sequence navigation** with auto-detection
- **Direct Flutter export** - generates compatible JSON files
- **TypeScript-based** with comprehensive validation

### Key Components

#### Core Services
- **ChatService** - Main orchestrator with focused processors (sequence_loader, message_processor, route_processor)
- **UserDataService** - Local storage using shared_preferences
- **SessionService** - Session tracking with daily reset functionality
- **LoggerService** - Centralized logging system (NEVER use print statements)
- **SemanticContentService** - Dynamic content resolution with graceful fallbacks
- **NotificationService** - Comprehensive notification management with permission tracking and scheduling
- **AppStateService** - Notification tap event tracking and cross-session state management

#### Models & Message Types
- **MessageType enum**: bot, user, choice, textInput, autoroute, dataAction
- **ChatMessage** - Core message model with multi-text support (`|||`)
- **Choice** - User interaction options with optional custom values
- **DataAction** - Data modification operations (set, increment, decrement, reset, trigger)
- **NotificationPermissionStatus** - 5-state permission model (granted, denied, notRequested, restricted, unknown)
- **NotificationTapEvent** - Rich tap event model with JSON payload parsing and type detection
- **NotificationType enum**: dailyReminder, achievement, warning, system, unknown

#### UI Architecture
- **ChatScreen** - Main container
- **ChatStateManager** - Split into service_manager, message_display_manager, user_interaction_handler
- **UserPanelOverlay** - Debug panel with scenario testing and variable editing

## Asset Structure
- `assets/sequences/` - JSON conversation flows (7 core sequences: welcome_seq, onboarding_seq, taskChecking_seq, taskSetting_seq, sendoff_seq, success_seq, failure_seq)
- `assets/content/` - Semantic content system (actor/action/subject structure)
- `assets/debug/scenarios.json` - Test scenarios for rapid user state simulation

## Key Features

### Storage & Templates
- **Local Storage**: shared_preferences for user data persistence
- **Template System**: `{key|fallback}` syntax for dynamic text substitution
- **Formatter Support**: `{key:formatter}` and `{key:formatter|fallback}` syntax (timeOfDay, intensity, activeDays, timePeriod)
- **Case Transformations**: `{key:upper}`, `{key:lower}`, `{key:proper}`, `{key:sentence}` for text formatting
- **Combined Formatting**: `{key:formatter:case}` and `{key:formatter:join:case}` for complex transformations
- **Key Task Variables**: `task.currentDate`, `task.currentStatus`, `task.startTime`, `task.deadlineTime`, `task.isActiveDay`, `task.isBeforeStart`, `task.isInTimeRange`, `task.isPastDeadline`

### Message System
- **Multi-text messages**: Use `|||` separator for multiple bubbles
- **MessageType enum**: bot, user, choice, textInput, autoroute, dataAction
- **Conditional routing**: Auto-routes with compound conditions (`&&`, `||`)
- **Semantic content**: Dynamic text resolution with graceful fallbacks

### Session Tracking
- **SessionService** automatically tracks user data on app start
- **Key Session Variables**: `session.visitCount`, `session.totalVisitCount`, `session.timeOfDay`, `session.isWeekend`
- **Task Management**: Automatic date initialization, status updates, and deadline checking
- **Common Conditions**: 
  - `session.visitCount > 1` - Returning daily user
  - `task.isActiveDay == true` - Today is active day
  - `task.isBeforeStart == true` - Before user's start time
  - `task.isInTimeRange == true` - Within start-deadline window
  - `task.isPastDeadline == true` - Past user's deadline

### Semantic Content System
Dynamic content system using semantic keys like `bot.acknowledge.completion.positive`:
- **Graceful fallbacks**: 8-level fallback chain ensures content always resolves
- **File structure**: `assets/content/` organized by actor/action/subject
- **Usage**: Add `contentKey` field to messages for dynamic text resolution
- **Legacy support**: `assets/variants/` files still work for backward compatibility

### Notification System
Comprehensive notification management with permission tracking and tap event handling:
- **Permission Management**: 5-state model distinguishing between never-asked, denied, and granted permissions
- **Rich Tap Events**: JSON payloads with type detection, action support, and user input handling
- **Cross-Session Persistence**: AppStateService tracks notification taps even when app was closed
- **Debug Integration**: Visual permission status and tap event tracking in debug panel
- **Platform Support**: iOS, Android, and macOS with platform-specific behavior handling

#### Permission States
- **granted**: Notifications enabled, can schedule
- **denied**: User explicitly denied, needs manual Settings enable
- **notRequested**: Ready to request permissions from user
- **restricted**: System policy prevents notifications (e.g., parental controls)
- **unknown**: Unable to determine status (error condition)

#### Notification Types
- **dailyReminder** (ID: 1001): Task deadline notifications with scheduling data
- **achievement**: Milestone and progress notifications  
- **warning**: Alert notifications for important events
- **system**: Maintenance and system-level notifications
- **unknown**: Fallback for unrecognized notification types

#### Key Methods
- `NotificationService.getPermissionStatus()` - Check current permission state without requesting
- `NotificationService.requestPermissions()` - Request permissions with tracking
- `AppStateService.handleNotificationTap(event)` - Process tap events with rich context
- `AppStateService.consumePendingNotification()` - Handle cross-session tap events

## Critical Rules

### Logging (MANDATORY)
⚠️ **NEVER use print() statements - ALWAYS use LoggerService** ⚠️
- Import: `final logger = LoggerService();`
- Levels: `debug()`, `info()`, `warning()`, `error()`, `critical()`
- Component methods: `logger.route()`, `logger.semantic()`, `logger.ui()`

### Testing (TDD Required)
- **ALWAYS use Test-Driven Development** (Red-Green-Refactor cycle)
- Write tests BEFORE implementing functionality
- **350+ passing tests** across models, services, widgets, validation
- Test files mirror `lib/` directory structure in `test/`
- Never commit code without corresponding tests
- **Notification System**: 67 comprehensive tests covering permission states, tap events, and cross-session persistence

#### Test Setup for Minimal Output
```dart
import '../test_helpers.dart';

setUp(() {
  setupQuietTesting(); // Reduces log noise during TDD
  // ... other test setup
});
```

## Authoring Tool Integration

### Workflow
1. **Design**: Create flows visually in React Flow interface (`npm start`)
2. **Group**: Organize nodes into groups (become sequences)
3. **Connect**: Add cross-sequence navigation with auto-detection
4. **Export**: Use "🚀 Export to Flutter" → place in `assets/sequences/`
5. **Configure**: Add to `AppConstants.availableSequences`

## Development Notes

### Current Sequences (7 total)
Default start: `welcome_seq` → routes to appropriate user flow
- **onboarding_seq** - New user setup → taskSetting_seq → sendoff_seq  
- **taskChecking_seq** - Returning users → success_seq/failure_seq/taskSetting_seq
- **taskSetting_seq** - Daily planning → sendoff_seq
- **sendoff_seq** - Session conclusion
- **success_seq/failure_seq** - Task completion handling

### Adding Sequences
1. **Authoring Tool** (preferred): Design → Group → Export → Configure
2. **Manual**: Create JSON → Add to `AppConstants.availableSequences` → Add display name

### Debug Panel Features
- **Chat Controls**: Reset, clear messages, reload sequence
- **Test Scenarios**: 8 predefined scenarios in `assets/debug/scenarios.json`
- **Variable Editing**: Inline editing with type-aware inputs
- **Date/Time Testing**: Task date and deadline selection for testing
- **Sequence Selection**: Switch between sequences for testing
- **Notification Debug**: 
  - **Permission Status**: Visual indicators with color-coded states and actionable suggestions
  - **App State Tracking**: Real-time notification tap event monitoring and cross-session persistence
  - **Enhanced Controls**: Permission checking, state clearing, and comprehensive notification management

## Data Actions
JSON format for modifying user data:
```json
{
  "id": 1,
  "type": "dataAction",
  "action": {
    "type": "increment", // set, increment, decrement, reset, trigger
    "key": "user.streak",
    "value": 1
  }
}
```

### Test Notification Showcase
Use the `show_test_notification` trigger to demonstrate notifications to users:
```json
{
  "id": "demo_notification",
  "type": "dataAction",
  "action": {
    "type": "trigger",
    "event": "show_test_notification",
    "data": {
      "title": "Demo Notification",
      "subtitle": "Custom subtitle text",
      "body": "This is how notifications look on your device!",
      "delaySeconds": 3
    }
  }
}
```

**Parameters:**
- `title` (optional): Notification title, defaults to "Demo Notification"
- `subtitle` (optional): Notification subtitle, defaults to semantic content based on notification type
- `body` (optional): Notification body, defaults to "This is how notifications look on your device!"
- `delaySeconds` (optional): Delay before showing notification, defaults to 3 seconds

**Usage in conversation flow:**
1. Bot message: "Let me show you what a notification looks like..."
2. Data action triggers test notification
3. Follow-up message: "Check your device - you should see a notification!"

**Requirements:**
- Must test on real device (notifications don't work in simulator)
- User must have notification permissions granted
- Works while app is running or in background

## Case Transformations

The templating system supports case transformations that can be applied to any template variable:

### Case Transformation Types
- **`upper`**: ALL UPPERCASE
- **`lower`**: all lowercase
- **`proper`**: First Letter Of Each Word Capitalized
- **`sentence`**: First letter only capitalized

### Usage Examples

#### Basic Case Transformations
```
{user.name:upper} → "JOHN DOE"
{user.name:lower} → "john doe"
{user.name:proper} → "John Doe"
{user.name:sentence} → "John doe"
```

#### Combined with Formatters
```
{session.timeOfDay:timeOfDay:upper} → "MORNING"
{user.intensity:intensity:proper} → "High"
```

#### Combined with Array Joining
```
{task.activeDays:activeDays:join:upper} → "MONDAY, TUESDAY AND WEDNESDAY"
{task.activeDays:activeDays:join:proper} → "Monday, Tuesday And Wednesday"
{task.activeDays:activeDays:join:lower} → "monday, tuesday and wednesday"
```

#### With Fallback Values
```
{user.name:upper|ANONYMOUS} → "ANONYMOUS" (if user.name missing)
{missing.key:lower|default text} → "default text" (case applied to fallback)
```

### Processing Order
1. **Get raw value** from storage
2. **Apply base formatter** (timeOfDay, activeDays, etc.)
3. **Apply join flag** (if array, create grammatical sentence)
4. **Apply case transformation** (upper, lower, proper, sentence)
5. **Use fallback** (if any step failed, case transformation applied to fallback too)

## Quick Reference
- **Default sequence**: `welcome_seq` 
- **Configuration**: Add sequences to `AppConstants.availableSequences`
- **Cross-sequence navigation**: Use `sequenceId` field in choices
- **Template syntax**: `{key|fallback}` for dynamic text
- **Multi-text**: Use `|||` separator for multiple message bubbles

## Development Warnings
- Do not test a build on iphone wireless, favor chrome runtime or iPhone 16 when available

## Notification Development Guidelines

### Permission Handling Best Practices
- **Always check permission status** before attempting to schedule notifications using `getPermissionStatus()`
- **Request permissions only when needed** - use `shouldRequestPermissions` property to determine timing
- **Handle denied permissions gracefully** - guide users to Settings when `needsManualSettings` is true
- **Track permission history** - system automatically stores request count and timestamps for debugging

### Cross-Platform Considerations
- **iOS**: Cannot check permission status without requesting; rely on stored status from previous requests
- **Android**: Similar limitations to iOS; use stored status for accurate state tracking  
- **macOS**: Supports permission checking; treat as "other platform" in permission logic
- **All Platforms**: Use fallback logic for past dates in scheduling (automatic next-active-date calculation)

### Tap Event Handling
- **Rich Context**: Notification payloads include JSON data with scheduling context, task dates, and notification type
- **Cross-Session Support**: AppStateService persists tap events across app launches - always check for pending events on startup
- **Type Detection**: Events automatically determine type from payload JSON or fallback to notification ID-based detection
- **Debugging**: Use debug panel to monitor tap events and inspect payload data in real-time

### Testing Notifications
- **Use Mock Services**: Test files include MockUserDataService for isolated testing without platform dependencies
- **Platform Simulation**: Tests handle platform-specific failures gracefully with try-catch patterns
- **State Persistence**: Verify cross-session functionality by testing AppStateService persistence methods
- **Permission Edge Cases**: Test all 5 permission states and transitions between them 