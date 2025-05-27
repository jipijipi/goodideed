#!/bin/bash

# Environment setup verification script
# This script checks if all environment configurations are properly set up

set -e

echo "🔍 Verifying Tristopher environment setup..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
error_count=0

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((success_count++))
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((error_count++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "📱 Checking Flutter setup..."

# Check Flutter installation
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter is installed: $FLUTTER_VERSION"
else
    print_error "Flutter is not installed or not in PATH"
fi

# Check if Flutter dependencies are installed
if [ -f "pubspec.yaml" ]; then
    if [ -d ".dart_tool" ]; then
        print_success "Flutter dependencies are installed"
    else
        print_warning "Flutter dependencies may not be installed. Run 'flutter pub get'"
    fi
else
    print_error "pubspec.yaml not found. Are you in the right directory?"
fi

echo ""
echo "🔧 Checking project configuration files..."

# Check main entry points
if [ -f "lib/main.dart" ]; then
    print_success "Production entry point exists (lib/main.dart)"
else
    print_error "Production entry point missing (lib/main.dart)"
fi

if [ -f "lib/main_dev.dart" ]; then
    print_success "Development entry point exists (lib/main_dev.dart)"
else
    print_error "Development entry point missing (lib/main_dev.dart)"
fi

if [ -f "lib/main_staging.dart" ]; then
    print_success "Staging entry point exists (lib/main_staging.dart)"
else
    print_error "Staging entry point missing (lib/main_staging.dart)"
fi

# Check environment configuration
if [ -f "lib/config/environment.dart" ]; then
    print_success "Environment configuration exists"
else
    print_error "Environment configuration missing (lib/config/environment.dart)"
fi

echo ""
echo "🔥 Checking Firebase configuration..."

# Check Firebase options files
if [ -f "lib/firebase_options.dart" ]; then
    print_success "Production Firebase config exists"
else
    print_error "Production Firebase config missing (lib/firebase_options.dart)"
fi

if [ -f "lib/firebase_options_dev.dart" ]; then
    print_success "Development Firebase config exists"
else
    print_error "Development Firebase config missing (lib/firebase_options_dev.dart)"
fi

if [ -f "lib/firebase_options_staging.dart" ]; then
    print_success "Staging Firebase config exists"
else
    print_error "Staging Firebase config missing (lib/firebase_options_staging.dart)"
fi

echo ""
echo "⚙️  Checking environment variable files..."

# Check environment files
if [ -f "config/.env.dev" ]; then
    print_success "Development environment file exists"
else
    print_error "Development environment file missing (config/.env.dev)"
fi

if [ -f "config/.env.staging" ]; then
    print_success "Staging environment file exists"
else
    print_error "Staging environment file missing (config/.env.staging)"
fi

if [ -f "config/.env.prod" ]; then
    print_success "Production environment file exists"
else
    print_error "Production environment file missing (config/.env.prod)"
fi

echo ""
echo "📜 Checking build scripts..."

# Check scripts
if [ -f "scripts/run.sh" ]; then
    if [ -x "scripts/run.sh" ]; then
        print_success "Run script exists and is executable"
    else
        print_warning "Run script exists but is not executable. Run 'chmod +x scripts/run.sh'"
    fi
else
    print_error "Run script missing (scripts/run.sh)"
fi

if [ -f "scripts/build.sh" ]; then
    if [ -x "scripts/build.sh" ]; then
        print_success "Build script exists and is executable"
    else
        print_warning "Build script exists but is not executable. Run 'chmod +x scripts/build.sh'"
    fi
else
    print_error "Build script missing (scripts/build.sh)"
fi

# Check Makefile
if [ -f "Makefile" ]; then
    print_success "Makefile exists"
else
    print_error "Makefile missing"
fi

echo ""
echo "🎯 Checking VS Code configuration..."

# Check VS Code config
if [ -f ".vscode/launch.json" ]; then
    print_success "VS Code launch configurations exist"
else
    print_warning "VS Code launch configurations missing (.vscode/launch.json)"
fi

if [ -f ".vscode/settings.json" ]; then
    print_success "VS Code settings exist"
else
    print_warning "VS Code settings missing (.vscode/settings.json)"
fi

echo ""
echo "📱 Checking platform configurations..."

# Check Android configuration
if [ -f "android/app/build.gradle.kts" ]; then
    if grep -q "flavorDimensions" "android/app/build.gradle.kts"; then
        print_success "Android build flavors configured"
    else
        print_warning "Android build flavors may not be configured"
    fi
else
    print_error "Android build configuration missing"
fi

# Check iOS configuration
if [ -f "ios/Runner/Info.plist" ]; then
    print_success "iOS production configuration exists"
else
    print_error "iOS production configuration missing"
fi

if [ -f "ios/Runner/Info-Dev.plist" ]; then
    print_success "iOS development configuration exists"
else
    print_warning "iOS development configuration missing"
fi

if [ -f "ios/Runner/Info-Staging.plist" ]; then
    print_success "iOS staging configuration exists"
else
    print_warning "iOS staging configuration missing"
fi

echo ""
echo "📚 Checking documentation..."

if [ -f "ENVIRONMENT_SETUP.md" ]; then
    print_success "Environment setup documentation exists"
else
    print_error "Environment setup documentation missing (ENVIRONMENT_SETUP.md)"
fi

if [ -f "README.md" ]; then
    print_success "Project README exists"
else
    print_error "Project README missing"
fi

echo ""
echo "🎉 Setup verification complete!"
echo ""

if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}🎯 All critical components are properly configured!${NC}"
    echo -e "${GREEN}   You can now run: make dev${NC}"
else
    echo -e "${RED}⚠️  Found $error_count critical issues that need attention.${NC}"
    echo -e "${YELLOW}   Please fix the errors above before proceeding.${NC}"
fi

if [ $success_count -gt 0 ]; then
    echo -e "${GREEN}   Successfully verified $success_count components.${NC}"
fi

echo ""
echo "🚀 Quick start commands:"
echo "   make setup    # Install dependencies and setup project"
echo "   make dev      # Run development environment"
echo "   make staging  # Run staging environment"
echo "   make prod     # Run production environment"
echo "   make help     # Show all available commands"
echo ""

exit $error_count
