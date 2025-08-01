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

#### Models & Message Types
- **MessageType enum**: bot, user, choice, textInput, autoroute, dataAction
- **ChatMessage** - Core message model with multi-text support (`|||`)
- **Choice** - User interaction options with optional custom values
- **DataAction** - Data modification operations (set, increment, decrement, reset, trigger)

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

## Critical Rules

### Logging (MANDATORY)
⚠️ **NEVER use print() statements - ALWAYS use LoggerService** ⚠️
- Import: `final logger = LoggerService();`
- Levels: `debug()`, `info()`, `warning()`, `error()`, `critical()`
- Component methods: `logger.route()`, `logger.semantic()`, `logger.ui()`

### Testing (TDD Required)
- **ALWAYS use Test-Driven Development** (Red-Green-Refactor cycle)
- Write tests BEFORE implementing functionality
- **290+ passing tests** across models, services, widgets, validation
- Test files mirror `lib/` directory structure in `test/`
- Never commit code without corresponding tests

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

## Quick Reference
- **Default sequence**: `welcome_seq` 
- **Configuration**: Add sequences to `AppConstants.availableSequences`
- **Cross-sequence navigation**: Use `sequenceId` field in choices
- **Template syntax**: `{key|fallback}` for dynamic text
- **Multi-text**: Use `|||` separator for multiple message bubbles

## Development Warnings
- Do not test a build on iphone wireless, favor chrome runtime or iPhone 16 when available 