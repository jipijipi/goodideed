# Tristopher Flutter Project - Environment Setup

This document explains how to work with the different environments (dev, staging, production) in the Tristopher Flutter project.

## Environment Overview

The Tristopher project is configured with three environments:

- **Development (`dev`)** - For local development and testing
- **Staging (`staging`)** - For pre-production testing and QA
- **Production (`prod`)** - For live app releases

Each environment has its own:
- Firebase project configuration
- API endpoints
- App naming and bundle IDs
- Feature flags and payment settings
- Logging and analytics configuration

## Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase CLI
- Android Studio / Xcode for respective platforms

### Setup
```bash
# Make scripts executable and install dependencies
make setup

# Or manually:
chmod +x scripts/run.sh scripts/build.sh
flutter pub get
```

### Running the App

#### Using Make Commands (Recommended)
```bash
# Development environment
make dev

# Staging environment
make staging

# Production environment
make prod
```

#### Using Scripts Directly
```bash
# Run in development
./scripts/run.sh dev

# Run in staging
./scripts/run.sh staging

# Run in production
./scripts/run.sh prod

# Run on specific device
./scripts/run.sh dev [device_id]
```

#### Using Flutter Command Directly
```bash
# Development
flutter run --target=lib/main_dev.dart

# Staging
flutter run --target=lib/main_staging.dart

# Production
flutter run --target=lib/main.dart
```

## Building the App

### Using Make Commands
```bash
# Build all environments
make build-dev
make build-staging
make build-prod

# Build specific platforms
make build-android-dev
make build-ios-staging
```

### Using Scripts
```bash
# Build for all platforms
./scripts/build.sh dev both
./scripts/build.sh staging android
./scripts/build.sh prod ios
```

## VS Code Integration

The project includes VS Code launch configurations for easy debugging:

1. Open the project in VS Code
2. Go to Run and Debug (Ctrl+Shift+D)
3. Select from available configurations:
   - **Tristopher Dev** - Debug development build
   - **Tristopher Staging** - Debug staging build
   - **Tristopher Production** - Debug production build
   - **Tristopher Dev (Profile Mode)** - Profile development build
   - **Tristopher Staging (Profile Mode)** - Profile staging build

## Environment Configuration

### Environment Variables

Each environment has its own configuration file in `config/`:
- `config/.env.dev` - Development settings
- `config/.env.staging` - Staging settings
- `config/.env.prod` - Production settings

Key configuration options:

```env
# App Configuration
APP_NAME=Tristopher Dev
APP_ENV=dev
DEBUG_MODE=true
ENABLE_LOGGING=true

# API Configuration
API_BASE_URL=https://api-dev.tristopher.app
API_TIMEOUT=30000

# Payment Configuration (Important for Tristopher's anti-charity system)
ENABLE_REAL_PAYMENTS=false
MINIMUM_STAKE_AMOUNT=0.01

# Feature Flags
ENABLE_CHAT_FEATURES=true
ENABLE_ANTI_CHARITY_SYSTEM=true
ENABLE_PUSH_NOTIFICATIONS=false

# Tristopher Robot Configuration
ROBOT_PERSONALITY_LEVEL=3
ENABLE_BRUTAL_MODE=true
```

### Firebase Configuration

Each environment connects to a different Firebase project:
- **Dev**: `tristopher-dev`
- **Staging**: `tristopher-staging`
- **Production**: `tristopher-72b78`

Firebase configuration files:
- `lib/firebase_options_dev.dart`
- `lib/firebase_options_staging.dart`
- `lib/firebase_options.dart` (production)

### Android Configuration

The Android build system supports flavors for each environment:

```kotlin
productFlavors {
    create("dev") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "Tristopher Dev")
    }
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        resValue("string", "app_name", "Tristopher Staging")
    }
    create("prod") {
        dimension = "environment"
        resValue("string", "app_name", "Tristopher")
    }
}
```

This allows installing multiple versions of the app simultaneously.

### iOS Configuration

iOS uses separate Info.plist files for each environment:
- `ios/Runner/Info.plist` (production)
- `ios/Runner/Info-Dev.plist` (development)
- `ios/Runner/Info-Staging.plist` (staging)

## Environment-Specific Features

### Development Environment
- Extensive logging enabled
- Debug mode active
- Test payments only ($0.01 minimum stake)
- No analytics or crash reporting
- All features enabled for testing
- Tristopher robot personality level 3

### Staging Environment
- Moderate logging enabled
- Debug mode active
- Test payments only ($0.10 minimum stake)
- Analytics and crash reporting enabled
- All features enabled
- Visual "STAGING" banner in top-right corner
- Tristopher robot personality level 4

### Production Environment
- Minimal logging
- Debug mode disabled
- Real payments enabled ($1.00 minimum stake)
- Full analytics and crash reporting
- All features enabled
- Maximum Tristopher robot personality level 5

## Tristopher-Specific Configuration

### Anti-Charity System
The core feature of Tristopher - the anti-charity wagering system - has different behaviors per environment:

- **Dev**: Payments disabled, very low stakes for testing
- **Staging**: Test payments with realistic stakes for QA
- **Production**: Real payments with actual charity donations

### Robot Personality Levels
Tristopher's pessimistic robot companion has configurable personality levels:
- Level 1: Mild pessimism
- Level 2: Moderate negativity
- Level 3: Strong pessimism (dev default)
- Level 4: Very pessimistic (staging default)
- Level 5: Maximum brutality (production default)

### Feature Flags
Key Tristopher features can be toggled per environment:
- `ENABLE_CHAT_FEATURES`: Chat with Tristopher robot
- `ENABLE_ANTI_CHARITY_SYSTEM`: Core wagering functionality
- `ENABLE_PUSH_NOTIFICATIONS`: Habit reminders and taunts
- `ENABLE_BIOMETRIC_AUTH`: Secure payment authorization
- `ENABLE_BRUTAL_MODE`: Extra harsh robot responses

## Development Workflow

### Typical Development Flow
1. Start with dev environment for feature development
2. Test on staging for integration testing
3. Deploy to production for releases

### Testing Anti-Charity Features
```bash
# Test with minimal stakes in dev
make dev

# Test with realistic stakes in staging
make staging

# Only use production for final testing with real payments
make prod
```

### Firebase Setup
To set up Firebase for new environments:

1. Create new Firebase projects for dev/staging
2. Run `flutterfire configure` for each environment
3. Update the respective `firebase_options_*.dart` files
4. Update environment configuration files

## Troubleshooting

### Common Issues

**Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
make build-dev
```

**Firebase Connection Issues**
- Verify Firebase project IDs match environment configs
- Check Google Services files are properly placed
- Ensure Firebase CLI is authenticated

**Environment Variables Not Loading**
- Verify `.env.*` files exist in `config/` directory
- Check file permissions
- Restart development server

### Useful Commands

```bash
# Check available devices
make devices

# Run Flutter doctor
make doctor

# Analyze code
make analyze

# Format code
make format

# Run tests
make test

# Upgrade dependencies
make upgrade
```

## Project Structure

```
tristopher/
├── lib/
│   ├── config/
│   │   └── environment.dart          # Environment configuration class
│   ├── main.dart                     # Production entry point
│   ├── main_dev.dart                 # Development entry point
│   ├── main_staging.dart             # Staging entry point
│   ├── firebase_options.dart         # Production Firebase config
│   ├── firebase_options_dev.dart     # Development Firebase config
│   └── firebase_options_staging.dart # Staging Firebase config
├── config/
│   ├── .env.dev                      # Development environment variables
│   ├── .env.staging                  # Staging environment variables
│   └── .env.prod                     # Production environment variables
├── scripts/
│   ├── build.sh                      # Build script
│   └── run.sh                        # Run script
├── .vscode/
│   ├── launch.json                   # VS Code debug configurations
│   └── settings.json                 # VS Code settings
├── android/app/build.gradle.kts      # Android build configuration
├── ios/Runner/
│   ├── Info.plist                    # Production iOS config
│   ├── Info-Dev.plist               # Development iOS config
│   └── Info-Staging.plist           # Staging iOS config
└── Makefile                          # Convenient make commands
```

## Security Considerations

- Never commit real API keys or production secrets
- Use different Firebase projects for each environment
- Test payment flows only in dev/staging environments
- Keep production keys in secure environment variables
- Use proper code signing for production builds

## Next Steps

1. Set up CI/CD pipeline for automated builds
2. Configure app store distribution for different environments
3. Set up monitoring and alerts for production
4. Create automated testing for anti-charity payment flows
5. Implement proper code signing and security measures

---

**Remember**: Tristopher's core value proposition is turning procrastination into real consequences through the anti-charity system. Test this functionality thoroughly in dev and staging before any production releases!
