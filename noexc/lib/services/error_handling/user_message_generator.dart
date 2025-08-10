import 'chat_error_types.dart';

/// Generates user-friendly error messages for different error types
class UserMessageGenerator {
  /// Creates a safe fallback message for UI display
  static String createFallbackMessage(
    ChatErrorType errorType, {
    String? context,
  }) {
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

  /// Creates a contextual error message with additional information
  static String createContextualMessage(
    ChatErrorType errorType, {
    String? context,
    String? sequenceId,
    int? messageId,
  }) {
    final baseMessage = createFallbackMessage(errorType, context: context);

    if (sequenceId != null) {
      return '$baseMessage (Sequence: $sequenceId)';
    }

    if (messageId != null) {
      return '$baseMessage (Message: $messageId)';
    }

    return baseMessage;
  }

  /// Creates a recovery suggestion message
  static String createRecoveryMessage(ChatErrorType errorType) {
    switch (errorType) {
      case ChatErrorType.assetNotFound:
        return 'Try refreshing the page or checking your internet connection.';
      case ChatErrorType.invalidFormat:
        return 'Please contact support with the error details.';
      case ChatErrorType.templateError:
        return 'The conversation will continue with default text.';
      case ChatErrorType.conditionError:
        return 'The conversation will take the default path.';
      case ChatErrorType.flowError:
        return 'The conversation will restart from the beginning.';
      case ChatErrorType.processingError:
        return 'Please try your response again.';
      case ChatErrorType.loadError:
        return 'Check your connection and try again.';
      case ChatErrorType.assetValidation:
        return 'Please contact support for assistance.';
    }
  }

  /// Creates a complete error message with both explanation and recovery
  static String createCompleteMessage(
    ChatErrorType errorType, {
    String? context,
    String? sequenceId,
    int? messageId,
  }) {
    final contextualMessage = createContextualMessage(
      errorType,
      context: context,
      sequenceId: sequenceId,
      messageId: messageId,
    );
    final recoveryMessage = createRecoveryMessage(errorType);

    return '$contextualMessage\n\n$recoveryMessage';
  }
}
