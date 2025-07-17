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
import 'data_action_processor.dart';
import '../models/route_condition.dart';

class ChatService {
  ChatSequence? _currentSequence;
  Map<int, ChatMessage> _messageMap = {};
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;
  final TextVariantsService? _variantsService;
  final ConditionEvaluator? _conditionEvaluator;
  final DataActionProcessor? _dataActionProcessor;
  
  // Callback for notifying UI about sequence changes from autoroutes
  Future<void> Function(String sequenceId, int startMessageId)? _onSequenceSwitch;
  
  // Callback for notifying UI about events from dataAction triggers
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService,
       _variantsService = variantsService,
       _conditionEvaluator = userDataService != null 
           ? ConditionEvaluator(userDataService) 
           : null,
       _dataActionProcessor = userDataService != null 
           ? DataActionProcessor(userDataService) 
           : null {
    // Set up event callback for dataActionProcessor
    if (_dataActionProcessor != null) {
      _dataActionProcessor!.setEventCallback(_handleEvent);
    }
  }

  /// Set callback for sequence switching notifications
  void setSequenceSwitchCallback(Future<void> Function(String sequenceId, int startMessageId) callback) {
    _onSequenceSwitch = callback;
  }

  /// Set callback for event notifications from dataAction triggers
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  /// Handle events from dataActionProcessor
  Future<void> _handleEvent(String eventType, Map<String, dynamic> data) async {
    if (_onEvent != null) {
      try {
        await _onEvent!(eventType, data);
      } catch (e) {
        // Silent error handling
      }
    }
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
      
      // Handle dataAction messages
      if (msg.isDataAction) {
        currentId = await _processDataAction(msg);
        continue; // Skip adding to display
      }
      
      // Process template and variants on the original message first
      final processedMsg = await processMessageTemplate(msg);
      
      // Expand multi-text messages into individual messages
      final expandedMessages = processedMsg.expandToIndividualMessages();
      messages.addAll(expandedMessages);
      
      // Stop at choice messages or text input messages - let UI handle the interaction
      if (msg.isChoice || msg.isTextInput) break;
      
      // Check for universal cross-sequence navigation
      if (msg.sequenceId != null) {
        final startMessageId = ChatConfig.initialMessageId;
        
        // Always load sequence directly and continue processing
        await loadSequence(msg.sequenceId!);
        currentId = startMessageId;
        
        continue;
      }
      
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
      type: message.type,
      choices: message.choices,
      nextMessageId: message.nextMessageId,
      storeKey: message.storeKey,
      placeholderText: message.placeholderText,
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
    
    // FIXED: First evaluate all conditional routes, then fall back to default
    // First pass: Evaluate all conditional routes
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      print('🚏 AUTOROUTE: Evaluating conditional route ${i + 1}/${routeMessage.routes!.length}');
      
      // Skip default routes in first pass
      if (route.isDefault) {
        print('🚏 AUTOROUTE: Route ${i + 1} is default route, skipping in first pass');
        continue;
      }
      
      // Evaluate condition if present
      if (route.condition != null) {
        print('🚏 AUTOROUTE: Route ${i + 1} has condition: "${route.condition}"');
        final matches = await _conditionEvaluator!.evaluateCompound(route.condition!);
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
    
    // Second pass: Execute default route if no conditions matched
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      if (route.isDefault) {
        print('🚏 AUTOROUTE: No conditions matched, executing default route ${i + 1}');
        return await _executeRoute(route);
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    print('🚏 AUTOROUTE: No routes matched, using fallback nextMessageId: ${routeMessage.nextMessageId}');
    return routeMessage.nextMessageId;
  }

  /// Process dataAction messages by executing data modifications
  Future<int?> _processDataAction(ChatMessage dataActionMessage) async {
    if (_dataActionProcessor == null || dataActionMessage.dataActions == null) {
      return dataActionMessage.nextMessageId;
    }

    try {
      await _dataActionProcessor!.processActions(dataActionMessage.dataActions!);
    } catch (e) {
      // Silent error handling - dataActions should not fail the message flow
    }
    
    // Continue to next message
    return dataActionMessage.nextMessageId;
  }

  /// Execute a route condition by loading sequence or returning message ID
  Future<int?> _executeRoute(RouteCondition route) async {
    if (route.sequenceId != null) {
      final startMessageId = ChatConfig.initialMessageId;
      
      // Always load sequence directly for message accumulation
      await loadSequence(route.sequenceId!);
      
      // Note: No UI notification needed - messages are accumulated seamlessly
      
      return startMessageId;
    }
    
    // Stay in current sequence, go to specified message
    return route.nextMessageId;
  }
}