import 'package:flutter/foundation.dart';

/// Handles runtime errors in chat services
class ChatErrorHandler {
  static const String _tag = 'ChatErrorHandler';
  
  /// Handles sequence loading errors
  static Exception handleSequenceLoadError(String sequenceId, dynamic error) {
    final message = 'Failed to load sequence "$sequenceId": ${error.toString()}';
    _logError(message, error);
    
    if (error is FormatException) {
      return ChatSequenceException(
        'Invalid JSON format in sequence "$sequenceId"',
        type: ChatErrorType.invalidFormat,
        sequenceId: sequenceId,
      );
    }
    
    if (error.toString().contains('Unable to load asset')) {
      return ChatSequenceException(
        'Sequence file not found: "$sequenceId"',
        type: ChatErrorType.assetNotFound,
        sequenceId: sequenceId,
      );
    }
    
    return ChatSequenceException(
      message,
      type: ChatErrorType.loadError,
      sequenceId: sequenceId,
    );
  }
  
  /// Handles message processing errors
  static Exception handleMessageProcessingError(int messageId, dynamic error) {
    final message = 'Failed to process message $messageId: ${error.toString()}';
    _logError(message, error);
    
    return ChatMessageException(
      message,
      type: ChatErrorType.processingError,
      messageId: messageId,
    );
  }
  
  /// Handles template processing errors
  static Exception handleTemplateError(String template, dynamic error) {
    final message = 'Template processing failed for "$template": ${error.toString()}';
    _logError(message, error);
    
    return ChatTemplateException(
      message,
      type: ChatErrorType.templateError,
      template: template,
    );
  }
  
  /// Handles condition evaluation errors
  static Exception handleConditionError(String condition, dynamic error) {
    final message = 'Condition evaluation failed for "$condition": ${error.toString()}';
    _logError(message, error);
    
    return ChatConditionException(
      message,
      type: ChatErrorType.conditionError,
      condition: condition,
    );
  }
  
  /// Handles flow navigation errors
  static Exception handleFlowError(String description, dynamic error) {
    final message = 'Flow navigation error: $description - ${error.toString()}';
    _logError(message, error);
    
    return ChatFlowException(
      message,
      type: ChatErrorType.flowError,
      description: description,
    );
  }
  
  /// Handles asset validation errors
  static Exception handleAssetValidationError(String asset, dynamic error) {
    final message = 'Asset validation failed for "$asset": ${error.toString()}';
    _logError(message, error);
    
    return ChatAssetException(
      message,
      type: ChatErrorType.assetValidation,
      asset: asset,
    );
  }
  
  /// Logs error with debug info
  static void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('[$_tag] ERROR: $message');
      if (error is Exception) {
        print('[$_tag] Exception type: ${error.runtimeType}');
      }
      if (error is Error) {
        print('[$_tag] Stack trace: ${error.stackTrace}');
      }
    }
  }
  
  /// Creates a safe fallback message for UI display
  static String createFallbackMessage(ChatErrorType errorType, {String? context}) {
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
      default:
        return 'I encountered an unexpected issue. Please try again.';
    }
  }
}

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
  String get userMessage => ChatErrorHandler.createFallbackMessage(type);
}

/// Exception for sequence-related errors
class ChatSequenceException extends ChatException {
  final String? sequenceId;
  
  const ChatSequenceException(
    String message, {
    required ChatErrorType type,
    this.sequenceId,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatSequenceException: $message (Sequence: $sequenceId)';
}

/// Exception for message-related errors
class ChatMessageException extends ChatException {
  final int? messageId;
  
  const ChatMessageException(
    String message, {
    required ChatErrorType type,
    this.messageId,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatMessageException: $message (Message ID: $messageId)';
}

/// Exception for template-related errors
class ChatTemplateException extends ChatException {
  final String? template;
  
  const ChatTemplateException(
    String message, {
    required ChatErrorType type,
    this.template,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatTemplateException: $message (Template: $template)';
}

/// Exception for condition evaluation errors
class ChatConditionException extends ChatException {
  final String? condition;
  
  const ChatConditionException(
    String message, {
    required ChatErrorType type,
    this.condition,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatConditionException: $message (Condition: $condition)';
}

/// Exception for flow navigation errors
class ChatFlowException extends ChatException {
  final String? description;
  
  const ChatFlowException(
    String message, {
    required ChatErrorType type,
    this.description,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatFlowException: $message (Description: $description)';
}

/// Exception for asset validation errors
class ChatAssetException extends ChatException {
  final String? asset;
  
  const ChatAssetException(
    String message, {
    required ChatErrorType type,
    this.asset,
  }) : super(message, type: type);
  
  @override
  String toString() => 'ChatAssetException: $message (Asset: $asset)';
}