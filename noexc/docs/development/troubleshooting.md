# Troubleshooting Guide

## Common Development Issues

### Flutter Build Issues

#### Clean Build Errors
```bash
# Full clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### iOS-Specific Issues
```bash
# Clean iOS build files
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run
```

#### Android-Specific Issues
```bash
# Clean Android build
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

### Testing Issues

#### Tests Not Running
```bash
# Verify Flutter installation
flutter doctor

# Check test dependencies
flutter pub get

# Run specific test
flutter test test/services/chat_service_test.dart
```

#### TDD Runner Issues
```bash
# Check tool permissions
chmod +x tool/tdd_runner.dart

# Run with explicit dart command
dart tool/tdd_runner.dart --quiet test/
```

#### Mock Generation Issues
```bash
# Regenerate mocks
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Service Integration Issues

#### LoggerService Issues
**Problem**: Print statements instead of LoggerService
```dart
// DON'T DO THIS
print('Debug message');

// DO THIS INSTEAD
final logger = LoggerService();
logger.debug('Debug message');
```

#### UserDataService Issues
**Problem**: Data not persisting
```dart
// Check async/await usage
await userDataService.setValue('key', 'value');
final value = await userDataService.getValue('key');
```

#### NotificationService Issues
**Problem**: Notifications not appearing
- Test on real device (not simulator)
- Check notification permissions
- Verify notification scheduling logic

### UI Issues

#### Widget Not Updating
```dart
// Ensure StatefulWidget calls setState
setState(() {
  // Update state here
});

// Or use service notifications for reactive updates
```

#### Animation Issues
**Problem**: Rive animations not loading
- Verify asset paths in pubspec.yaml
- Check Rive file compatibility (version ^0.14.0-dev.5)
- Test animation files in Rive editor first

### Performance Issues

#### Slow Hot Reload
```bash
# Use debug mode during development
flutter run --debug

# Avoid release mode during development
# flutter run --release  # Don't use this for dev
```

#### Memory Issues
- Close unused IDEs and applications
- Use VS Code instead of Android Studio for lighter resource usage
- Increase system memory if possible

### Asset Loading Issues

#### Sequence Files Not Loading
```dart
// Verify JSON syntax
// Check file paths match AppConstants.availableSequences
// Ensure proper JSON structure in assets/sequences/
```

#### Content Resolution Issues
```dart
// Check semantic content file structure
// Verify fallback content exists
// Test with SemanticContentService directly
```

### Template System Issues

#### Template Not Resolving
```dart
// Check template syntax: {key|fallback}
// Verify data exists in UserDataService
// Test formatter syntax: {key:formatter|fallback}
```

#### Formatter Issues
```dart
// Check available formatters:
// timeOfDay, activeDays, intensity, timePeriod
// Verify formatter parameters match expected format
```

### Cross-Platform Issues

#### iOS Simulator Issues
```bash
# Reset iOS simulator
Device > Erase All Content and Settings

# Or launch specific simulator
xcrun simctl list devices
xcrun simctl boot "iPhone 14"
```

#### Android Emulator Issues
```bash
# List available AVDs
emulator -list-avds

# Launch specific emulator
emulator -avd Pixel_4_API_30
```

### Debugging Strategies

#### Enable Debug Logging
```dart
// Use LoggerService with appropriate levels
final logger = LoggerService();
logger.debug('Detailed debug info');
logger.info('General information');
logger.warning('Warning conditions');
logger.error('Error conditions');
```

#### Use Debug Panel
- Access in-app debug panel
- Test different user scenarios
- Modify variables in real-time
- Switch between sequences manually

#### VS Code Debugging
1. Set breakpoints in code
2. Press F5 to start debugging
3. Use Debug Console for variable inspection
4. Step through code execution

### Environment Issues

#### Flutter Version Issues
```bash
# Check Flutter version
flutter --version

# Update Flutter
flutter upgrade

# Switch Flutter channel if needed
flutter channel stable
flutter upgrade
```

#### IDE Setup Issues
**VS Code:**
```bash
# Install Flutter extension
code --install-extension Dart-Code.flutter

# Check extension settings
Command Palette > Flutter: Change SDK
```

**Android Studio:**
- Install Flutter and Dart plugins
- Configure Flutter SDK path
- Restart IDE after installation

### Data Issues

#### SharedPreferences Issues
```dart
// Clear all data for testing
await userDataService.clearAllData();

// Check specific keys
final keys = await userDataService.getAllKeys();
print('Available keys: $keys');
```

#### Session Issues
```dart
// Force session reset
await sessionService.resetSession();

// Check session variables
final visitCount = await userDataService.getValue('session.visitCount');
```

### Notification System Issues

#### Permission Issues
```dart
// Check current permission status
final status = await notificationService.getPermissionStatus();
print('Permission status: $status');

// Request permissions if needed
if (status == NotificationPermissionStatus.notRequested) {
  await notificationService.requestPermissions();
}
```

#### Cross-Session Issues
```dart
// Check for pending notification events
final pendingEvent = await appStateService.consumePendingNotification();
if (pendingEvent != null) {
  // Handle pending notification tap
}
```

### Build Configuration Issues

#### Xcode Issues
- Update to latest Xcode version
- Clean build folder: Product > Clean Build Folder
- Reset simulator: Device > Erase All Content and Settings

#### Android Issues
- Update Android Studio and SDK
- Check gradle wrapper version
- Verify target SDK versions in build.gradle

### Getting Help

#### Internal Resources
1. Check [CLAUDE.md](../../CLAUDE.md) for development guidelines
2. Review [Testing Guide](../getting-started/testing-guide.md)
3. Use debug panel for real-time debugging
4. Check service-specific documentation

#### External Resources
1. [Flutter Documentation](https://flutter.dev/docs)
2. [Dart Language Guide](https://dart.dev/guides)
3. [Rive Flutter Package](https://pub.dev/packages/rive)

#### Debug Commands Quick Reference
```bash
# Analysis and formatting
flutter analyze
flutter format .

# Testing
flutter test
dart tool/tdd_runner.dart --quiet test/

# Device management
flutter devices
flutter run -d <device_id>

# Clean builds
flutter clean
flutter pub get

# Debugging
flutter run --verbose
flutter logs
```

## Emergency Procedures

### Project Won't Build
1. `flutter clean`
2. `flutter pub get`
3. Restart IDE
4. Try `flutter run --verbose` for detailed errors

### Tests Failing After Changes
1. Run `flutter analyze` first
2. Check for formatting issues: `flutter format .`
3. Regenerate mocks if using mockito
4. Run individual test files to isolate issues

### Animation System Broken
1. Verify Rive package version: `^0.14.0-dev.5`
2. Check asset paths in pubspec.yaml
3. Test animations in Rive editor
4. Review animation zone configuration

### Data Loss During Development
1. Check UserDataService implementation
2. Verify async/await usage
3. Use debug panel to inspect current data
4. Reset to known good state using scenarios

Remember: When in doubt, check the logs using LoggerService - never use print() statements!