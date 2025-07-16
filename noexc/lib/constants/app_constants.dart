/// Application-wide constants
class AppConstants {
  // App Information
  static const String appTitle = 'noexc';
  
  // Storage Keys
  static const String userDataKeyPrefix = 'noexc_user_data_';
  static const String themeKey = 'theme.isDark';
  
  // Habit Tracking User Attributes
  static const String isOnboardedKey = 'user.isOnboarded';
  static const String currentTaskKey = 'user.currentTask';
  static const String taskDeadlineKey = 'user.taskDeadline';
  static const String currentStreakKey = 'user.currentStreak';
  static const String isOnNoticeKey = 'user.isOnNotice';
  static const String lastVisitKey = 'user.lastVisit';
  
  // Chat Configuration
  static const int defaultMessageDelay = 1000; // milliseconds
  static const String defaultPlaceholderText = 'Type your answer...';
  static const String chatScriptAssetPath = 'assets/chat_script.json'; // Legacy support
  
  // Chat Sequences
  static const String sequencesAssetPath = 'assets/sequences/';
  static const String defaultSequenceId = 'onboarding';
  static const List<String> availableSequences = ['onboarding', 'tutorial', 'support', 'menu', 'comprehensive_test', 'autoroute_debug','dataaction_demo','achievement_demo','welcome_seq'];
  
  // User Response ID Offset
  static const int userResponseIdOffset = 1000;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}