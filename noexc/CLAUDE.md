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

### Key Components

#### Models (`lib/models/`)
- **ChatMessage** - Core message model with multi-text support using `|||` separator
- **ChatSequence** - Container for complete conversation flows
- **Choice** - User interaction options with optional custom values
- **RouteCondition** - Conditional routing logic

#### Services (`lib/services/`)
- **ChatService** - Main service for loading sequences and processing messages
- **UserDataService** - Local storage using shared_preferences
- **TextTemplatingService** - Template processing with `{key|fallback}` syntax
- **TextVariantsService** - Random text variation from asset files
- **ConditionEvaluator** - Evaluates routing conditions

#### UI Architecture (`lib/widgets/`)
- **ChatScreen** - Main container with state management
- **ChatStateManager** - Handles all chat state and message flow
- **ChatMessageList** - Displays messages with automatic scrolling
- **UserPanelOverlay** - Debug panel for user data and sequence management

### Data Flow
1. **Sequence Loading**: JSON files from `assets/sequences/` loaded by ChatService
2. **Message Processing**: Templates processed, variants applied, multi-text expanded
3. **User Interactions**: Choices and text inputs stored via UserDataService
4. **Conditional Routing**: Auto-routes evaluate conditions and switch sequences

### Asset Structure
- `assets/sequences/` - JSON conversation flows
- `assets/variants/` - Text variant files (format: `{sequenceId}_message_{messageId}.txt`)
- Available sequences defined in `AppConstants.availableSequences`
- Current sequences: onboarding, tutorial, support, menu, autoroute_test, custom_value_demo, comparison_demo, multi_text_demo

### Storage System
- **Local Storage**: Uses shared_preferences for user data persistence
- **Template System**: `{key|fallback}` syntax for dynamic text substitution
- **Data Keys**: Dot notation supported (e.g., `user.name`, `preferences.theme`)

### Multi-Text Messages
- Use `|||` separator to split single message into multiple bubbles
- Example: `"Welcome! ||| Let me show you around. ||| This will be fun!"`
- Templates and variants processed before expansion
- Each part displays as separate message bubble with same delay

### Conditional Routing
- **Auto-route messages** with `isAutoRoute: true` evaluate conditions
- Support for `==`, `!=`, `>`, `<`, `>=`, `<=`, null checks, and boolean evaluation
- Numeric comparisons with automatic type conversion
- Route to different sequences or continue in current sequence
- Always include default route as fallback

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
  - Integration tests for chat functionality
  - User data storage and templating services (`test/services/`)
- Use `flutter test` to run tests
- Test files mirror the `lib/` directory structure in `test/`
- Import main app code using `package:noexc/main.dart`
- **Current test status: 109 passing tests** (100% success rate)
- Aim for high test coverage (minimum 80%) - Currently at 100% success rate
- Never commit code without corresponding tests

## Development Notes

### Adding New Sequences
1. Create JSON file in `assets/sequences/`
2. Add sequence ID to `AppConstants.availableSequences`
3. Add display name to `ChatConfig.sequenceDisplayNames`

### Message Types
- **Basic**: Simple bot/user messages
- **Choice**: Present buttons with optional data storage
- **Text Input**: Collect user input with storage
- **Auto-route**: Invisible conditional routing
- **Multi-text**: Multiple messages from single JSON entry

### Template Syntax
- `{key}` - Use stored value or leave unchanged
- `{key|fallback}` - Use stored value or fallback if not found
- Supports nested keys like `user.name`, `preferences.theme`

### Debugging
- Use debug panel (bug icon) to view user data and manage sequences
- **Chat Controls**: Reset Chat, Clear Messages, Reload Sequence buttons
- **Data Management**: "Clear All Data" removes all stored user data (with confirmation)
- **Sequence Selection**: Dropdown to switch between sequences
- Current sequence and message count displayed in panel

### Custom Value Storage
- **Choice.value field**: Store clean values separate from display text
- Example: `{"text": "I'm a beginner", "value": "beginner"}`
- Supports strings, booleans, numbers, and null values
- Backward compatible - uses text if no value provided
- Better for conditions and internationalization