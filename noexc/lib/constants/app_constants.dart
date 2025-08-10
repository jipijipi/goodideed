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

  // Adaptive delay configuration (bot text messages)
  static const int dynamicDelayBaseMs = 200; // Base delay
  static const int dynamicDelayPerWordMs = 100; // Per-word delay
  static const int dynamicDelayMinMs = 100; // Clamp lower bound
  static const int dynamicDelayMaxMs = 3000; // Clamp upper bound

  // Choice options delay (production mode)
  static const int choiceDisplayDelayMs = 1300;

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
    // Fix for validation test failures
    'taskCheck_seq',
    'taskparam_seq',
    'autoFailed_seq',
    'catchup_seq',
    'due_seq',
    'return_seq',
    'startday_seq',
    'updateChoice_seq',
    'updatetask_seq',
  ];

  // User Response ID Offset
  static const int userResponseIdOffset = 1000;

  // Private constructor to prevent instantiation
  AppConstants._();
}
