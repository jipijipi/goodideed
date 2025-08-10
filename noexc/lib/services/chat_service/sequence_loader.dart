import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../config/chat_config.dart';

/// Handles loading and managing chat sequences from assets
class SequenceLoader {
  ChatSequence? _currentSequence;
  Map<int, ChatMessage> _messageMap = {};

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _currentSequence;

  /// Get message map for quick lookup
  Map<int, ChatMessage> get messageMap => _messageMap;

  /// Load a specific chat sequence by ID
  Future<ChatSequence> loadSequence(String sequenceId) async {
    try {
      final String assetPath = 'assets/sequences/$sequenceId.json';
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _currentSequence = ChatSequence.fromJson(jsonData);

      // Build message map for quick lookup
      _messageMap = {for (var msg in _currentSequence!.messages) msg.id: msg};

      return _currentSequence!;
    } catch (e) {
      throw Exception(
        '${ChatConfig.chatScriptLoadError} for sequence $sequenceId: $e',
      );
    }
  }

  /// Load the default chat script (for backward compatibility)
  Future<List<ChatMessage>> loadChatScript() async {
    // Default to onboarding_seq sequence for backward compatibility
    final sequence = await loadSequence('onboarding_seq');
    return sequence.messages;
  }

  /// Check if a message exists by ID
  bool hasMessage(int id) {
    return _messageMap.containsKey(id);
  }

  /// Get a message by ID
  ChatMessage? getMessageById(int id) {
    return _messageMap[id];
  }

  /// Get initial messages for a specific sequence
  Future<List<ChatMessage>> getInitialMessages({
    String sequenceId = 'onboarding_seq',
  }) async {
    if (_currentSequence == null ||
        _currentSequence!.sequenceId != sequenceId) {
      await loadSequence(sequenceId);
    }

    return _currentSequence!.messages;
  }

  /// Create a user response message
  ChatMessage createUserResponseMessage(int id, String userInput) {
    return ChatMessage(
      id: id,
      text: userInput,
      delay: 0,
      sender: ChatConfig.userSender,
    );
  }
}
