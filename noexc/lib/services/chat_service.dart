import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';

class ChatService {
  Future<List<ChatMessage>> loadChatScript() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/chat_script.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> messagesJson = jsonData['messages'];
      
      return messagesJson
          .map((messageJson) => ChatMessage.fromJson(messageJson))
          .toList();
    } catch (e) {
      throw Exception('Failed to load chat script: $e');
    }
  }
}