# Build Guide

## Platform-Specific Build Instructions

### iOS Build

#### Prerequisites
- macOS with Xcode installed
- Valid Apple Developer Account (for device testing)
- iOS deployment target: iOS 12.0+

#### Debug Build
```bash
# Debug build for simulator
flutter build ios --debug --simulator

# Debug build for device
flutter build ios --debug
```

#### Release Build
```bash
# Release build for device
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release
```

#### Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Signing & Capabilities
3. Configure Team and Bundle Identifier
4. Ensure capabilities match app requirements:
   - Background Modes (for notifications)
   - Push Notifications
   - App Groups (if needed)

### Android Build

#### Prerequisites
- Android Studio with SDK
- Java Development Kit (JDK 11+)
- Android SDK API level 21+ (Android 5.0+)

#### Debug Build
```bash
# Debug APK
flutter build apk --debug

# Debug bundle
flutter build appbundle --debug
```

#### Release Build
```bash
# Release APK
flutter build apk --release

# Release bundle (recommended for Play Store)
flutter build appbundle --release
```

#### Signing Configuration
Create `android/key.properties`:
```properties
storePassword=<store_password>
keyPassword=<key_password>
keyAlias=<key_alias>
storeFile=<path_to_keystore>
```

Update `android/app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### macOS Build

#### Prerequisites
- macOS 10.14+
- Xcode command line tools

#### Build Commands
```bash
# Debug build
flutter build macos --debug

# Release build
flutter build macos --release
```

### Web Build

#### Prerequisites
- Modern web browser
- Web server for deployment

#### Build Commands
```bash
# Debug build
flutter build web --debug

# Release build
flutter build web --release

# Build with custom base href
flutter build web --base-href /myapp/
```

## Build Optimization

### Performance Optimization

#### Flutter Build Flags
```bash
# Optimize for size
flutter build apk --release --split-per-abi

# Obfuscate code
flutter build apk --release --obfuscate --split-debug-info=/path/to/symbols

# Tree shake icons
flutter build apk --release --tree-shake-icons
```

#### Asset Optimization
- Optimize images before including in assets
- Use vector graphics where possible
- Compress Rive animation files
- Remove unused assets

### Build Configuration

#### Environment Variables
Set environment-specific configurations:

```dart
// lib/config.dart
class Config {
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: false);
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
}
```

Build with environment:
```bash
flutter build apk --release --dart-define=ENVIRONMENT=production
```

## Platform-Specific Configurations

### iOS Specific

#### Info.plist Configuration
Add required permissions in `ios/Runner/Info.plist`:
```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app sends reminders to help you maintain your habits.</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

#### Background Modes
Enable background processing for notifications:
```xml
<key>UIBackgroundModes</key>
<array>
    <key>background-processing</key>
    <key>background-fetch</key>
</array>
```

### Android Specific

#### AndroidManifest.xml Configuration
Add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

#### ProGuard Rules
Add to `android/app/proguard-rules.pro`:
```
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
```

## Build Troubleshooting

### Common iOS Issues

#### Code Signing Errors
```bash
# Clean and rebuild
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter build ios
```

#### Simulator vs Device Builds
```bash
# Ensure correct build for target
flutter build ios --debug --simulator  # For simulator
flutter build ios --debug              # For device
```

### Common Android Issues

#### Gradle Build Failures
```bash
# Clean gradle
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

#### SDK Version Conflicts
Check `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Universal Solutions

#### Dependency Conflicts
```bash
# Update dependencies
flutter pub get
flutter pub deps

# Clear pub cache if needed
flutter pub cache repair
```

#### Build Cache Issues
```bash
# Nuclear option - clean everything
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build [platform]
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'
      - run: flutter pub get
      - run: flutter build apk --release

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

## Distribution

### iOS Distribution

#### TestFlight (Internal Testing)
See [iOS TestFlight Guide](VSCODE_TESTFLIGHT_GUIDE.md) for detailed instructions.

#### App Store Release
1. Build release IPA: `flutter build ipa --release`
2. Upload via Xcode Organizer or Transporter app
3. Configure App Store Connect listing
4. Submit for review

### Android Distribution

#### Google Play Store
1. Build release bundle: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Configure store listing
4. Release to testing track first

#### Direct APK Distribution
1. Build release APK: `flutter build apk --release`
2. Sign APK with release key
3. Distribute through preferred channel

### Web Distribution

#### Static Hosting
1. Build web version: `flutter build web --release`
2. Upload `build/web/` contents to web server
3. Configure server for Flutter web requirements

## Build Verification

### Pre-Release Checklist

#### Functionality Testing
- [ ] All core features working
- [ ] Notifications functioning on real devices
- [ ] Rive animations loading correctly
- [ ] User data persistence working
- [ ] Cross-platform consistency

#### Performance Testing
- [ ] App launch time acceptable
- [ ] Memory usage reasonable
- [ ] Battery drain testing
- [ ] Animation performance smooth

#### Platform Testing
- [ ] Test on minimum supported OS versions
- [ ] Test on various screen sizes
- [ ] Test permission flows
- [ ] Test background behavior

### Build Quality Checks
```bash
# Code analysis
flutter analyze

# Format check
flutter format --dry-run .

# Test coverage
flutter test --coverage

# Build size analysis
flutter build apk --analyze-size
```

## Deployment Automation

### Build Scripts
Create `scripts/build.sh`:
```bash
#!/bin/bash
set -e

echo "Starting build process..."

# Clean and prepare
flutter clean
flutter pub get

# Run tests
flutter test

# Build for platforms
flutter build apk --release
flutter build ios --release --no-codesign

echo "Build complete!"
```

### Version Management
Update version in `pubspec.yaml`:
```yaml
version: 1.2.3+4
#        │ │ │ │
#        │ │ │ └── Build number
#        │ │ └──── Patch version
#        │ └────── Minor version
#        └──────── Major version
```

## See Also

- **[iOS TestFlight Guide](VSCODE_TESTFLIGHT_GUIDE.md)** - iOS testing workflow
- **[Development Setup](../getting-started/development-setup.md)** - Environment configuration
- **[Troubleshooting](../development/troubleshooting.md)** - Build issue resolution