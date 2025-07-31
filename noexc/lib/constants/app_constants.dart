/// Application-wide constants
class AppConstants {
  // App Information
  static const String appTitle = 'Excuse You';
  
  // Storage Keys
  static const String userDataKeyPrefix = 'noexc_user_data_';
  static const String themeKey = 'theme.isDark';
  
  // Note: User attribute constants moved to StorageKeys for consistency
  
  // Chat Configuration
  static const int defaultMessageDelay = 100; // milliseconds
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
    'richtext_demo_seq',
    'image_demo_seq',
    // Missing sequences that exist in assets
    'intro_seq',
    'inactive_seq', 
    'active_seq',
    'settask_seq',
    'excuse_seq',
    'completed_seq',
    'deadline_seq',
    'failed_seq',
    'notice_seq',
    'overdue_seq',
    'pending_seq',
    'previous_seq',
    'reminders_seq',
    'weekdays_seq',
    'task_start_timing_seq',
  ];
  
  // User Response ID Offset
  static const int userResponseIdOffset = 1000;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}