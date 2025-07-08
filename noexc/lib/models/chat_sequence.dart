import 'chat_message.dart';

/// Represents a complete chat sequence with metadata and messages
class ChatSequence {
  final String sequenceId;
  final String name;
  final String description;
  final List<ChatMessage> messages;

  ChatSequence({
    required this.sequenceId,
    required this.name,
    required this.description,
    required this.messages,
  });

  factory ChatSequence.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messagesJson = json['messages'] ?? [];
    final messages = messagesJson
        .map((messageJson) => ChatMessage.fromJson(messageJson))
        .toList();

    return ChatSequence(
      sequenceId: json['sequenceId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sequenceId': sequenceId,
      'name': name,
      'description': description,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  /// Get a message by ID from this sequence
  ChatMessage? getMessageById(int id) {
    try {
      return messages.firstWhere((message) => message.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if this sequence contains a message with the given ID
  bool hasMessage(int id) {
    return messages.any((message) => message.id == id);
  }

  /// Get all message IDs in this sequence
  List<int> get messageIds => messages.map((message) => message.id).toList();
}