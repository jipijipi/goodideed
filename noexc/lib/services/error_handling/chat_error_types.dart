/// Types of chat-related errors
enum ChatErrorType {
  assetNotFound,
  invalidFormat,
  templateError,
  conditionError,
  flowError,
  processingError,
  loadError,
  assetValidation,
}

/// Base class for chat-related exceptions
abstract class ChatException implements Exception {
  final String message;
  final ChatErrorType type;
  
  const ChatException(this.message, {required this.type});
  
  @override
  String toString() => 'ChatException: $message';
  
  /// Gets user-friendly error message
  String get userMessage => _createFallbackMessage(type);
  
  /// Creates a safe fallback message for UI display
  static String _createFallbackMessage(ChatErrorType errorType) {
    switch (errorType) {
      case ChatErrorType.assetNotFound:
        return 'Sorry, I couldn\'t find the conversation content. Please try again.';
      case ChatErrorType.invalidFormat:
        return 'There seems to be an issue with the conversation format. Please contact support.';
      case ChatErrorType.templateError:
        return 'I\'m having trouble personalizing this message. Continuing with default text.';
      case ChatErrorType.conditionError:
        return 'I couldn\'t evaluate the conversation path. Taking the default route.';
      case ChatErrorType.flowError:
        return 'I lost track of our conversation flow. Let me restart from the beginning.';
      case ChatErrorType.processingError:
        return 'I encountered an issue processing your response. Please try again.';
      case ChatErrorType.loadError:
        return 'I\'m having trouble loading the conversation. Please check your connection.';
      case ChatErrorType.assetValidation:
        return 'There\'s an issue with the conversation content. Please contact support.';
    }
  }
}