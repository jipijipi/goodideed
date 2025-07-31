# Gemini Agent Project Analysis: noexc

This document provides a summary of the `noexc` project to guide the Gemini agent in development. It is based on an analysis of the project structure and existing agent documentation (`.agent.md`, `CLAUDE.md`).

## 1. Project Overview

`noexc` is a cross-platform accountability and habit-tracking application built with Flutter. It features a conversational AI companion ("Tristopher") that interacts with users through a sequence-based chat system. The core functionality revolves around setting, tracking, and managing daily tasks.

A key component of the project is the `noexc-authoring-tool`, a separate web-based application built with React and TypeScript. This tool provides a visual, node-based editor (using React Flow) for creating and managing the conversational JSON sequences used by the Flutter app.

## 2. Technology Stack

- **Main Application (noexc):**
  - **Framework:** Flutter
  - **Language:** Dart
  - **State Management:** `ChangeNotifier`
  - **Local Storage:** `shared_preferences`
  - **Testing:** `flutter_test`

- **Authoring Tool (noexc-authoring-tool):**
  - **Framework:** React
  - **Language:** TypeScript
  - **UI Library:** React Flow
  - **Build Tool:** Create React App (`react-scripts`)

## 3. Project Structure

- **/lib**: Main Dart source code for the Flutter application.
  - `main.dart`: Application entry point.
  - `models/`: Data models (e.g., `ChatMessage`, `ChatSequence`).
  - `services/`: Business logic (e.g., `ChatService`, `UserDataService`, `SessionService`).
  - `widgets/`: Reusable UI components.
  - `validation/`: Logic for validating assets and sequences.
- **/test**: Unit and widget tests for the Flutter app. The structure mirrors the `/lib` directory.
- **/assets**: Static assets for the Flutter app.
  - `sequences/`: JSON files defining the conversation flows. (7 core sequences: welcome_seq, onboarding_seq, taskChecking_seq, taskSetting_seq, sendoff_seq, success_seq, failure_seq)
  - `content/`: Semantic content system (actor/action/subject structure).
  - `variants/`: Text files with alternative phrasings for messages to add variety.
  - `debug/`: Contains `scenarios.json` for setting up specific user states for testing.
- **/noexc-authoring-tool**: The React/TypeScript project for the visual authoring tool.
- **pubspec.yaml**: Flutter project manifest, defining dependencies and assets.
- **analysis_options.yaml**: Dart static analysis and linting rules.

## 4. Development Workflow & Commands

### Flutter Application

- **Install Dependencies:** `flutter pub get`
- **Run the App:** `flutter run`
- **Run Tests:** `flutter test`
  - **TDD is a strict requirement for this project.** New features must be preceded by failing tests.
- **Static Analysis:** `flutter analyze`
- **Build:** `flutter build apk/ios/web`

#### TDD-Optimized Test Commands
- **Quick TDD Testing (Minimal Output):**
    - `dart tool/tdd_runner.dart --quiet test/services/specific_test.dart` - Single file, minimal output
    - `dart tool/tdd_runner.dart -q test/models/` - Directory testing with minimal noise
    - `dart tool/tdd_runner.dart --name "specific test pattern"` - Target specific tests
    - `flutter test --reporter compact test/specific_test.dart` - Built-in compact reporter
- **Focused Testing Strategies:**
    - `flutter test test/services/logger_service_test.dart` - Single service test
    - `flutter test test/models/ --concurrency=2` - Directory with limited concurrency
    - `flutter test --name "should handle errors"` - Pattern-based test selection
    - `flutter test --tags tdd` - Run only TDD-tagged tests

### Authoring Tool (`noexc-authoring-tool`)

- **Install Dependencies:** `cd noexc-authoring-tool && npm install`
- **Run Development Server:** `npm start`
- **Run Tests:** `npm test`

## 5. Key Architectural Concepts & Conventions

### Core Architecture
- **Sequence-Based Conversations:** The app's logic is driven by JSON files in `assets/sequences/`. These files define messages, user choices, conditional routing (`autoroute`), and data manipulation (`dataAction`).
- **Visual Authoring:** The recommended way to create or modify sequences is through the `noexc-authoring-tool`, which exports compatible JSON.
- **Test-Driven Development (TDD):** The project has extensive test coverage, and all new development must follow the Red-Green-Refactor cycle. Do not commit code without corresponding tests.
- **Comprehensive Debug Panel:** The Flutter app includes a powerful debug panel accessible from the app bar.
- **Variable Management:**
    - Variables are stored using dot notation (e.g., `user.name`, `task.deadlineTime`).
    - All variable keys should be defined and centralized in `lib/constants/storage_keys.dart`.
    - Naming convention is strictly `camelCase`.
- **Modular Services:** Business logic is separated into single-responsibility services (e.g., `ChatService`, `SessionService`, `DataActionProcessor`).
- **Error Handling:** The app has a dedicated error handling system to manage exceptions gracefully.
- **Documentation Maintenance:** This `GEMINI.md` file, along with `.agent.md` and `CLAUDE.md`, should be kept up-to-date with any significant architectural changes, new dependencies, or modified development practices.

### Critical Rules
- **Logging (MANDATORY):**
    - ⚠️ **NEVER use print() statements - ALWAYS use LoggerService** ⚠️
    - Import: `final logger = LoggerService();`
    - Levels: `debug()`, `info()`, `warning()`, `error()`, `critical()`
    - Component methods: `logger.route()`, `logger.semantic()`, `logger.ui()`
- **Testing (TDD Required):**
    - **ALWAYS use Test-Driven Development** (Red-Green-Refactor cycle).
    - Write tests BEFORE implementing functionality.
    - **290+ passing tests** across models, services, widgets, validation.
    - Test files mirror `lib/` directory structure in `test/`.
    - Never commit code without corresponding tests.
    - For minimal test output, use `setupQuietTesting()` from `test/test_helpers.dart`.

### Key Features
- **Storage & Templates:**
    - **Local Storage:** `shared_preferences` for user data persistence.
    - **Template System:** `{key|fallback}` syntax for dynamic text substitution.
    - **Formatter Support:** `{key:formatter}` and `{key:formatter|fallback}` syntax (e.g., `timeOfDay`, `intensity`, `activeDays`).
    - **Key Task Variables:** `task.currentDate`, `task.currentStatus`, `task.deadlineTime`, `task.isActiveDay`, `task.isPastDeadline`.
- **Message System:**
    - **Multi-text messages:** Use `|||` separator for multiple bubbles.
    - **MessageType enum:** `bot`, `user`, `choice`, `textInput`, `autoroute`, `dataAction`.
    - **Conditional routing:** Auto-routes with compound conditions (`&&`, `||`).
- **Semantic Content System:**
    - Dynamic content system using semantic keys like `bot.acknowledge.completion.positive`.
    - **Graceful fallbacks:** 8-level fallback chain ensures content always resolves.
    - **File structure:** `assets/content/` organized by actor/action/subject.
    - **Usage:** Add `contentKey` field to messages for dynamic text resolution.
- **Session Tracking:**
    - `SessionService` automatically tracks user data on app start.
    - **Key Session Variables:** `session.visitCount`, `session.totalVisitCount`, `session.timeOfDay`, `session.isWeekend`.
    - **Task Management:** Automatic date initialization, status updates, and deadline checking.

### Authoring Tool Integration
1.  **Design**: Create flows visually in React Flow interface (`npm start`).
2.  **Group**: Organize nodes into groups (which become sequences).
3.  **Connect**: Add cross-sequence navigation with auto-detection.
4.  **Export**: Use "🚀 Export to Flutter" and place the JSON in `assets/sequences/`.
5.  **Configure**: Add the new sequence to `AppConstants.availableSequences`.

### Debug Panel
- **Chat Controls**: Reset, clear messages, reload sequence.
- **Test Scenarios**: 8 predefined scenarios in `assets/debug/scenarios.json`.
- **Variable Editing**: Inline editing with type-aware inputs.
- **Date/Time Testing**: Task date and deadline selection for testing.
- **Sequence Selection**: Switch between sequences for testing.

### Data Actions
JSON format for modifying user data within a sequence:
` + "```" + `json
{
  "id": 1,
  "type": "dataAction",
  "action": {
    "type": "increment", // set, increment, decrement, reset, trigger
    "key": "user.streak",
    "value": 1
  }
}
` + "```" + `