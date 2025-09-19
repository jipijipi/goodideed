# noexc - Habit Tracking Chat App

A cross-platform **habit tracking and motivational app** built with **Flutter**, designed to encourage consistency through gamification, humor, and conversational interaction. The app combines **Rive interactive animations**, a witty **jantagonist character**, and a dynamic conversation system for personalized experiences.

## Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Node.js (for authoring tool)
- iOS/Android development environment

### Run the App
```bash
flutter run
```

### Run the Authoring Tool
```bash
cd noexc-authoring-tool
npm start
```

### Run Tests
```bash
flutter test
# Or for minimal output during TDD:
dart tool/tdd_runner.dart --quiet test/
```

## Key Features

### 🎯 **Sequence-Based Conversations**
- Dynamic conversation flows loaded from JSON
- Multi-text messages with `|||` separator
- Template system with `{key|fallback}` syntax
- Conditional routing based on user data

### 📱 **Smart Notifications**
- Context-aware reminder system
- Platform-specific permission handling
- Rich notification payloads with tap events
- Cross-session state persistence

### 🎨 **Rive Animation System**
- 4-zone layered animation system
- Data-bound interactive animations
- Script-triggered overlay effects
- Template-integrated dynamic content

### 💾 **Local Data Management**
- SharedPreferences-based storage
- Session tracking with daily reset
- Task calculation with active day logic
- Semantic content resolution

### 🛠 **Visual Authoring Tool**
- React Flow-based conversation designer
- Group-based sequence organization
- Cross-sequence navigation
- Direct Flutter JSON export

## Architecture Overview

### Core Services
- **ChatService** - Main conversation orchestrator
- **UserDataService** - Local storage management
- **SessionService** - Session and task tracking
- **NotificationService** - Platform notification handling
- **SemanticContentService** - Dynamic content resolution
- **LoggerService** - Centralized logging (NEVER use print!)

### Message Types
- `bot` - Bot responses with optional animations
- `user` - User text input
- `choice` - Multiple choice interactions
- `textInput` - Free text input
- `autoroute` - Automatic routing based on conditions
- `dataAction` - Data modification operations

### File Structure
```
lib/
├── models/           # Data models and enums
├── services/         # Core business logic
├── ui/              # Widgets and screens
└── utils/           # Utilities and helpers

assets/
├── sequences/       # JSON conversation flows
├── content/         # Semantic content system
└── animations/      # Rive animation files

docs/               # Comprehensive documentation
noexc-authoring-tool/  # React Flow authoring interface
```

## Development

### Commands
```bash
# Essential commands
flutter run          # Run the app
flutter test         # Run all tests
flutter analyze      # Static analysis
flutter build apk    # Build for Android

# TDD-optimized testing
dart tool/tdd_runner.dart --quiet test/services/
flutter test --reporter compact test/specific_test.dart
```

### Documentation
- **[Developer Guide](CLAUDE.md)** - Comprehensive development instructions
- **[Documentation Index](docs/README.md)** - Organized documentation hub
- **[Architecture Docs](docs/architecture/)** - System design and specifications
- **[Authoring Guides](docs/authoring/)** - Content creation workflows

### Key Principles
- **Test-Driven Development** - Write tests before implementation
- **LoggerService Only** - Never use print() statements
- **Template-Driven Content** - Use `{key|fallback}` syntax
- **Semantic Content** - Leverage dynamic content resolution

## Getting Started

1. **Clone and Setup**
   ```bash
   git clone <repository>
   cd noexc
   flutter pub get
   ```

2. **Understand the Flow**
   - Read [CLAUDE.md](CLAUDE.md) for development guidelines
   - Explore [docs/](docs/) for detailed documentation
   - Check debug panel for testing scenarios

3. **Try the Authoring Tool**
   ```bash
   cd noexc-authoring-tool
   npm install
   npm start
   ```

4. **Run Tests**
   ```bash
   flutter test
   # 350+ passing tests across all components
   ```

## Contributing

- Follow TDD practices
- Use LoggerService for all logging
- Test on real devices for notifications
- Update documentation with changes
- Maintain code style consistency

## License

[Add your license information here]
