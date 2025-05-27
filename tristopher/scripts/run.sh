#!/bin/bash

# Run script for different environments
# Usage: ./run.sh [dev|staging|prod] [device_id]

set -e

ENVIRONMENT=${1:-dev}
DEVICE_ID=$2

echo "🚀 Running Tristopher in $ENVIRONMENT environment"

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

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run the app
if [ -n "$DEVICE_ID" ]; then
  echo "📱 Running on device: $DEVICE_ID"
  flutter run --target=$MAIN_FILE --device-id=$DEVICE_ID
else
  echo "📱 Running on default device..."
  flutter run --target=$MAIN_FILE
fi

echo "✅ App launched successfully!"
echo "🎉 $APP_NAME is now running"
