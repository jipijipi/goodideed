# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Commands
- `flutter run` - Run the app on connected device/emulator
- `flutter test` - Run all unit tests
- `flutter analyze` - Run static analysis and linting
- `flutter pub get` - Install dependencies
- `flutter pub outdated` - Check for outdated dependencies

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app

### Testing Commands
- `flutter test test/models/` - Run model tests only
- `flutter test test/services/` - Run service tests only
- `flutter test test/widgets/` - Run widget tests only

## Architecture Overview

### Core Architecture
This is a Flutter chat app with a **sequence-based conversation system** that supports:
- **Dynamic message sequences** loaded from JSON files
- **User data storage** with template substitution
- **Multi-text messages** with separator-based splitting
- **Text variants** for dynamic content
- **Conditional routing** based on user attributes
- **Choice-based interactions** with data persistence

### React Flow Authoring Tool
Located in `noexc-authoring-tool/`, this is a **visual authoring tool** for creating conversation sequences:

#### Purpose
- **Visual Flow Creation**: Drag-and-drop interface for building conversation flows
- **Cross-Sequence Navigation**: Create complex multi-sequence workflows with visual connections
- **Flutter Export**: Export groups as JSON sequences compatible with the Flutter chat app

#### Key Features
- **Node Types**: Bot messages, user responses, choices, text inputs, auto-routes, data actions
- **Group System**: Organize nodes into groups that become separate sequences
- **Cross-Sequence Edges**: Visual connections between groups with auto-detection
- **Real-time Validation**: Live validation of flow structure and requirements
- **Export Integration**: Direct export to Flutter-compatible JSON format
- **Content Management**: Semantic contentKey fields for nodes and edges for robust referencing
- **Edge Properties**: Advanced edge customization with labels, values, contentKeys, delays, and styling

#### Architecture
- **React Flow**: Built on ReactFlow library for node-based editing
- **TypeScript**: Fully typed with comprehensive interfaces
- **Custom Components**: EditableNode, GroupNode, CustomEdge components
- **Validation System**: Comprehensive validation rules for export integrity

#### Development Commands
- `cd noexc-authoring-tool && npm start` - Run authoring tool development server
- `cd noexc-authoring-tool && npm run build` - Build authoring tool for production
- `cd noexc-authoring-tool && npm test` - Run authoring tool tests

#### Cross-Sequence Navigation
The authoring tool supports advanced cross-sequence navigation:
- **Auto-Detection**: Edges between different groups automatically create cross-sequence navigation
- **Explicit Syntax**: Removed `@sequence_id` syntax - now uses auto-detection only
- **Validation**: Ensures all cross-sequence references are valid
- **Export**: Groups export as separate sequence files with proper `sequenceId` fields

#### Recent Updates (2025)
- **Edge ContentKey System**: Added semantic contentKey field to edges for robust choice/condition referencing
- **Edge Value System**: Moved choice values from parsed labels to dedicated value fields for safety
- **Visual Edge Display**: Enhanced edge rendering with Label → ContentKey → Value → Delay display order
- **Export/Import Integrity**: Fixed JSON import/export discrepancy that added unwanted group metadata to regular nodes
- **Edge Properties Panel**: Added comprehensive edge properties panel with data/style property organization and bottom padding
- **Delete-on-Drop Disabled**: Removed accidental edge deletion when reconnecting edges

### Key Components

#### Models (`lib/models/`)
- **ChatMessage** - Core message model with MessageType enum, multi-text support using `|||` separator
- **ChatSequence** - Container for complete conversation flows
- **Choice** - User interaction options with optional custom values
- **RouteCondition** - Conditional routing logic
- **MessageType** - Enum defining message types: bot, user, choice, textInput, autoroute, dataAction
- **DataAction** - Model for data modification operations (set, increment, decrement, reset, trigger)

#### Services (`lib/services/`)
- **ChatService** - Main orchestrator for chat functionality with focused processors:
  - `chat_service/sequence_loader.dart` - Handles sequence loading and management
  - `chat_service/message_processor.dart` - Processes message templates and user interactions
  - `chat_service/route_processor.dart` - Handles autoroute and dataAction processing
- **UserDataService** - Local storage using shared_preferences
- **SessionService** - Session tracking with daily reset functionality
- **TextTemplatingService** - Template processing with `{key|fallback}` syntax
- **TextVariantsService** - Random text variation from asset files
- **ConditionEvaluator** - Evaluates routing conditions with compound logic support (&&, ||)
- **ErrorHandler** - Centralized error handling with modular components:
  - `error_handling/chat_error_types.dart` - Error type classifications
  - `error_handling/chat_exceptions.dart` - Custom exception classes
  - `error_handling/error_classifier.dart` - Classifies errors by type and severity
  - `error_handling/user_message_generator.dart` - Generates user-friendly error messages
- **DataActionProcessor** - Processes data modification operations and event triggers
- **MessageQueue** - Sequential message processing with proper timing and no race conditions

#### UI Architecture (`lib/widgets/`)
- **ChatScreen** - Main container with state management
- **ChatStateManager** - Orchestrates chat state through focused managers:
  - `state_management/service_manager.dart` - Manages service lifecycle and dependencies
  - `state_management/message_display_manager.dart` - Handles message display and queue management
  - `state_management/user_interaction_handler.dart` - Processes user choices and text inputs
- **ChatMessageList** - Displays messages with automatic scrolling
- **UserPanelOverlay** - Debug panel for user data and sequence management

#### Validation System (`lib/validation/`)
- **AssetValidator** - Comprehensive asset validation with modular validators:
  - `asset_validators/sequence_file_validator.dart` - Validates sequence JSON structure
  - `asset_validators/variant_file_validator.dart` - Validates variant text files
  - `asset_validators/template_variable_validator.dart` - Validates template variable usage
  - `asset_validators/cross_reference_validator.dart` - Validates cross-references between files
  - `asset_validators/json_schema_validator.dart` - JSON schema validation

### Data Flow
1. **Sequence Loading**: JSON files from `assets/sequences/` loaded by ChatService
2. **Message Processing**: Templates processed, variants applied, multi-text expanded
3. **User Interactions**: Choices and text inputs stored via UserDataService
4. **Conditional Routing**: Auto-routes evaluate conditions and switch sequences

### Asset Structure
- `assets/sequences/` - JSON conversation flows
- `assets/variants/` - Text variant files (format: `{sequenceId}_message_{messageId}.txt`)
- Available sequences defined in `AppConstants.availableSequences`
- Current sequences: welcome_seq, onboarding_seq, taskChecking_seq, taskSetting_seq, sendoff_seq, success_seq, failure_seq, task_config_seq, task_config_test_seq, day_tracking_test_seq

### Storage System
- **Local Storage**: Uses shared_preferences for user data persistence
- **Template System**: `{key|fallback}` syntax for dynamic text substitution
- **Data Keys**: Dot notation supported (e.g., `user.name`, `preferences.theme`)
- **Task Storage Keys**: Comprehensive task management with dedicated storage keys:
  - `task.currentDate` - Current task date (YYYY-MM-DD format)
  - `task.status` - Task status (pending, completed, failed)
  - `task.deadlineTime` - Deadline option (1-4 integer values)
  - `task.isActiveDay` - Computed boolean for active day status
  - `task.isPastDeadline` - Computed boolean for deadline status
  - `task.previousDate` - Previous day's task date for archiving
  - `task.gracePeriodUsed` - Boolean for grace period tracking

### Multi-Text Messages
- Use `|||` separator to split single message into multiple bubbles
- Example: `"Welcome! ||| Let me show you around. ||| This will be fun!"`
- Templates and variants processed before expansion
- Each part displays as separate message bubble with same delay

### Conditional Routing
- **Auto-route messages** with `"type": "autoroute"` evaluate conditions
- Support for `==`, `!=`, `>`, `<`, `>=`, `<=`, null checks, and boolean evaluation
- **Compound conditions** with `&&` (AND) and `||` (OR) operators
- Numeric comparisons with automatic type conversion
- Route to different sequences or continue in current sequence
- Always include default route as fallback

### Session Tracking & Task Management
- **SessionService** automatically tracks user session data on app start
- **Daily Visit Count** (`session.visitCount`) - Resets to 1 each new day, increments for same-day visits
- **Total Visit Count** (`session.totalVisitCount`) - Never resets, tracks lifetime app launches
- **Time of Day** (`session.timeOfDay`) - 1=morning, 2=afternoon, 3=evening, 4=night
- **Date Tracking** (`session.lastVisitDate`, `session.firstVisitDate`, `session.daysSinceFirstVisit`)
- **Weekend Detection** (`session.isWeekend`) - Boolean for Saturday/Sunday
- **Task Date Management**: Automatic task date initialization and archiving
  - New day detection with task date updates
  - Previous day task archiving with grace period handling
  - Task status preservation across sessions
- **Automatic Status Updates**: Enhanced automatic status updates with deadline checking
  - Task status transitions based on deadlines and completion
  - Grace period tracking for task completion
  - Logging for debugging status changes
- **Use Cases**: 
  - `session.visitCount > 1` - Returning daily user (visited app multiple times today)
  - `session.totalVisitCount >= 10` - Experienced user (used app 10+ times total)
  - `session.timeOfDay == 1` - Morning user
  - `session.isWeekend == true` - Weekend user
  - `task.isActiveDay == true` - Today is configured as an active day
  - `task.isPastDeadline == true` - Current time is past user's deadline

### Text Variants
- Random text variations loaded from `assets/variants/`
- NOT applied to choice messages, text inputs, auto-routes, or multi-text messages
- Supports separator-formatted variants for consistency
- Cached for performance

### Testing (Test-Driven Development Required)
- **ALWAYS use Test-Driven Development (TDD)** for this project
- Write tests BEFORE implementing functionality (Red-Green-Refactor cycle)
- Follow TDD workflow:
  1. **Red**: Write a failing test that describes the desired behavior
  2. **Green**: Write the minimum code to make the test pass
  3. **Refactor**: Improve the code while keeping tests green
- **Comprehensive test coverage implemented**:
  - Widget tests for UI components (`test/widgets/`)
  - Unit tests for business logic and data models (`test/models/`, `test/services/`)
  - Integration tests for chat functionality and daily reset scenarios
  - User data storage and templating services (`test/services/`)
  - Validation system tests (`test/validation/`)
  - Error handling and edge case testing
  - **Task management tests** with comprehensive coverage:
    - Task boolean computation tests (14 tests for isActiveDay/isPastDeadline)
    - Automatic status updates tests (complex deadline scenarios)
    - Previous day grace period tests (archiving and recovery)
    - DateTimePickerWidget tests (UI interaction and data flow)
    - Deadline format compatibility tests (integer vs string handling)
- Use `flutter test` to run tests
- Test files mirror the `lib/` directory structure in `test/`
- Import main app code using `package:noexc/main.dart`
- **Current test status: 290+ passing tests** (high success rate)
- Aim for high test coverage (minimum 80%) - Currently at high success rate
- Never commit code without corresponding tests

## Message Flow Architecture (Recently Fixed)

### Fixed Message Duplication Issue
The app previously had a 4x message duplication problem that was resolved through architectural improvements:

#### Root Cause
- **Double initialization** - `getInitialMessages()` called multiple times
- **Callback duplication** - Sequence switch callbacks creating parallel message flows
- **No coordination** - Multiple async message processing without synchronization

#### Solution Implemented
- **Single-flow architecture** - Removed sequence switch callbacks
- **Message accumulation** - `ChatService._getMessagesFromId()` handles all sequence switching internally
- **MessageQueue integration** - Proper sequential message processing with timing
- **Duplicate filtering** - Safety net at UI level to prevent any duplicates

#### Key Files Modified
- `lib/services/chat_service.dart` - Removed callback notifications, maintained message accumulation
- `lib/widgets/chat_screen/chat_state_manager.dart` - Removed callback setup, simplified initialization
- `lib/services/message_queue.dart` - Added for proper message sequencing

## Authoring Tool ↔ Flutter Integration

### Workflow Overview
1. **Design in Authoring Tool**: Create conversation flows visually using React Flow interface
2. **Organize into Groups**: Group related nodes to create logical sequences
3. **Add Cross-Sequence Navigation**: Connect groups with `@sequence_id` syntax or auto-detection
4. **Export to Flutter**: Use "🚀 Export to Flutter" button to generate JSON files
5. **Import to Flutter**: Place exported JSON files in `assets/sequences/` directory

### File Format Compatibility
The authoring tool exports JSON files that are **100% compatible** with the Flutter app's sequence format:

```json
{
  "sequenceId": "onboarding",
  "name": "User Onboarding",
  "description": "Initial user setup flow",
  "messages": [
    {
      "id": 1,
      "type": "bot",
      "text": "Welcome! How can I help you?",
      "nextMessageId": 2
    },
    {
      "id": 2,
      "type": "choice",
      "storeKey": "user.choice",
      "choices": [
        {
          "text": "Continue to Task Setting",
          "sequenceId": "taskSetting_seq"
        }
      ]
    }
  ]
}
```

### Cross-Sequence Features
- **sequenceId Field**: Enables navigation between different conversation sequences
- **Auto-Detection**: Authoring tool automatically detects cross-group connections
- **Validation**: Ensures all cross-sequence references are valid before export
- **Multiple Sequences**: One authoring session can export multiple related sequences

## Development Notes

### Current Sequence Structure (Updated)
The app now uses `welcome_seq` as the default starting sequence with a clean, focused architecture:

#### Active Sequences (7 total)
1. **welcome_seq** - Entry point with user routing logic
2. **onboarding_seq** - New user setup and introduction
3. **taskChecking_seq** - Daily task progress checking
4. **taskSetting_seq** - Daily task planning and goal setting
5. **sendoff_seq** - Session conclusion and wrap-up
6. **success_seq** - Task completion celebration
7. **failure_seq** - Task support and encouragement

#### Sequence Flow Map
```
welcome_seq (entry)
├── onboarding_seq → taskSetting_seq → sendoff_seq (new users)
└── taskChecking_seq → (returning users)
    ├── taskSetting_seq → sendoff_seq
    ├── success_seq → taskSetting_seq | sendoff_seq
    ├── sendoff_seq
    └── failure_seq → sendoff_seq | taskSetting_seq
```

### Adding New Sequences

#### Method 1: Using the Authoring Tool (Recommended)
1. Open the React Flow authoring tool (`cd noexc-authoring-tool && npm start`)
2. Create conversation flows visually with drag-and-drop
3. Organize nodes into groups for each sequence
4. Export using "🚀 Export to Flutter" button
5. Place exported JSON files in `assets/sequences/`
6. Add sequence IDs to `AppConstants.availableSequences`
7. Add display names to `ChatConfig.sequenceDisplayNames`

#### Method 2: Manual JSON Creation
1. Create JSON file manually in `assets/sequences/`
2. Follow the sequence format with proper message structure
3. Add sequence ID to `AppConstants.availableSequences`
4. Add display name to `ChatConfig.sequenceDisplayNames`

### Message Types
The app uses a **MessageType enum** system that replaces legacy boolean flags:

#### MessageType Enum Values
- **bot**: Simple bot messages (default)
- **user**: User messages
- **choice**: Present buttons with optional data storage
- **textInput**: Collect user input with storage
- **autoroute**: Invisible conditional routing
- **dataAction**: Data modification operations (set, increment, decrement, reset, trigger)

#### JSON Format
**New format** (preferred):
```json
{
  "id": 1,
  "type": "bot",
  "text": "Hello! How can I help you?"
}
```

**Legacy format** (backward compatible):
```json
{
  "id": 1,
  "isChoice": true,
  "text": "Choose an option:",
  "choices": [...]
}
```

#### Features
- **Backward Compatible**: Legacy boolean flags (`isChoice`, `isTextInput`, `isAutoRoute`) still work
- **Convenience Getters**: `isChoice`, `isTextInput`, `isAutoRoute` getters maintained for API compatibility
- **Multi-text Support**: Works with `|||` separator across all message types
- **Clean Architecture**: Single `type` field replaces multiple boolean flags

### Template Syntax
- `{key}` - Use stored value or leave unchanged
- `{key|fallback}` - Use stored value or fallback if not found
- Supports nested keys like `user.name`, `preferences.theme`

### Debugging
- Use debug panel (bug icon) to view user data and manage sequences
- **Chat Controls**: Reset Chat, Clear Messages, Reload Sequence buttons
- **Data Management**: "Clear All Data" removes all stored user data (with confirmation)
- **Sequence Selection**: Dropdown to switch between sequences
- **Date & Time Testing**: DateTimePickerWidget for testing task management features
  - Task date selection with quick preset options (today, yesterday)
  - Deadline option selection (Morning, Afternoon, Evening, Night)
  - Real-time display of computed boolean values (isActiveDay, isPastDeadline)
  - Integration with SessionService for immediate testing
- Current sequence and message count displayed in panel

### Custom Value Storage
- **Choice.value field**: Store clean values separate from display text
- Example: `{"text": "I'm a beginner", "value": "beginner"}`
- Supports strings, booleans, numbers, and null values
- Backward compatible - uses text if no value provided
- Better for conditions and internationalization

## Quick Win Opportunities

### High Priority Quick Wins (Recently Analyzed)
1. **UX/UI Improvements**: Loading indicators, message animations, haptic feedback
2. **Performance Optimizations**: Message caching, lazy loading, memory management
3. **Content Enhancements**: More sequence variants, smart features, user engagement
4. **Developer Experience**: Better tooling, automated testing, documentation
5. **Technical Infrastructure**: Error handling, monitoring, security improvements

### Implementation Priority
- **Phase 1**: Basic animations, loading states, performance monitoring
- **Phase 2**: Advanced UX features, content management, analytics
- **Phase 3**: Platform-specific features, community features, enterprise features

See detailed analysis for 80+ specific quick wins across all categories.

## Quick Reference

### Authoring Tool Commands
```bash
# Development
cd noexc-authoring-tool
npm start                    # Start development server (usually port 3003)
npm run build               # Build for production
npm test                    # Run tests

# Usage
# 1. Create nodes with Quick Create panel
# 2. Select multiple nodes with Shift+click to create groups
# 3. Double-click group info panels to edit metadata
# 4. Add cross-sequence edges with @sequence_id syntax
# 5. Export with "🚀 Export to Flutter" button
```

### Flutter App Commands
```bash
# Development
flutter run                 # Run app
flutter test                # Run all tests
flutter analyze            # Static analysis

# Sequences
# 1. Place exported JSON files in assets/sequences/
# 2. Add to AppConstants.availableSequences
# 3. Add display names to ChatConfig.sequenceDisplayNames
```

### Cross-Sequence Navigation Syntax
- `@sequence_id` - Jump to another sequence
- `choice::value` - Store choice value  
- `condition` - Auto-route condition
- `default` - Default route

## Data Action System

### DataAction Types
- **set**: Set a value in user data storage
- **increment**: Increment numeric values (default: +1)
- **decrement**: Decrement numeric values (default: -1)
- **reset**: Reset a value to 0 or null
- **trigger**: Fire events for achievements, notifications, etc.

### DataAction JSON Format
```json
{
  "id": 1,
  "type": "dataAction",
  "action": {
    "type": "increment",
    "key": "user.streak",
    "value": 1
  },
  "nextMessageId": 2
}
```

### Event Trigger System
```json
{
  "id": 3,
  "type": "dataAction",
  "action": {
    "type": "trigger",
    "event": "achievement_unlocked",
    "data": {
      "achievement": "first_streak",
      "title": "Getting Started",
      "description": "Started your first streak"
    }
  }
}
```

## Recent Major Changes (December 2024 - July 2025)

### Architecture Refactoring (July 2025)
- **ChatService Refactor**: Split into focused processors for better separation of concerns
  - `sequence_loader.dart` - Handles sequence loading and management
  - `message_processor.dart` - Processes message templates and user interactions  
  - `route_processor.dart` - Handles autoroute and dataAction processing
- **ChatStateManager Refactor**: Split into specialized state managers
  - `service_manager.dart` - Manages service lifecycle and dependencies
  - `message_display_manager.dart` - Handles message display and queue management
  - `user_interaction_handler.dart` - Processes user choices and text inputs
- **Error Handling System**: Modular error handling with user-friendly messaging
- **Validation System**: Comprehensive asset validation with focused validators
- **Benefits**: Improved testability, maintainability, and single responsibility principle

### Message Duplication Fix (December 2024)
- **Problem**: Messages displaying up to 4 times due to parallel processing
- **Solution**: Implemented single-flow architecture with MessageQueue
- **Files Modified**: ChatService, ChatStateManager, MessageQueue
- **Result**: Clean message flow with no duplication

### Sequence Architecture Cleanup
- **Changed default sequence**: `onboarding` → `welcome_seq`
- **Removed unused sequences**: 8 demo/test sequences deleted
- **Updated configuration**: AppConstants, ChatConfig, UI components
- **Result**: Clean, focused daily task management flow

### Task Boolean Computation System (July 2025)
- **Boolean Computation**: Added pre-computed boolean values for simplified conditional routing
  - `task.isActiveDay` - Computed based on user's configured active days
  - `task.isPastDeadline` - Computed based on current time vs user's deadline
- **Storage Integration**: New storage keys in `StorageKeys` class
- **SessionService Integration**: Automatic computation on session initialization via `_computeTaskBooleans()`
- **Debug Panel Enhancement**: Added display of computed boolean values in debug panel
- **Comprehensive Testing**: 14 new tests covering various scenarios and edge cases
- **Benefits**: Simplified JSON sequence conditions, better UX with consistent boolean logic

### Deadline Options System (July 2025)
- **Debug Panel Redesign**: Replaced time picker with preset deadline options
- **Option Mapping**: Mirror production sequence choices with integer values
  - 1: Morning (before noon)
  - 2: Afternoon (noon to 5pm)
  - 3: Evening (5pm to 9pm)
  - 4: Night (9pm to midnight)
- **UI Improvements**: Button-based selection interface with visual feedback
- **Morning Recovery Removal**: Eliminated flawed morning recovery logic for cleaner status transitions

### Key Configuration Changes
- `AppConstants.defaultSequenceId = 'welcome_seq'`
- `AppConstants.availableSequences` - reduced to 7 core sequences
- `ChatConfig.sequenceDisplayNames` - updated with user-friendly names
- Sequence selector icons updated for new sequences

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.