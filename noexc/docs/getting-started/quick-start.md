# Quick Start Guide

**← [Documentation Index](../README.md) | [Getting Started](.)**

Get the noexc app running in under 5 minutes.

## Prerequisites

- Flutter SDK (latest stable)
- Node.js 16+ (for authoring tool)
- iOS Simulator / Android Emulator or physical device

## 1. Clone and Setup

```bash
git clone <repository-url>
cd noexc
flutter pub get
```

## 2. Run the App

```bash
flutter run
```

Choose your target device when prompted.

## 3. Explore the Debug Panel

1. Tap the debug icon in the app
2. Try different test scenarios
3. Modify user variables
4. Switch between conversation sequences

## 4. Run Tests (Optional)

```bash
# Full test suite
flutter test

# Quick TDD mode
dart tool/tdd_runner.dart --quiet test/
```

## 5. Try the Authoring Tool (Optional)

```bash
cd noexc-authoring-tool
npm install
npm start
```

Open http://localhost:3000 to access the visual conversation designer.

## What's Next?

- **Developers**: Read [CLAUDE.md](../../CLAUDE.md) for development guidelines
- **Content Authors**: Check [Content Authoring Guide](../authoring/CONTENT_AUTHORING_GUIDE.md)
- **Designers**: Explore [Rive Animation Zones](../reference/rive-animation-zones.md)

## Common Issues

### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### iOS Simulator Issues
- Ensure Xcode is installed and up to date
- Open iOS Simulator manually if it doesn't launch

### Android Emulator Issues
- Verify Android Studio AVD is created and running
- Check Android SDK installation

## Need Help?

- **Documentation**: [docs/README.md](../README.md)
- **Architecture**: [Architecture Overview](../architecture/overview.md)
- **Troubleshooting**: [Development Issues](../development/troubleshooting.md)