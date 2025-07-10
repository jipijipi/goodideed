import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../models/choice.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';
import 'text_variants_service.dart';
import 'condition_evaluator.dart';
import '../models/route_condition.dart';

class ChatService {
  ChatSequence? _currentSequence;
  Map<int, ChatMessage> _messageMap = {};
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;
  final TextVariantsService? _variantsService;
  final ConditionEvaluator? _conditionEvaluator;
  
  // Callback for notifying UI about sequence changes from autoroutes
  Future<void> Function(String sequenceId, int startMessageId)? _onSequenceSwitch;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService,
       _variantsService = variantsService,
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
      
      // Process template and variants on the original message first
      final processedMsg = await processMessageTemplate(msg);
      
      // Expand multi-text messages into individual messages
      final expandedMessages = processedMsg.expandToIndividualMessages();
      messages.addAll(expandedMessages);
      
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
  /// Also applies text variants for regular messages (not choices, inputs, conditionals, or multi-texts)
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    String textToProcess = message.text;
    
    // Apply variants only for regular messages (not choices, inputs, conditionals, or multi-texts)
    if (_variantsService != null && 
        _currentSequence != null &&
        !message.isChoice && 
        !message.isTextInput && 
        !message.isAutoRoute && 
        !message.hasMultipleTexts) {
      
      // Get variant for the main text
      textToProcess = await _variantsService!.getVariant(
        message.text, 
        _currentSequence!.sequenceId, 
        message.id
      );
    }
    
    // Apply template processing if service is available
    if (_templatingService != null) {
      textToProcess = await _templatingService!.processTemplate(textToProcess);
    }
    
    return ChatMessage(
      id: message.id,
      text: textToProcess,
      delay: message.delay,
      sender: message.sender,
      isChoice: message.isChoice,
      isTextInput: message.isTextInput,
      choices: message.choices,
      nextMessageId: message.nextMessageId,
      storeKey: message.storeKey,
      placeholderText: message.placeholderText,
      isAutoRoute: message.isAutoRoute,
      routes: message.routes,
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
    print('🚏 AUTOROUTE: Processing autoroute message ID: ${routeMessage.id}');
    if (_conditionEvaluator == null || routeMessage.routes == null) {
      print('❌ AUTOROUTE: No condition evaluator or routes found, using nextMessageId: ${routeMessage.nextMessageId}');
      return routeMessage.nextMessageId;
    }

    print('🚏 AUTOROUTE: Found ${routeMessage.routes!.length} routes to evaluate');
    
    // Evaluate conditions in order
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      print('🚏 AUTOROUTE: Evaluating route ${i + 1}/${routeMessage.routes!.length}');
      // Check if this is a default route (no condition)
      if (route.isDefault) {
        print('🚏 AUTOROUTE: Route ${i + 1} is default route, executing');
        return await _executeRoute(route);
      }
      
      // Evaluate condition if present
      if (route.condition != null) {
        print('🚏 AUTOROUTE: Route ${i + 1} has condition: "${route.condition}"');
        final matches = await _conditionEvaluator!.evaluate(route.condition!);
        print('🚏 AUTOROUTE: Route ${i + 1} condition result: $matches');
        if (matches) {
          print('🚏 AUTOROUTE: Route ${i + 1} matches! Executing route');
          return await _executeRoute(route);
        }
        print('🚏 AUTOROUTE: Route ${i + 1} does not match, trying next route');
      } else {
        print('🚏 AUTOROUTE: Route ${i + 1} has no condition and is not default, skipping');
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    print('🚏 AUTOROUTE: No routes matched, using fallback nextMessageId: ${routeMessage.nextMessageId}');
    return routeMessage.nextMessageId;
  }

  /// Execute a route condition by loading sequence or returning message ID
  Future<int?> _executeRoute(RouteCondition route) async {
    print('🎯 EXECUTE_ROUTE: Executing route - sequenceId: ${route.sequenceId}, nextMessageId: ${route.nextMessageId}');
    if (route.sequenceId != null) {
      final startMessageId = ChatConfig.initialMessageId;
      print('🎯 EXECUTE_ROUTE: Switching to sequence "${route.sequenceId}" starting at message $startMessageId');
      
      // Notify UI about sequence change if callback is set
      if (_onSequenceSwitch != null) {
        print('🎯 EXECUTE_ROUTE: Notifying UI about sequence switch');
        await _onSequenceSwitch!(route.sequenceId!, startMessageId);
        // Return null to indicate that UI will handle the continuation
        print('🎯 EXECUTE_ROUTE: UI will handle continuation, returning null');
        return null;
      } else {
        // Fallback: Load sequence directly (for backward compatibility)
        print('🎯 EXECUTE_ROUTE: No UI callback, loading sequence directly');
        await loadSequence(route.sequenceId!);
        return startMessageId;
      }
    }
    
    // Stay in current sequence, go to specified message
    print('🎯 EXECUTE_ROUTE: No sequence switch, returning nextMessageId: ${route.nextMessageId}');
    return route.nextMessageId;
  }
}