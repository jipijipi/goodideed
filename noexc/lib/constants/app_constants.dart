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
  static const String chatScriptAssetPath = 'assets/chat_script.json'; // Legacy support
  
  // Chat Sequences
  static const String sequencesAssetPath = 'assets/sequences/';
  static const String defaultSequenceId = 'onboarding';
  static const List<String> availableSequences = ['onboarding', 'tutorial', 'support'];
  
  // User Response ID Offset
  static const int userResponseIdOffset = 1000;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}