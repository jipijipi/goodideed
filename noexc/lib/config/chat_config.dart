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
    'onboarding': 'Welcome & Setup',
    'tutorial': 'App Tutorial',
    'support': 'Get Help',
    'menu': 'Main Menu',
    'autoroute_test': 'Autoroute Test',
    'custom_value_demo': 'Custom Value Demo',
    'comparison_demo': 'Comparison Operators Demo',
    'multi_text_demo': 'Multi-Text Message Demo',
    'test_single_responsibility': 'Single Responsibility Test',
  };
  
  // Private constructor to prevent instantiation
  ChatConfig._();
}