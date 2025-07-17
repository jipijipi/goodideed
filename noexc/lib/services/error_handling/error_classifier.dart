import 'package:flutter/foundation.dart';
import 'chat_error_types.dart';
import 'chat_exceptions.dart';

/// Classifies and handles different types of errors
class ErrorClassifier {
  static const String _tag = 'ErrorClassifier';
  
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
}