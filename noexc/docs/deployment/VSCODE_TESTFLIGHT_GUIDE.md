# VS Code TestFlight Quick Guide

## 🚀 One-Click TestFlight Builds from VS Code

This guide covers the automated VS Code tasks for building and preparing iOS apps for TestFlight distribution.

## 📋 Prerequisites

- ✅ **Xcode installed** with valid Apple Developer account
- ✅ **iOS signing certificates** configured in Xcode
- ✅ **Provisioning profiles** set up for your app
- ✅ **App Store Connect** app record created
- ✅ **Flutter iOS dependencies** working (`flutter doctor`)

## 🎯 Quick Start (30 seconds to TestFlight)

### **Method 1: Command Palette (Recommended)**
1. **Ctrl+Shift+P** (Windows/Linux) or **Cmd+Shift+P** (Mac)
2. Type **"Tasks: Run Task"**
3. Select **"🍎 Build iOS Archive"**
4. Wait for build completion
5. Upload `build/ios/ipa/noexc.ipa` to TestFlight

### **Method 2: Default Build Shortcut**
1. **Ctrl+Shift+P** → **"Tasks: Run Build Task"**
2. Automatically runs iOS archive build
3. Upload generated `.ipa` file

## 📱 Available Tasks

### **🍎 Build iOS Archive** ⭐ *Most Used*
```
flutter build ipa --release
```
- **Purpose:** Quick production build for TestFlight
- **Output:** `build/ios/ipa/noexc.ipa`
- **Use When:** Ready to upload, no version changes needed

### **🔄 Bump Version & Build iOS**
```
Auto-increment build number + flutter build ipa --release
```
- **Purpose:** Version management + build in one step
- **Example:** `1.0.0+6` → `1.0.0+7`
- **Use When:** New TestFlight build with incremented version

### **🧪 Test & Build iOS**
```
flutter test --reporter failures-only && flutter build ipa --release
```
- **Purpose:** Safety build - only builds if tests pass
- **Uses:** Your existing test setup (`tf` alias equivalent)
- **Use When:** Want to ensure code quality before TestFlight

### **🔍 Validate & Build iOS**
```
test_analyzer.dart + flutter analyze + flutter build ipa --verbose
```
- **Purpose:** Full validation with detailed output
- **Uses:** Your existing `tool/test_analyzer.dart`
- **Use When:** Debugging build issues or comprehensive validation

### **🚀 Complete TestFlight Pipeline**
```
clean → pub get → test → build
```
- **Purpose:** Full clean build pipeline
- **Use When:** Major releases or after dependency changes

## 📂 Build Outputs

### **Success Build:**
```
✅ Build completed successfully!
📁 Output: build/ios/ipa/noexc.ipa
📱 Ready for TestFlight upload
```

### **Build Locations:**
- **iOS Archive:** `build/ios/ipa/noexc.ipa`
- **iOS Debug:** `build/ios/Release-iphoneos/Runner.app`
- **Build Logs:** VS Code integrated terminal

## 🔄 Version Management

### **Current Version:** `1.0.0+6` (from `pubspec.yaml`)

### **Manual Version Update:**
```yaml
# pubspec.yaml
version: 1.0.1+7  # Major.Minor.Patch+BuildNumber
```

### **Automatic Version Bump:**
Use **"🔄 Bump Version & Build iOS"** task:
- Reads current build number from `pubspec.yaml`
- Increments automatically (`+6` → `+7`)
- Updates file and builds with new version

## 📤 TestFlight Upload Methods

### **Method 1: Transporter App (Recommended)**
1. Open **Transporter** app (from Mac App Store)
2. Drag `build/ios/ipa/noexc.ipa` into Transporter
3. Click **"Deliver"**
4. Wait for processing in App Store Connect

### **Method 2: Xcode Organizer**
1. Open Xcode → **Window** → **Organizer**
2. Select **Archives** tab
3. Find your build → **Distribute App**
4. Choose **App Store Connect** → **Upload**

### **Method 3: Command Line (Advanced)**
```bash
xcrun altool --upload-app -f build/ios/ipa/noexc.ipa -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD
```

## 🔧 Troubleshooting

### **Common Build Issues:**

#### **"No signing certificate found"**
```bash
# Solution: Open Xcode and configure signing
open ios/Runner.xcworkspace
# Xcode → Runner → Signing & Capabilities → Team
```

#### **"Provisioning profile expired"**
```bash
# Solution: Refresh profiles in Xcode
# Xcode → Preferences → Accounts → Download Manual Profiles
```

#### **"Build failed with exit code 65"**
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter build ipa --release --verbose
```

#### **"Tests failed, build aborted"**
```bash
# Check failing tests:
flutter test --reporter failures-only

# Or use your existing aliases:
source tool/test_aliases.sh
tf  # failures only
```

### **Task-Specific Issues:**

#### **Version bump not working:**
- Check `pubspec.yaml` format: `version: 1.0.0+6`
- Ensure no extra spaces or characters
- Manually verify version after bump

#### **Test task hanging:**
- Use **"🍎 Build iOS Archive"** to skip tests
- Check specific test failures with `tf` alias
- Run `dart tool/test_analyzer.dart --quick`

## ⚙️ Advanced Configuration

### **Custom Keyboard Shortcuts**
Add to VS Code `keybindings.json`:
```json
{
  "key": "ctrl+shift+i",
  "command": "workbench.action.tasks.runTask",
  "args": "🍎 Build iOS Archive"
}
```

### **Task Customization**
Edit `.vscode/tasks.json` to modify:
- Build arguments (`--release`, `--debug`, `--profile`)
- Output verbosity (`--verbose`, `--quiet`)
- Additional validation steps

### **Environment Variables**
```json
{
  "label": "Custom iOS Build",
  "type": "shell",
  "command": "flutter",
  "args": ["build", "ipa", "--release"],
  "options": {
    "env": {
      "FLUTTER_BUILD_MODE": "release"
    }
  }
}
```

## 🎯 Best Practices

### **Development Workflow:**
1. **Code changes** → **🧪 Test & Build iOS** (safety first)
2. **Ready for TestFlight** → **🔄 Bump Version & Build iOS**
3. **Quick iterations** → **🍎 Build iOS Archive**
4. **Major releases** → **🚀 Complete TestFlight Pipeline**

### **Version Strategy:**
- **Build number (`+N`):** Increment for every TestFlight build
- **Patch version (`.N`):** Bug fixes and minor updates
- **Minor version (`.N.0`):** New features
- **Major version (`N.0.0`):** Breaking changes or major releases

### **Testing Strategy:**
- Use **🧪 Test & Build iOS** for regular development
- Use **🍎 Build iOS Archive** when tests are already passing
- Use **🔍 Validate & Build iOS** for debugging build issues

## 📊 Integration with Existing Workflow

### **Existing Tools Integration:**
- **Test aliases:** Tasks use your `tf`, `tc`, `tq` patterns
- **Test analyzer:** **🔍 Validate & Build iOS** uses `tool/test_analyzer.dart`
- **TDD workflow:** **🧪 Test & Build iOS** follows your TDD practices

### **Debug Panel Compatibility:**
- VS Code tasks complement your debug panel controls
- Use debug panel for **development/testing**
- Use VS Code tasks for **production builds**

## 🚨 Important Notes

### **Encryption Declaration:**
✅ **Already configured** in `ios/Runner/Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```
- **No manual encryption questions** during upload
- **Automatic TestFlight processing**
- **Faster upload workflow**

### **Build Artifacts:**
- **Keep `.ipa` files** for version tracking
- **Archive old builds** before major releases
- **`.ipa` files are ~50-100MB** - manage disk space

### **App Store Connect:**
- **Processing time:** 5-15 minutes after upload
- **TestFlight availability:** 15-30 minutes after processing
- **External testing:** Requires App Review (24-48 hours)

## 🔗 Related Documentation

- **[Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)**
- **[App Store Connect Guide](https://developer.apple.com/app-store-connect/)**
- **[TestFlight Beta Testing](https://developer.apple.com/testflight/)**
- **[Xcode Signing Guide](https://developer.apple.com/documentation/xcode/)**

## 📞 Quick Reference

### **Most Common Commands:**
```bash
# VS Code Tasks (Ctrl+Shift+P → Tasks: Run Task)
🍎 Build iOS Archive          # Quick TestFlight build
🔄 Bump Version & Build iOS   # Version + build
🧪 Test & Build iOS          # Safety build

# Manual Commands (if needed)
flutter build ipa --release  # Direct build
flutter clean                # Clean cache
flutter doctor               # Check setup
```

### **File Locations:**
```
📁 Build output:     build/ios/ipa/noexc.ipa
📁 iOS project:      ios/Runner.xcworkspace
📁 Version config:   pubspec.yaml
📁 VS Code tasks:    .vscode/tasks.json
📁 App info:         ios/Runner/Info.plist
```

---

**🎉 You're all set!** Use **"🍎 Build iOS Archive"** for your next TestFlight build.