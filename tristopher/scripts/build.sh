#!/bin/bash

# Build script for different environments
# Usage: ./build.sh [dev|staging|prod] [android|ios|both]

set -e

ENVIRONMENT=${1:-prod}
PLATFORM=${2:-both}

echo "🚀 Building Tristopher for $ENVIRONMENT environment on $PLATFORM platform(s)"

# Set the main file based on environment
case $ENVIRONMENT in
  "dev")
    MAIN_FILE="lib/main_dev.dart"
    APP_NAME="Tristopher Dev"
    ;;
  "staging")
    MAIN_FILE="lib/main_staging.dart"
    APP_NAME="Tristopher Staging"
    ;;
  "prod")
    MAIN_FILE="lib/main.dart"
    APP_NAME="Tristopher"
    ;;
  *)
    echo "❌ Invalid environment. Use dev, staging, or prod"
    exit 1
    ;;
esac

echo "📱 Using main file: $MAIN_FILE"
echo "🏷️  App name: $APP_NAME"

# Function to build Android
build_android() {
  echo "🤖 Building Android APK..."
  flutter build apk \
    --target=$MAIN_FILE \
    --build-name=1.0.0 \
    --build-number=1 \
    --flavor=$ENVIRONMENT
  
  echo "🤖 Building Android App Bundle..."
  flutter build appbundle \
    --target=$MAIN_FILE \
    --build-name=1.0.0 \
    --build-number=1 \
    --flavor=$ENVIRONMENT
}

# Function to build iOS
build_ios() {
  echo "🍎 Building iOS..."
  flutter build ios \
    --target=$MAIN_FILE \
    --build-name=1.0.0 \
    --build-number=1 \
    --flavor=$ENVIRONMENT
}

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build based on platform
case $PLATFORM in
  "android")
    build_android
    ;;
  "ios")
    build_ios
    ;;
  "both")
    build_android
    build_ios
    ;;
  *)
    echo "❌ Invalid platform. Use android, ios, or both"
    exit 1
    ;;
esac

echo "✅ Build completed successfully!"
echo "🎉 $APP_NAME is ready for $ENVIRONMENT environment"
