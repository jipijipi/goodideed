import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';

class ChatService {
  ChatSequence? _currentSequence;
  Map<int, ChatMessage> _messageMap = {};
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService;

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
      throw Exception('${ChatConfig.chatScriptLoadError} for sequence $sequenceId: $e');
    }
  }

  /// Load the default chat script (for backward compatibility)
  Future<List<ChatMessage>> loadChatScript() async {
    // Default to onboarding sequence for backward compatibility
    final sequence = await loadSequence('onboarding');
    return sequence.messages;
  }

  bool hasMessage(int id) {
    return _messageMap.containsKey(id);
  }

  ChatMessage? getMessageById(int id) {
    return _messageMap[id];
  }

  /// Get initial messages for a specific sequence
  Future<List<ChatMessage>> getInitialMessages({String sequenceId = 'onboarding'}) async {
    if (_currentSequence == null || _currentSequence!.sequenceId != sequenceId) {
      await loadSequence(sequenceId);
    }
    
    return _getMessagesFromId(ChatConfig.initialMessageId);
  }

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _currentSequence;

  List<ChatMessage> getMessagesAfterChoice(int startId) {
    return _getMessagesFromId(startId);
  }

  List<ChatMessage> getMessagesAfterTextInput(int nextMessageId, String userInput) {
    return _getMessagesFromId(nextMessageId);
  }

  ChatMessage createUserResponseMessage(int id, String userInput) {
    return ChatMessage(
      id: id,
      text: userInput,
      delay: 0,
      sender: ChatConfig.userSender,
    );
  }

  List<ChatMessage> _getMessagesFromId(int startId) {
    List<ChatMessage> messages = [];
    int? currentId = startId;
    
    while (currentId != null && _messageMap.containsKey(currentId)) {
      ChatMessage msg = _messageMap[currentId]!;
      messages.add(msg);
      
      // Stop at choice messages or text input messages - let UI handle the interaction
      if (msg.isChoice || msg.isTextInput) break;
      
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

  /// Process a single message template and replace variables with stored values
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    if (_templatingService == null) {
      return message;
    }

    final processedText = await _templatingService!.processTemplate(message.text);
    
    return ChatMessage(
      id: message.id,
      text: processedText,
      delay: message.delay,
      sender: message.sender,
      isChoice: message.isChoice,
      isTextInput: message.isTextInput,
      choices: message.choices,
      nextMessageId: message.nextMessageId,
      storeKey: message.storeKey,
      placeholderText: message.placeholderText,
    );
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(List<ChatMessage> messages) async {
    final List<ChatMessage> processedMessages = [];
    
    for (final message in messages) {
      final processedMessage = await processMessageTemplate(message);
      processedMessages.add(processedMessage);
    }
    
    return processedMessages;
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(ChatMessage textInputMessage, String userInput) async {
    if (_userDataService != null && textInputMessage.storeKey != null) {
      await _userDataService!.storeValue(textInputMessage.storeKey!, userInput);
    }
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(ChatMessage choiceMessage, String choiceText) async {
    if (_userDataService != null && choiceMessage.storeKey != null) {
      await _userDataService!.storeValue(choiceMessage.storeKey!, choiceText);
    }
  }
}