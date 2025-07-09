import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../models/choice.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';
import 'condition_evaluator.dart';
import '../models/route_condition.dart';

class ChatService {
  ChatSequence? _currentSequence;
  Map<int, ChatMessage> _messageMap = {};
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;
  final ConditionEvaluator? _conditionEvaluator;
  
  // Callback for notifying UI about sequence changes from autoroutes
  Future<void> Function(String sequenceId, int startMessageId)? _onSequenceSwitch;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService,
       _conditionEvaluator = userDataService != null 
           ? ConditionEvaluator(userDataService) 
           : null;

  /// Set callback for sequence switching notifications
  void setSequenceSwitchCallback(Future<void> Function(String sequenceId, int startMessageId) callback) {
    _onSequenceSwitch = callback;
  }

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
    
    return await _getMessagesFromId(ChatConfig.initialMessageId);
  }

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _currentSequence;

  Future<List<ChatMessage>> getMessagesAfterChoice(int startId) async {
    return await _getMessagesFromId(startId);
  }

  Future<List<ChatMessage>> getMessagesAfterTextInput(int nextMessageId, String userInput) async {
    return await _getMessagesFromId(nextMessageId);
  }

  ChatMessage createUserResponseMessage(int id, String userInput) {
    return ChatMessage(
      id: id,
      text: userInput,
      delay: 0,
      sender: ChatConfig.userSender,
    );
  }

  Future<List<ChatMessage>> _getMessagesFromId(int startId) async {
    List<ChatMessage> messages = [];
    int? currentId = startId;
    
    while (currentId != null && _messageMap.containsKey(currentId)) {
      ChatMessage msg = _messageMap[currentId]!;
      
      // Handle autoroute messages
      if (msg.isAutoRoute) {
        currentId = await _processAutoRoute(msg);
        continue; // Skip adding to display
      }
      
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
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    if (_userDataService != null && choiceMessage.storeKey != null) {
      // Use custom value if provided, fallback to choice text
      final valueToStore = selectedChoice.value ?? selectedChoice.text;
      await _userDataService!.storeValue(choiceMessage.storeKey!, valueToStore);
    }
  }

  /// Process an autoroute message and return the next message ID
  Future<int?> _processAutoRoute(ChatMessage routeMessage) async {
    if (_conditionEvaluator == null || routeMessage.routes == null) {
      return routeMessage.nextMessageId;
    }

    // Evaluate conditions in order
    for (final route in routeMessage.routes!) {
      // Check if this is a default route (no condition)
      if (route.isDefault) {
        return await _executeRoute(route);
      }
      
      // Evaluate condition if present
      if (route.condition != null) {
        final matches = await _conditionEvaluator!.evaluate(route.condition!);
        if (matches) {
          return await _executeRoute(route);
        }
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    return routeMessage.nextMessageId;
  }

  /// Execute a route condition by loading sequence or returning message ID
  Future<int?> _executeRoute(RouteCondition route) async {
    if (route.sequenceId != null) {
      final startMessageId = route.nextMessageId ?? ChatConfig.initialMessageId;
      
      // Notify UI about sequence change if callback is set
      if (_onSequenceSwitch != null) {
        await _onSequenceSwitch!(route.sequenceId!, startMessageId);
        // Return null to indicate that UI will handle the continuation
        return null;
      } else {
        // Fallback: Load sequence directly (for backward compatibility)
        await loadSequence(route.sequenceId!);
        return startMessageId;
      }
    }
    
    // Stay in current sequence, go to specified message
    return route.nextMessageId;
  }
}