# TestFlight Testing Guide for Excuse You

Complete guide for testing the "Excuse You" chat app using Apple's TestFlight platform.

## Prerequisites

### Apple Developer Account
- **Required**: Active Apple Developer Program membership ($99/year)
- **Access**: App Store Connect account with app management permissions
- **Team**: Ensure you're added to the correct development team

### Development Environment
- **Xcode**: Latest stable version (15.0+)
- **Flutter**: Ensure iOS toolchain is properly configured
- **Device**: iPhone or iPad running iOS 12.0+ for testing

## App Configuration

### Current App Details
- **App Name**: Excuse You
- **Bundle ID**: Check in `ios/Runner.xcodeproj` project settings
- **Version**: 1.0.0+1 (from pubspec.yaml)
- **Display Name**: "Excuse You" (from Info.plist)

## Build Process

### 1. Prepare Flutter Build
```bash
# Navigate to project root
cd /path/to/noexc

# Clean previous builds
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release
```

### 2. Archive in Xcode
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select "Any iOS Device" as target
2. Product → Archive
3. Wait for archive to complete
4. Xcode Organizer will open automatically

### 3. Upload to App Store Connect
**In Xcode Organizer:**
1. Select your archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Follow upload wizard
5. Wait for processing (5-30 minutes)

## App Store Connect Setup

### 1. Create App Record
1. Login to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to "My Apps" → "+" → "New App"
3. Fill in details:
   - **Platform**: iOS
   - **Name**: Excuse You
   - **Primary Language**: English
   - **Bundle ID**: Select from dropdown
   - **SKU**: Unique identifier (e.g., noexc-ios-2024)

### 2. Configure TestFlight
1. Navigate to your app → "TestFlight" tab
2. Wait for build processing to complete
3. Click on your build number when ready
4. Fill in required metadata:
   - **What to Test**: Describe new features/changes
   - **Test Information**: App description for testers
   - **App Review Information**: Contact details

## Testing Groups

### Internal Testing
- **Automatic**: Up to 100 users from your team
- **No Review**: Builds available immediately
- **Access**: Team members with App Store Connect access

### External Testing
- **Manual Approval**: Requires App Review (1-3 days)
- **Capacity**: Up to 10,000 external testers
- **Public Link**: Can create shareable TestFlight links

### Creating Test Groups
1. TestFlight → "Internal Testing" or "External Testing"
2. Click "+" next to Groups
3. Name your group (e.g., "Beta Testers", "QA Team")
4. Add build to group
5. Invite testers via email

## Inviting Testers

### Individual Invites
1. TestFlight → Select Group → "Testers" tab
2. Click "+" → "Add New Tester"
3. Enter email addresses
4. Send invitations

### Public Link (External Only)
1. External Testing → Select Group
2. Enable "Public Link"
3. Share generated link
4. Testers can join without email invitation

## Testing the Chat App

### Key Testing Scenarios

#### 1. First-Time User Flow
- **Test**: Fresh app installation
- **Verify**: Welcome sequence loads properly
- **Check**: Onboarding → Task Setting → Sendoff flow

#### 2. Returning User Flow
- **Test**: App reopening (simulate with debug panel)
- **Verify**: Task Checking sequence activates
- **Check**: Success/Failure/Task Setting routing

#### 3. Session Management
- **Test**: Daily visit tracking
- **Verify**: `session.visitCount` increments correctly
- **Check**: Time-based conditions work properly

#### 4. Task Time Management
- **Test**: Various time scenarios using debug panel
- **Verify**: Start time, deadline, and time range logic
- **Check**: `task.isBeforeStart`, `task.isInTimeRange`, `task.isPastDeadline`

### Using Debug Features
1. **User Panel**: Tap status bar to open debug overlay
2. **Test Scenarios**: Load predefined scenarios from dropdown
3. **Variable Editing**: Modify user data in real-time
4. **Date/Time Testing**: Change task dates and deadlines
5. **Sequence Testing**: Switch between conversation sequences

### Testing Checklist
- [ ] App launches without crashes
- [ ] All conversation sequences load properly
- [ ] Template substitution works (`{key|fallback}` syntax)
- [ ] Multi-text messages display correctly (`|||` separator)
- [ ] Choice interactions save data properly
- [ ] Data actions modify user storage
- [ ] Session tracking persists between app launches
- [ ] Time-based routing functions correctly
- [ ] Debug panel operates without issues

## Build Management

### Version Updates
1. Update `version` in `pubspec.yaml` (e.g., 1.0.1+2)
2. Rebuild and archive
3. Upload new build to TestFlight
4. Add to existing test groups or create new ones

### Build Notes
- **What to Test**: Always provide clear testing instructions
- **Known Issues**: Document any known bugs or limitations
- **New Features**: Highlight new functionality to focus testing on

## Common Issues

### Build Failures
- **Code Signing**: Verify certificates and provisioning profiles
- **Dependencies**: Run `flutter pub get` and `pod install`
- **Clean Build**: Use `flutter clean` before rebuilding

### TestFlight Upload Issues
- **Processing Stuck**: Wait 30+ minutes, contact Apple if persistent
- **Rejected Build**: Check email for specific rejection reasons
- **Missing Compliance**: Add export compliance information

### Tester Issues
- **Can't Install**: Verify device compatibility and iOS version
- **No Invitation**: Check spam folder, resend invitation
- **TestFlight Not Working**: Update TestFlight app from App Store

## Best Practices

### Development Cycle
1. **Feature Development**: Use local testing and simulators
2. **Internal Testing**: Quick validation with team members
3. **External Testing**: Broader user feedback before release
4. **Production Release**: Final testing in TestFlight environment

### Communication
- **Test Instructions**: Provide clear, specific testing scenarios
- **Feedback Collection**: Use TestFlight's built-in feedback or external tools
- **Update Notifications**: Keep testers informed of new builds and changes

### App Store Preparation
- **Screenshots**: Capture from TestFlight builds
- **App Description**: Use tester feedback to refine store listing
- **Metadata**: Prepare App Store information during TestFlight phase

## Automation Options

### Fastlane Integration
```ruby
# Example fastlane configuration for automated uploads
lane :beta do
  build_app(scheme: "Runner", workspace: "ios/Runner.xcworkspace")
  upload_to_testflight
end
```

### GitHub Actions
Consider setting up automated TestFlight uploads on code commits or releases.

---

## Quick Reference

### Essential Commands
```bash
# Build for TestFlight
flutter build ios --release

# Open Xcode workspace
open ios/Runner.xcworkspace
```

### Important URLs
- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://developer.apple.com/testflight/)
- [Apple Developer Portal](https://developer.apple.com/account/)

### Support
- **TestFlight Issues**: Apple Developer Support
- **App-Specific Issues**: Use debug panel and app logs
- **Flutter Issues**: Check Flutter documentation and GitHub issues