/// Configuration specific to chat functionality
class ChatConfig {
  // Message Types
  static const String botSender = 'bot';
  static const String userSender = 'user';

  // Chat Flow
  static const int initialMessageId = 1;

  // Template Processing
  static const String templateVariablePattern = r'\{([^}]+)\}';
  static const String templateFallbackSeparator = '|';

  // Multi-text Processing
  static const String multiTextSeparator = '|||';

  // Error Messages
  static const String chatScriptLoadError = 'Failed to load chat script';
  static const String messageNotFoundError = 'Message not found';

  // UI Labels
  static const String chatScreenTitle = 'Chat';
  static const String userInfoPanelTitle = 'Debug Panel';
  static const String emptyDataMessage = 'No debug data available';
  static const String toggleThemeTooltip = 'Toggle Theme';
  static const String userInfoTooltip = 'Debug Panel';
  static const String sequenceSelectorTooltip = 'Choose Chat Sequence';

  // Sequence Names
  static const Map<String, String> sequenceDisplayNames = {
    'welcome_seq': 'Welcome Check-in',
    'onboarding_seq': 'User Onboarding',
    'taskChecking_seq': 'Task Progress Check',
    'taskSetting_seq': 'Daily Task Setting',
    'sendoff_seq': 'Session Wrap-up',
    'success_seq': 'Task Completed',
    'failure_seq': 'Task Support',
    'task_config_seq': 'Task Configuration',
    'task_config_test_seq': '🧪 Config Test',
    'image_demo_seq': 'Image Demo Test',
  };

  // Private constructor to prevent instantiation
  ChatConfig._();
}
