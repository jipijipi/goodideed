import 'chat_error_types.dart';

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