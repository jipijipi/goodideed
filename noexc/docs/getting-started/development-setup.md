# Development Setup

Complete development environment setup for the noexc project.

## System Requirements

### Flutter Development
- **Flutter SDK**: Latest stable version
- **Dart**: Comes with Flutter
- **IDE**: VS Code or Android Studio
- **Git**: Version control

### Platform-Specific Requirements

#### iOS Development
- **macOS**: Required for iOS development
- **Xcode**: Latest version from App Store
- **iOS Simulator**: Installed with Xcode
- **Apple Developer Account**: For device testing (optional)

#### Android Development
- **Android Studio**: Latest version
- **Android SDK**: API level 21+ (Android 5.0+)
- **Android Emulator**: AVD with API 21+
- **Java Development Kit**: OpenJDK 11+

### Authoring Tool
- **Node.js**: Version 16 or higher
- **npm**: Comes with Node.js

## Installation Steps

### 1. Install Flutter

#### macOS
```bash
# Using Homebrew
brew install flutter

# Or download from https://flutter.dev
```

#### Windows/Linux
Download from [flutter.dev](https://flutter.dev) and follow platform-specific instructions.

### 2. Verify Installation

```bash
flutter doctor
```

Address any issues shown by `flutter doctor`.

### 3. IDE Setup

#### VS Code
```bash
# Install Flutter extension
code --install-extension Dart-Code.flutter
```

#### Android Studio
1. Install Flutter plugin
2. Install Dart plugin
3. Restart Android Studio

### 4. Clone and Setup Project

```bash
git clone <repository-url>
cd noexc
flutter pub get
```

### 5. Verify Project Setup

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Run app
flutter run
```

## Development Tools

### Essential Commands

```bash
# Development
flutter run              # Run app
flutter run --hot-reload # Hot reload (default)
flutter run --release    # Release mode

# Testing
flutter test                                    # All tests
dart tool/tdd_runner.dart --quiet test/       # TDD mode
flutter test --reporter compact               # Compact output

# Analysis
flutter analyze           # Static analysis
flutter format .         # Format code

# Building
flutter build apk        # Android APK
flutter build ios        # iOS build
flutter build web        # Web build
```

### TDD Workflow

The project uses Test-Driven Development:

```bash
# Quick test commands for TDD
dart tool/tdd_runner.dart --quiet test/services/specific_test.dart
dart tool/tdd_runner.dart -q test/models/
flutter test --name "specific test pattern"
```

### Debugging Tools

#### Flutter Inspector
```bash
flutter run --debug
# Then press 'w' to open Flutter Inspector
```

#### Logging
- **NEVER use print()** - Use LoggerService instead
- Import: `final logger = LoggerService();`
- Levels: `debug()`, `info()`, `warning()`, `error()`, `critical()`

### Authoring Tool Setup

```bash
cd noexc-authoring-tool
npm install
npm start
```

Access at http://localhost:3000

## Configuration

### VS Code Settings

Create `.vscode/settings.json`:

```json
{
  \"dart.flutterSdkPath\": \"/path/to/flutter\",
  \"dart.previewFlutterUiGuides\": true,
  \"dart.previewFlutterUiGuidesCustomTracking\": true,
  \"editor.rulers\": [80],
  \"files.exclude\": {
    \"**/.git\": true,
    \"**/.svn\": true,
    \"**/.hg\": true,
    \"**/CVS\": true,
    \"**/.DS_Store\": true,
    \"build/\": true,
    \".dart_tool/\": true
  }
}
```

### Git Hooks (Optional)

```bash
# Install pre-commit hooks
cp .githooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Project Structure

```
noexc/
├── lib/                 # Flutter source code
│   ├── models/         # Data models
│   ├── services/       # Business logic
│   ├── ui/            # User interface
│   └── utils/         # Utilities
├── test/              # Test files (mirrors lib/)
├── assets/            # App assets
│   ├── sequences/     # Conversation JSON files
│   ├── content/       # Semantic content
│   └── animations/    # Rive animation files
├── docs/              # Documentation
├── noexc-authoring-tool/  # React authoring tool
└── shared-config/     # Shared configurations
```

## Environment Variables

No environment variables required for basic development.

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
# Fix Android license issues
flutter doctor --android-licenses

# Update Flutter
flutter upgrade

# Clean and reinstall
flutter clean
flutter pub get
```

#### Build Issues
```bash
# Clean everything
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter pub get
cd ios && pod install && cd ..
```

#### Simulator Issues
```bash
# List available devices
flutter devices

# Launch specific simulator
open -a Simulator

# Reset iOS simulator
Device > Erase All Content and Settings
```

### Performance Issues

#### Hot Reload Not Working
- Save files to trigger hot reload
- Press 'r' in terminal to force reload
- Press 'R' for hot restart

#### Slow Build Times
- Use `flutter run --debug` for development
- Avoid `flutter run --release` during development
- Close unused IDEs and apps

## Next Steps

1. **Read Documentation**: [docs/README.md](../README.md)
2. **Understand Architecture**: [Architecture Overview](../architecture/overview.md)
3. **Run Tests**: [Testing Best Practices](../development/TESTING_BEST_PRACTICES.md)
4. **Try Authoring**: [Authoring Tool Guide](../authoring/AUTHORING_TOOL_README.md)

## Need Help?

- **Flutter Issues**: [Flutter Documentation](https://flutter.dev)
- **Project Issues**: [Troubleshooting Guide](../development/troubleshooting.md)
- **Development Questions**: Check [CLAUDE.md](../../CLAUDE.md)