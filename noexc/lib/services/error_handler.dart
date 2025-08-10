import 'error_handling/chat_error_types.dart';
import 'error_handling/error_classifier.dart';
import 'error_handling/user_message_generator.dart';

/// Main error handler that orchestrates all error handling functionality
class ChatErrorHandler {
  /// Handles sequence loading errors
  static Exception handleSequenceLoadError(String sequenceId, dynamic error) {
    return ErrorClassifier.handleSequenceLoadError(sequenceId, error);
  }

  /// Handles message processing errors
  static Exception handleMessageProcessingError(int messageId, dynamic error) {
    return ErrorClassifier.handleMessageProcessingError(messageId, error);
  }

  /// Handles template processing errors
  static Exception handleTemplateError(String template, dynamic error) {
    return ErrorClassifier.handleTemplateError(template, error);
  }

  /// Handles condition evaluation errors
  static Exception handleConditionError(String condition, dynamic error) {
    return ErrorClassifier.handleConditionError(condition, error);
  }

  /// Handles flow navigation errors
  static Exception handleFlowError(String description, dynamic error) {
    return ErrorClassifier.handleFlowError(description, error);
  }

  /// Handles asset validation errors
  static Exception handleAssetValidationError(String asset, dynamic error) {
    return ErrorClassifier.handleAssetValidationError(asset, error);
  }

  /// Creates a safe fallback message for UI display
  static String createFallbackMessage(
    ChatErrorType errorType, {
    String? context,
  }) {
    return UserMessageGenerator.createFallbackMessage(
      errorType,
      context: context,
    );
  }

  /// Creates a contextual error message with additional information
  static String createContextualMessage(
    ChatErrorType errorType, {
    String? context,
    String? sequenceId,
    int? messageId,
  }) {
    return UserMessageGenerator.createContextualMessage(
      errorType,
      context: context,
      sequenceId: sequenceId,
      messageId: messageId,
    );
  }

  /// Creates a recovery suggestion message
  static String createRecoveryMessage(ChatErrorType errorType) {
    return UserMessageGenerator.createRecoveryMessage(errorType);
  }

  /// Creates a complete error message with both explanation and recovery
  static String createCompleteMessage(
    ChatErrorType errorType, {
    String? context,
    String? sequenceId,
    int? messageId,
  }) {
    return UserMessageGenerator.createCompleteMessage(
      errorType,
      context: context,
      sequenceId: sequenceId,
      messageId: messageId,
    );
  }
}
