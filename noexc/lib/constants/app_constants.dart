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
  static const int dynamicDelayPerWordMs = 250; // Per-word delay
  static const int dynamicDelayMinMs = 100; // Clamp lower bound
  static const int dynamicDelayMaxMs = 3000; // Clamp upper bound

  // Choice options delay (production mode)
  static const int choiceDisplayDelayMs = 1300;

  // Lifecycle / Resume handling
  static const int resumeDebounceMs = 400; // Debounce for AppLifecycleState.resumed

  // Chat Sequences
  static const String sequencesAssetPath = 'assets/sequences/';
  static const String defaultSequenceId = 'welcome_seq';
  static const List<String> availableSequences = [
    'welcome_seq',
    'onboarding_seq',
    'sendoff_seq',
    'success_seq',
    'failure_seq',
    'intro_seq',
    'inactive_seq',
    'settask_seq',
    'excuse_seq',
    'deadline_seq',
    'overdue_seq',
    'pending_seq',
    'reminders_seq',
    'weekdays_seq',
    'taskCheck_seq',
    'taskparam_seq',
    'autoFailed_seq',
    'catchup_seq',
    'due_seq',
    'return_seq',
    'startday_seq',
    'updateChoice_seq',
    'updatetask_seq',
    'customDays_seq',
    'startTime_seq',
    'deadlineTime_seq',
    'taskConfirm_seq',
  ];

  // User Response ID Offset
  static const int userResponseIdOffset = 1000;

  // Private constructor to prevent instantiation
  AppConstants._();
}
