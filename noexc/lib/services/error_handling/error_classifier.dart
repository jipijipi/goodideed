import 'package:flutter/foundation.dart';
import 'chat_error_types.dart';
import 'chat_exceptions.dart';
import '../logger_service.dart';

/// Classifies and handles different types of errors
class ErrorClassifier {
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
    logger.error(message, component: LogComponent.errorHandler);
    
    if (kDebugMode) {
      if (error is Exception) {
        logger.debug('Exception type: ${error.runtimeType}', component: LogComponent.errorHandler);
      }
      if (error is Error) {
        logger.debug('Stack trace: ${error.stackTrace}', component: LogComponent.errorHandler);
      }
    }
  }
}