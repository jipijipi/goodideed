import 'chat_error_types.dart';

/// Exception for sequence-related errors
class ChatSequenceException extends ChatException {
  final String? sequenceId;
  
  const ChatSequenceException(
    super.message, {
    required super.type,
    this.sequenceId,
  });
  
  @override
  String toString() => 'ChatSequenceException: $message (Sequence: $sequenceId)';
}

/// Exception for message-related errors
class ChatMessageException extends ChatException {
  final int? messageId;
  
  const ChatMessageException(
    super.message, {
    required super.type,
    this.messageId,
  });
  
  @override
  String toString() => 'ChatMessageException: $message (Message ID: $messageId)';
}

/// Exception for template-related errors
class ChatTemplateException extends ChatException {
  final String? template;
  
  const ChatTemplateException(
    super.message, {
    required super.type,
    this.template,
  });
  
  @override
  String toString() => 'ChatTemplateException: $message (Template: $template)';
}

/// Exception for condition evaluation errors
class ChatConditionException extends ChatException {
  final String? condition;
  
  const ChatConditionException(
    super.message, {
    required super.type,
    this.condition,
  });
  
  @override
  String toString() => 'ChatConditionException: $message (Condition: $condition)';
}

/// Exception for flow navigation errors
class ChatFlowException extends ChatException {
  final String? description;
  
  const ChatFlowException(
    super.message, {
    required super.type,
    this.description,
  });
  
  @override
  String toString() => 'ChatFlowException: $message (Description: $description)';
}

/// Exception for asset validation errors
class ChatAssetException extends ChatException {
  final String? asset;
  
  const ChatAssetException(
    super.message, {
    required super.type,
    this.asset,
  });
  
  @override
  String toString() => 'ChatAssetException: $message (Asset: $asset)';
}