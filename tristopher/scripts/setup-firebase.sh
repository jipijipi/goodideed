#!/bin/bash

# Firebase Environment Setup Script
# This script helps set up Firebase for all environments

set -e

echo "🔥 Setting up Firebase for all Tristopher environments..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
fi

echo "📱 Configuring Firebase for each environment..."

echo ""
echo "🔧 Configuring Development Environment..."
echo "Project: tristopher-dev"
echo "This will create: lib/firebase_options_dev.dart"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

flutterfire configure \
  --project=tristopher-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.example.tristopherApp.dev \
  --android-app-id=com.example.tristopher_app.dev \
  --android-package-name=com.example.tristopher_app.dev

echo ""
echo "🔧 Configuring Staging Environment..."
echo "Project: tristopher-staging"
echo "This will create: lib/firebase_options_staging.dart"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

flutterfire configure \
  --project=tristopher-staging \
  --out=lib/firebase_options_staging.dart \
  --ios-bundle-id=com.example.tristopherApp.staging \
  --android-app-id=com.example.tristopher_app.staging \
  --android-package-name=com.example.tristopher_app.staging

echo ""
echo "🔧 Updating Production Environment..."
echo "Project: tristopher-72b78"
echo "This will update: lib/firebase_options.dart"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

flutterfire configure \
  --project=tristopher-72b78 \
  --out=lib/firebase_options.dart \
  --ios-bundle-id=com.example.tristopherApp \
  --android-app-id=com.example.tristopher_app \
  --android-package-name=com.example.tristopher_app

echo ""
echo "✅ Firebase configuration complete!"
echo ""
echo "📁 Created files:"
echo "   - lib/firebase_options_dev.dart (Development)"
echo "   - lib/firebase_options_staging.dart (Staging)"
echo "   - lib/firebase_options.dart (Production)"
echo ""
echo "🔥 Next steps:"
echo "   1. Enable Authentication in each Firebase project"
echo "   2. Create Firestore databases in each project"
echo "   3. Set up Firebase Functions (optional)"
echo "   4. Configure security rules"
echo ""
echo "🚀 Test your setup:"
echo "   make dev      # Test development environment"
echo "   make staging  # Test staging environment"  
echo "   make prod     # Test production environment"
