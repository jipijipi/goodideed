/// Application-wide constants
class AppConstants {
  // App Information
  static const String appTitle = 'noexc';
  
  // Storage Keys
  static const String userDataKeyPrefix = 'noexc_user_data_';
  static const String themeKey = 'theme.isDark';
  
  // Note: User attribute constants moved to StorageKeys for consistency
  
  // Chat Configuration
  static const int defaultMessageDelay = 1000; // milliseconds
  static const String defaultPlaceholderText = 'Type your answer...';
  
  // Chat Sequences
  static const String sequencesAssetPath = 'assets/sequences/';
  static const String defaultSequenceId = 'welcome_seq';
  static const List<String> availableSequences = [
    'welcome_seq', 
    'onboarding_seq', 
    'taskChecking_seq', 
    'taskSetting_seq', 
    'sendoff_seq', 
    'success_seq', 
    'failure_seq', 
    'task_config_seq', 
    'task_config_test_seq', 
    'day_tracking_test_seq',
    // Group sequences (generated from authoring tool)
    'group_28',
    'group_30', 
    'group_31',
    'group_39',
    'group_47',
    'group_55',
    'group_59',
    'group_62'
  ];
  
  // User Response ID Offset
  static const int userResponseIdOffset = 1000;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}