# Makefile for Tristopher Flutter Project
# Provides convenient commands for different environments

.PHONY: help dev staging prod build-dev build-staging build-prod clean setup

help: ## Show this help message
	@echo "Tristopher Flutter Project Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies and setup project
	@echo "🔧 Setting up Tristopher project..."
	@chmod +x scripts/run.sh scripts/build.sh scripts/verify-setup.sh
	@flutter pub get
	@echo "✅ Setup complete!"
	@echo "🔍 Running setup verification..."
	@./scripts/verify-setup.sh

clean: ## Clean build files and get dependencies
	@echo "🧹 Cleaning project..."
	@flutter clean
	@flutter pub get
	@echo "✅ Clean complete!"

dev: ## Run app in development environment
	@echo "🚀 Running Tristopher in development mode..."
	@chmod +x scripts/run.sh 2>/dev/null || true
	@./scripts/run.sh dev

staging: ## Run app in staging environment
	@echo "🚀 Running Tristopher in staging mode..."
	@chmod +x scripts/run.sh 2>/dev/null || true
	@./scripts/run.sh staging

prod: ## Run app in production environment
	@echo "🚀 Running Tristopher in production mode..."
	@chmod +x scripts/run.sh 2>/dev/null || true
	@./scripts/run.sh prod

build-dev: ## Build app for development
	@echo "🔨 Building Tristopher for development..."
	@./scripts/build.sh dev both

build-staging: ## Build app for staging
	@echo "🔨 Building Tristopher for staging..."
	@./scripts/build.sh staging both

build-prod: ## Build app for production
	@echo "🔨 Building Tristopher for production..."
	@./scripts/build.sh prod both

build-android-dev: ## Build Android APK for development
	@./scripts/build.sh dev android

build-android-staging: ## Build Android APK for staging
	@./scripts/build.sh staging android

build-android-prod: ## Build Android APK for production
	@./scripts/build.sh prod android

build-ios-dev: ## Build iOS app for development
	@./scripts/build.sh dev ios

build-ios-staging: ## Build iOS app for staging
	@./scripts/build.sh staging ios

build-ios-prod: ## Build iOS app for production
	@./scripts/build.sh prod ios

test: ## Run tests
	@echo "🧪 Running tests..."
	@flutter test

analyze: ## Analyze code
	@echo "🔍 Analyzing code..."
	@flutter analyze

format: ## Format code
	@echo "✨ Formatting code..."
	@dart format .

upgrade: ## Upgrade dependencies
	@echo "⬆️ Upgrading dependencies..."
	@flutter pub upgrade

devices: ## List available devices
	@echo "📱 Available devices:"
	@flutter devices

doctor: ## Run flutter doctor
	@flutter doctor

setup-firebase: ## Set up Firebase for all environments
	@echo "🔥 Setting up Firebase for all environments..."
	@chmod +x scripts/setup-firebase.sh
	@./scripts/setup-firebase.sh

verify: ## Verify environment setup
	@chmod +x scripts/verify-setup.sh 2>/dev/null || true
	@./scripts/verify-setup.sh
