/// Application-wide constants
class AppConstants {
  // App Information
  static const String appTitle = 'noexc';
  
  // Storage Keys
  static const String userDataKeyPrefix = 'noexc_user_data_';
  static const String themeKey = 'theme.isDark';
  
  // Chat Configuration
  static const int defaultMessageDelay = 1000; // milliseconds
  static const String defaultPlaceholderText = 'Type your answer...';
  static const String chatScriptAssetPath = 'assets/chat_script.json';
  
  // User Response ID Offset
  static const int userResponseIdOffset = 1000;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}