enum Environment {
  dev,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.production;
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }
  
  static bool get isDev => _currentEnvironment == Environment.dev;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  // API URLs
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return 'https://api-dev.tristopher.app';
      case Environment.staging:
        return 'https://api-staging.tristopher.app';
      case Environment.production:
        return 'https://api.tristopher.app';
    }
  }
  
  // Firebase project IDs
  static String get firebaseProjectId {
    switch (_currentEnvironment) {
      case Environment.dev:
        return 'tristopher-dev';
      case Environment.staging:
        return 'tristopher-staging';
      case Environment.production:
        return 'tristopher-72b78';
    }
  }
  
  // App name suffixes
  static String get appName {
    switch (_currentEnvironment) {
      case Environment.dev:
        return 'Tristopher Dev';
      case Environment.staging:
        return 'Tristopher Staging';
      case Environment.production:
        return 'Tristopher';
    }
  }
  
  // Bundle ID suffixes
  static String get bundleIdSuffix {
    switch (_currentEnvironment) {
      case Environment.dev:
        return '.dev';
      case Environment.staging:
        return '.staging';
      case Environment.production:
        return '';
    }
  }
  
  // Debug settings
  static bool get enableLogging {
    switch (_currentEnvironment) {
      case Environment.dev:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
  
  // Payment settings (for anti-charity system)
  static bool get enableRealPayments {
    switch (_currentEnvironment) {
      case Environment.dev:
        return false;
      case Environment.staging:
        return false; // Use test payments in staging
      case Environment.production:
        return true;
    }
  }
  
  // Minimum stake amounts
  static double get minimumStakeAmount {
    switch (_currentEnvironment) {
      case Environment.dev:
        return 0.01; // Very low for testing
      case Environment.staging:
        return 0.10; // Low for staging tests
      case Environment.production:
        return 1.0; // Production minimum
    }
  }
  
  // Analytics
  static bool get enableAnalytics {
    switch (_currentEnvironment) {
      case Environment.dev:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  // Crash reporting
  static bool get enableCrashReporting {
    switch (_currentEnvironment) {
      case Environment.dev:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
}
