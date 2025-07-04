import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';

class ChatService {
  List<ChatMessage> _allMessages = [];
  Map<int, ChatMessage> _messageMap = {};

  Future<List<ChatMessage>> loadChatScript() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/chat_script.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> messagesJson = jsonData['messages'];
      
      _allMessages = messagesJson
          .map((messageJson) => ChatMessage.fromJson(messageJson))
          .toList();
      
      // Build message map for quick lookup
      _messageMap = {for (var msg in _allMessages) msg.id: msg};
      
      return _allMessages;
    } catch (e) {
      throw Exception('Failed to load chat script: $e');
    }
  }

  bool hasMessage(int id) {
    return _messageMap.containsKey(id);
  }

  ChatMessage? getMessageById(int id) {
    return _messageMap[id];
  }

  Future<List<ChatMessage>> getInitialMessages() async {
    if (_allMessages.isEmpty) {
      await loadChatScript();
    }
    
    return _getMessagesFromId(1);
  }

  List<ChatMessage> getMessagesAfterChoice(int startId) {
    return _getMessagesFromId(startId);
  }

  List<ChatMessage> _getMessagesFromId(int startId) {
    List<ChatMessage> messages = [];
    int? currentId = startId;
    
    while (currentId != null && _messageMap.containsKey(currentId)) {
      ChatMessage msg = _messageMap[currentId]!;
      messages.add(msg);
      
      // Stop at choice messages - let UI handle the choice interaction
      if (msg.isChoice) break;
      
      // Move to next message
      if (msg.nextMessageId != null) {
        currentId = msg.nextMessageId;
      } else {
        // If no explicit next message, try sequential ID
        currentId = currentId + 1;
        if (!_messageMap.containsKey(currentId)) {
          break;
        }
      }
    }
    
    return messages;
  }
}