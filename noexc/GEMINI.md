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
  - `sequences/`: JSON files defining the conversation flows.
  - `variants/`: Text files with alternative phrasings for messages to add variety.
  - `debug/`: Contains `scenarios.json` for setting up specific user states for testing.
- **/noexc-authoring-tool**: The React/TypeScript project for the visual authoring tool.
- **pubspec.yaml**: Flutter project manifest, defining dependencies and assets.
- **analysis_options.yaml**: Dart static analysis and linting rules.

## 4. Development Workflow

### Flutter Application

- **Install Dependencies:** `flutter pub get`
- **Run the App:** `flutter run`
- **Run Tests:** `flutter test`
  - **TDD is a strict requirement for this project.** New features must be preceded by failing tests.
- **Static Analysis:** `flutter analyze`

### Authoring Tool (`noexc-authoring-tool`)

- **Install Dependencies:** `cd noexc-authoring-tool && npm install`
- **Run Development Server:** `npm start`
- **Run Tests:** `npm test`

## 5. Key Architectural Concepts & Conventions

- **Sequence-Based Conversations:** The app's logic is driven by JSON files in `assets/sequences/`. These files define messages, user choices, conditional routing (`autoroute`), and data manipulation (`dataAction`).
- **Visual Authoring:** The recommended way to create or modify sequences is through the `noexc-authoring-tool`, which exports compatible JSON.
- **Test-Driven Development (TDD):** The project has extensive test coverage, and all new development must follow the Red-Green-Refactor cycle. Do not commit code without corresponding tests.
- **Comprehensive Debug Panel:** The Flutter app includes a powerful debug panel accessible from the app bar. It allows for:
    - Viewing and editing user data variables.
    - Switching between different test scenarios (`scenarios.json`).
    - Manually selecting and loading chat sequences.
    - Resetting chat state and user data.
- **Variable Management:**
    - Variables are stored using dot notation (e.g., `user.name`, `task.deadlineTime`).
    - All variable keys should be defined and centralized in `lib/constants/storage_keys.dart`.
    - Naming convention is strictly `camelCase`.
- **Modular Services:** Business logic is separated into single-responsibility services (e.g., `ChatService`, `SessionService`, `DataActionProcessor`).
- **Error Handling:** The app has a dedicated error handling system to manage exceptions gracefully.
- **Documentation Maintenance:** This `GEMINI.md` file, along with `.agent.md` and `CLAUDE.md`, should be kept up-to-date with any significant architectural changes, new dependencies, or modified development practices.
