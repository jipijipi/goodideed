import 'dart:async';
import 'dart:math';
import 'enhanced_message_model.dart';
import 'script_model.dart';
import 'script_manager.dart';
import '../../utils/database/conversation_database.dart';

// Extension to add firstOrNull method
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Enhanced ConversationEngine with proper response waiting.
/// 
/// DAILY CONVERSATION DECISION ENGINE:
/// This is the "brain" of Tristopher that orchestrates the entire daily conversation
/// experience through sophisticated decision-making and consequence logic:
///
/// STEP 24: USER STATE EVALUATION
/// - Analyzes user's current status (onboarded, task set, overdue, etc.)
/// - Selects appropriate conversation variant from script based on conditions
/// - Determines Tristopher's "mood" and response style
///
/// STEP 25: CONVERSATION SCRIPT PROCESSING
/// - Loads daily events from JSON script (default_script_en.json)
/// - Processes conditional logic to determine conversation path
/// - Handles message templating with user variables ({{user_name}}, {{current_task}})
///
/// STEP 26: INTERACTIVE MESSAGE FLOW CONTROL
/// - Streams messages to UI with proper timing and delays
/// - Pauses at option/input messages for user response
/// - Resumes flow after user interaction with appropriate follow-up
///
/// STEP 27: RESPONSE PROCESSING & VARIABLE UPDATES
/// - Processes user choices and updates state variables
/// - Executes conditional logic based on responses
/// - Triggers appropriate consequence chains
///
/// STEP 28: CONSEQUENCE EXECUTION
/// - Handles streak increments for successes
/// - Processes wager losses for failures
/// - Manages "on notice" system for excuse handling
/// - Updates user state for next day's conversation
class ConversationEngine {
  final ScriptManager _scriptManager;
  final ConversationDatabase _database;
  final String _language;
  
  // User state that persists across conversations
  late UserConversationState _userState;
  
  // Current script being processed
  Script? _currentScript;
  
  // Random number generator for variant selection
  final Random _random = Random();
  
  // Conversation flow control
  StreamController<EnhancedMessageModel>? _messageController;
  String? _awaitingResponseForMessageId;
  List<ScriptMessage> _pendingMessages = [];
  String? _currentEventId;
  
  // Message tracking for response handling
  final Map<String, EnhancedMessageModel> _messageHistory = {};

  ConversationEngine({
    required String language,
  }) : _scriptManager = ScriptManager(),
       _database = ConversationDatabase(),
       _language = language;

  /// Initialize the engine with user state.
  Future<void> initialize() async {
    _userState = await _loadUserState();
    _currentScript = await _scriptManager.loadScript(language: _language);
  }

  /// Start a new conversation session.
  /// 
  /// This creates a new message stream and begins processing events.
  Stream<EnhancedMessageModel> startConversation() {
    _messageController = StreamController<EnhancedMessageModel>.broadcast();
    
    // Start processing asynchronously
    _processConversation();
    
    return _messageController!.stream;
  }

  /// Process the conversation flow.
  /// 
  /// STEP 29: CONVERSATION ORCHESTRATION
  /// This is where the magic happens - determining what Tristopher says based on
  /// the user's current situation and previous interactions.
  Future<void> _processConversation() async {
    try {
      if (_currentScript == null) {
        await initialize();
      }
      
      print('🎭 ConversationEngine: Starting conversation for day ${_userState.dayInJourney}');
      
      // STEP 30: PLOT EVENT PROCESSING (Future Feature)
      // Process any special story events or milestones
      await _processPlotEvents();
      
      // STEP 31: DAILY EVENT PROCESSING
      // This is where the core daily conversation logic happens
      // Only proceed if we're not waiting for a user response
      if (_awaitingResponseForMessageId == null) {
        await _processDailyEvents();
      }
      
      // STEP 32: STATE PERSISTENCE
      // Save all changes to user state for tomorrow's conversation
      await _saveUserState();
      
    } catch (e) {
      print('❌ ConversationEngine: Error in conversation: $e');
      // Even errors get Tristopher's sarcastic treatment
      _addMessage(EnhancedMessageModel.tristopherText(
        "Something's wrong with my circuits. How typical. Try again later.",
        style: BubbleStyle.error,
      ));
    }
  }

  /// Process plot events for the current day.
  Future<void> _processPlotEvents() async {
    final dayKey = 'day_${_userState.dayInJourney}';
    final plotDay = _currentScript!.plotTimeline[dayKey];
    
    if (plotDay == null) {
      print('📅 No plot events for $dayKey');
      return;
    }
    
    if (plotDay.conditions != null && !_evaluateConditions(plotDay.conditions!)) {
      print('🚫 Plot day conditions not met');
      return;
    }
    
    // Process each event
    for (final event in plotDay.events) {
      await _processPlotEvent(event);
      
      // Stop if waiting for response
      if (_awaitingResponseForMessageId != null) {
        return;
      }
    }
  }

  /// Process a single plot event.
  Future<void> _processPlotEvent(PlotEvent event) async {
    print('🎬 Processing plot event: ${event.id}');
    
    if (event.conditions != null && !_evaluateConditions(event.conditions!)) {
      print('🚫 Event conditions not met');
      return;
    }
    
    _currentEventId = event.id;
    
    // Process messages until we hit an interactive one
    for (int i = 0; i < event.messages.length; i++) {
      final scriptMessage = event.messages[i];
      final message = await _convertScriptMessage(scriptMessage);
      
      // Add delay before message if specified
      if (message.delayMs != null && message.delayMs! > 0) {
        await Future.delayed(Duration(milliseconds: message.delayMs!));
      }
      
      _addMessage(message);
      await _saveMessageToHistory(message);
      
      // Check if this message requires user interaction
      if (_requiresUserResponse(message)) {
        _awaitingResponseForMessageId = message.id;
        
        // Store remaining messages for after response
        if (i + 1 < event.messages.length) {
          _pendingMessages = event.messages.sublist(i + 1);
        }
        
        print('⏸️ Waiting for user response to message: ${message.id}');
        return; // Stop processing here
      }
    }
    
    // Update variables if specified
    if (event.setVariables != null) {
      _updateVariables(event.setVariables!);
    }
  }

  /// Process daily events.
  /// 
  /// STEP 33: DAILY CONVERSATION VARIANT SELECTION
  /// This determines which conversation path the user experiences today
  /// based on their current status and history.
  Future<void> _processDailyEvents() async {
    final triggeredEvents = <DailyEvent>[];
    
    // STEP 34: EVENT FILTERING
    // Check all possible daily events to see which ones apply
    for (final event in _currentScript!.dailyEvents) {
      if (_shouldTriggerEvent(event)) {
        triggeredEvents.add(event);
      }
    }
    
    // Sort by priority (highest first) to ensure correct conversation order
    triggeredEvents.sort((a, b) => b.priority.compareTo(a.priority));
    
    // STEP 35: EVENT EXECUTION
    // Process each triggered event until we hit an interactive message
    for (final event in triggeredEvents) {
      await _processDailyEvent(event);
      
      // STEP 36: FLOW CONTROL
      // Stop processing if we're now waiting for user response
      // (This ensures conversation pauses at the right moments)
      if (_awaitingResponseForMessageId != null) {
        return;
      }
    }
  }

  /// Process a single daily event.
  /// 
  /// STEP 37: CONVERSATION VARIANT EXECUTION
  /// Each daily event can have multiple variants (different conversation paths)
  /// based on user conditions. This selects and executes the appropriate one.
  Future<void> _processDailyEvent(DailyEvent event) async {
    print('🎯 Processing daily event: ${event.id}');
    
    // STEP 38: VARIANT SELECTION
    // Choose the right conversation variant based on user's current state
    // (e.g., "not_onboarded" vs "onboarded_with_task_overdue")
    final variant = _selectVariant(event.variants);
    if (variant == null) {
      print('⚠️ No suitable variant found for event ${event.id}');
      return;
    }
    
    _currentEventId = event.id;
    
    // STEP 39: MESSAGE SEQUENCE PROCESSING
    // Process each message in the variant until we hit an interactive one
    for (int i = 0; i < variant.messages.length; i++) {
      final scriptMessage = variant.messages[i];
      final message = await _convertScriptMessage(scriptMessage);
      
      // STEP 40: OPTION ENHANCEMENT FOR CONSEQUENCE HANDLING
      // If this is an options message, enhance it with response callbacks
      if (message.options != null) {
        final enhancedOptions = <MessageOption>[];
        for (final option in message.options!) {
          final response = event.responses[option.id];
          // Link each option to its consequences (next events, variable updates)
          enhancedOptions.add(MessageOption(
            id: option.id,
            text: option.text,
            onTap: option.onTap,
            nextEventId: response?.nextEventId ?? option.nextEventId,
            setVariables: response?.setVariables ?? option.setVariables,
            enabled: option.enabled,
            disabledReason: option.disabledReason,
          ));
        }
        
        // Create enhanced message with consequence-linked options
        final enhancedMessage = EnhancedMessageModel(
          id: message.id,
          type: message.type,
          content: message.content,
          sender: message.sender,
          timestamp: message.timestamp,
          bubbleStyle: message.bubbleStyle,
          animation: message.animation,
          delayMs: message.delayMs,
          textEffect: message.textEffect,
          options: enhancedOptions,
          inputConfig: message.inputConfig,
          metadata: message.metadata,
          nextEventId: message.nextEventId,
          setVariables: message.setVariables,
          contentKey: message.contentKey,
          templateVariables: message.templateVariables,
        );
        
        _addMessage(enhancedMessage);
      } else {
        // STEP 41: NATURAL CONVERSATION PACING
        // Add realistic delays between messages for natural conversation flow
        if (message.delayMs != null && message.delayMs! > 0) {
          await Future.delayed(Duration(milliseconds: message.delayMs!));
        }
        
        _addMessage(message);
      }
      
      // Persist message for conversation history
      await _saveMessageToHistory(message);
      
      // STEP 42: INTERACTION CHECKPOINT
      // Check if this message requires user interaction
      if (_requiresUserResponse(message)) {
        _awaitingResponseForMessageId = message.id;
        
        // Store remaining messages to continue after user responds
        if (i + 1 < variant.messages.length) {
          _pendingMessages = variant.messages.sublist(i + 1);
        }
        
        print('⏸️ Waiting for user response to message: ${message.id}');
        return; // Pause conversation flow here
      }
    }
    
    // STEP 43: VARIANT COMPLETION
    // Update user variables based on this variant's completion
    if (variant.setVariables != null) {
      _updateVariables(variant.setVariables!);
    }
  }

  /// Handle user option selection.
  /// 
  /// STEP 44: CRITICAL CHOICE PROCESSING
  /// This is where user choices trigger the most important consequences:
  /// - Success responses increment streaks and provide encouragement
  /// - Failure responses trigger wager losses and streak resets
  /// - Excuse responses activate the "on notice" system
  Future<void> selectOption(String messageId, String optionId) async {
    if (_awaitingResponseForMessageId != messageId) {
      print('⚠️ Not awaiting response for this message: $messageId');
      return;
    }
    
    print('✅ User selected option: $optionId for message: $messageId');
    
    // Resume conversation flow
    _awaitingResponseForMessageId = null;
    
    // STEP 45: OPTION VALIDATION & RETRIEVAL
    // Find the selected option and its associated consequences
    final message = await _findMessage(messageId);
    final option = message?.options?.firstWhere((o) => o.id == optionId);
      print(message);
    if (option == null) {
      print('❌ Option not found: $optionId');
      return;
    }
    
    // STEP 46: IMMEDIATE VARIABLE UPDATES
    // Update user state based on their choice (streak, wager status, etc.)
    if (option.setVariables != null) {
      _updateVariables(option.setVariables!);
    }
    
    // STEP 47: CONSEQUENCE CHAIN EXECUTION
    // Either trigger a specific follow-up event or continue current flow
    if (option.nextEventId != null) {
      // Trigger specific consequence event (e.g., "success_response", "wager_loss")
      await _processEventById(option.nextEventId!);
    } else {
      // Continue with remaining messages in current sequence
      await _continuePendingMessages();
    }
  }

  /// Handle user text input submission.
  Future<void> submitInput(String messageId, String input) async {
    if (_awaitingResponseForMessageId != messageId) {
      print('⚠️ Not awaiting response for this message: $messageId');
      return;
    }
    
    print('✅ User submitted input: $input for message: $messageId');
    
    // Clear awaiting state
    _awaitingResponseForMessageId = null;
    
    // Save input to variables
    _updateVariables({'last_input': input});
    
    // Check if the input message has a nextEventId
    final message = await _findMessage(messageId);
    if (message?.nextEventId != null) {
      await _processEventById(message!.nextEventId!);
    } else {
      // Continue with pending messages if no specific next event
      await _continuePendingMessages();
    }
  }

  /// Continue processing pending messages after user response.
  Future<void> _continuePendingMessages() async {
    if (_pendingMessages.isEmpty) {
      print('✅ No pending messages, conversation flow complete');
      return;
    }
    
    print('▶️ Continuing with ${_pendingMessages.length} pending messages');
    
    // Process remaining messages
    for (int i = 0; i < _pendingMessages.length; i++) {
      final scriptMessage = _pendingMessages[i];
      final message = await _convertScriptMessage(scriptMessage);
      
      // Add delay before message if specified
      if (message.delayMs != null && message.delayMs! > 0) {
        await Future.delayed(Duration(milliseconds: message.delayMs!));
      }
      
      _addMessage(message);
      await _saveMessageToHistory(message);
      
      // Check if this message requires user interaction
      if (_requiresUserResponse(message)) {
        _awaitingResponseForMessageId = message.id;
        
        // Store remaining messages
        if (i + 1 < _pendingMessages.length) {
          _pendingMessages = _pendingMessages.sublist(i + 1);
        } else {
          _pendingMessages = [];
        }
        
        print('⏸️ Waiting for user response to message: ${message.id}');
        return; // Stop processing here
      }
    }
    
    // Clear pending messages
    _pendingMessages = [];
    
    // Continue with daily events if we haven't processed them yet
    if (_currentEventId == null || !_currentEventId!.startsWith('daily_')) {
      await _processDailyEvents();
    }
  }

  /// Process a specific event by ID.
  Future<void> _processEventById(String eventId) async {
    print('🎯 Processing event by ID: $eventId');
    
    // Look for the event in daily events
    final dailyEvent = _currentScript!.dailyEvents
        .where((e) => e.id == eventId)
        .firstOrNull;
        
    if (dailyEvent != null) {
      await _processDailyEvent(dailyEvent);
      return;
    }
    
    // Could also check plot events here if needed
    print('⚠️ Event not found: $eventId');
  }

  /// Check if a message requires user response.
  bool _requiresUserResponse(EnhancedMessageModel message) {
    return message.type == MessageType.options || 
           message.type == MessageType.input ||
           (message.options != null && message.options!.isNotEmpty);
  }

  /// Add a message to the stream.
  void _addMessage(EnhancedMessageModel message) {
    // Store message in history for response tracking
    _messageHistory[message.id] = message;
    _messageController?.add(message);
  }

  /// Find a message by ID from the in-memory history.
  Future<EnhancedMessageModel?> _findMessage(String messageId) async {
    // Check in-memory history first
    final message = _messageHistory[messageId];
    if (message != null) {
      return message;
    }
    
    // In a real implementation, this would also search the database
    // For now, just log and return null
    print('⚠️ Message not found in history: $messageId');
    return null;
  }

  /// Check if a daily event should trigger.
  /// 
  /// STEP 48: EVENT TRIGGER EVALUATION
  /// This determines which conversation variants are available based on:
  /// - Time of day (morning check-in vs evening reminder)
  /// - User state (onboarded, has task, overdue status)
  /// - Previous interactions (already visited today, on notice status)
  bool _shouldTriggerEvent(DailyEvent event) {
    switch (event.trigger.type) {
      case 'time_window':
        // Check if current time falls within event's active window
        if (!_isInTimeWindow(event.trigger)) {
          return false;
        }
        break;
      case 'user_action':
        // Future: Check for specific user actions that trigger events
        break;
      case 'achievement':
        // Future: Check for achievement milestones that trigger special conversations
        break;
    }
    
    // STEP 49: CONDITION EVALUATION
    // Final check: does user's current state match event requirements?
    return _evaluateConditions(event.trigger.conditions);
  }

  /// Check if current time is within the event's time window.
  bool _isInTimeWindow(EventTrigger trigger) {
    if (trigger.startTime == null || trigger.endTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final startParts = trigger.startTime!.split(':');
    final endParts = trigger.endTime!.split(':');
    
    final startTime = DateTime(now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final endTime = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
    
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Select the most appropriate variant based on conditions and weights.
  EventVariant? _selectVariant(List<EventVariant> variants) {
    final validVariants = variants.where((variant) {
      return _evaluateConditions(variant.conditions);
    }).toList();
    
    if (validVariants.isEmpty) {
      return null;
    }
    
    if (validVariants.length == 1) {
      return validVariants.first;
    }
    
    // Weighted random selection
    final totalWeight = validVariants.fold(0.0, (sum, v) => sum + v.weight);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (final variant in validVariants) {
      currentWeight += variant.weight;
      if (randomValue <= currentWeight) {
        return variant;
      }
    }
    
    return validVariants.first;
  }

  /// Evaluate conditions against current user state.
  /// 
  /// STEP 50: CONVERSATION LOGIC ENGINE
  /// This is the core decision-making logic that determines which conversation
  /// variant the user experiences based on their current state and history.
  /// Examples:
  /// - {"is_onboarded": false} → triggers first-time user onboarding flow
  /// - {"has_task_set": true, "is_overdue": true} → triggers overdue task check
  /// - {"is_on_notice": true} → triggers stricter failure consequences
  bool _evaluateConditions(Map<String, dynamic> conditions) {
    for (final entry in conditions.entries) {
      final key = entry.key;
      final expected = entry.value;
      final actual = _userState.variables[key];
      
      // Handle range conditions (e.g., streak count requirements)
      if (expected is Map) {
        if (expected.containsKey('min') || expected.containsKey('max')) {
          final value = actual is num ? actual : 0;
          if (expected.containsKey('min') && value < expected['min']) {
            return false;
          }
          if (expected.containsKey('max') && value > expected['max']) {
            return false;
          }
        }
      } else {
        // Handle exact value conditions (e.g., is_onboarded: true)
        if (actual != expected) {
          return false;
        }
      }
    }
    
    // All conditions met - this conversation variant is valid
    return true;
  }

  /// Convert a script message into an enhanced message for display.
  Future<EnhancedMessageModel> _convertScriptMessage(ScriptMessage scriptMessage) async {
    String? content;
    if (scriptMessage.contentKey != null) {
      content = await _getLocalizedContent(scriptMessage.contentKey!);
    } else {
      content = scriptMessage.content;
    }
    
    if (content != null && content.contains('{{')) {
      content = _applyTemplateVariables(content);
    }
    
    final properties = scriptMessage.properties ?? {};
    
    return EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseMessageType(scriptMessage.type),
      content: content,
      sender: _parseMessageSender(scriptMessage.sender),
      timestamp: DateTime.now(),
      bubbleStyle: _parseBubbleStyle(properties['bubbleStyle']),
      animation: _parseAnimationType(properties['animation']),
      delayMs: scriptMessage.delayMs,
      textEffect: _parseTextEffect(properties['textEffect']),
      options: scriptMessage.options != null
          ? scriptMessage.options!.map((o) => MessageOption.fromJson(o)).toList()
          : null,
      inputConfig: scriptMessage.inputConfig != null
          ? InputConfig.fromJson(scriptMessage.inputConfig!)
          : null,
      metadata: properties['metadata'],
      nextEventId: scriptMessage.nextEventId, // Add this line
    );
  }

  /// Get localized content for a message key.
  Future<String> _getLocalizedContent(String key) async {
    return key;
  }

  /// Apply template variables to content.
  String _applyTemplateVariables(String content) {
    String result = content;
    final variablePattern = RegExp(r'\{\{(\w+)\}\}');
    final matches = variablePattern.allMatches(content);
    
    for (final match in matches) {
      final variableName = match.group(1)!;
      final value = _userState.variables[variableName]?.toString() ?? '';
      result = result.replaceAll('{{$variableName}}', value);
    }
    
    return result;
  }

  /// Update user state variables.
  void _updateVariables(Map<String, dynamic> updates) {
    updates.forEach((key, value) {
      _userState.variables[key] = value;
      print('📝 Updated variable: $key = $value');
    });
  }

  /// Save message to conversation history.
  Future<void> _saveMessageToHistory(EnhancedMessageModel message) async {
    await _database.saveMessage(
      id: message.id,
      sender: message.sender.toString().split('.').last,
      type: message.type.toString().split('.').last,
      content: message.content ?? '',
      metadata: message.toJson(),
    );
  }

  /// Load user conversation state from database.
  Future<UserConversationState> _loadUserState() async {
    final savedState = await _database.getUserState('conversation_state');
    if (savedState != null) {
      return UserConversationState.fromJson(savedState);
    }
    
    return UserConversationState(
      scriptVersion: _currentScript?.version ?? '1.0.0',
      dayInJourney: 1,
      activeBranches: [],
      variables: {
        'first_time': true,
        'streak_count': 0,
        'total_completions': 0,
        'total_failures': 0,
      },
      lastInteraction: DateTime.now(),
    );
  }

  /// Save user conversation state to database.
  Future<void> _saveUserState() async {
    await _database.saveUserState(
      'conversation_state',
      _userState.toJson(),
    );
  }

  /// Check if currently waiting for user response.
  bool get isAwaitingResponse => _awaitingResponseForMessageId != null;
  
  /// Get the message ID we're waiting for response to.
  String? get awaitingResponseForMessageId => _awaitingResponseForMessageId;

  /// Dispose of resources.
  void dispose() {
    _messageController?.close();
    _messageHistory.clear();
  }

  // Parsing helper methods
  MessageType _parseMessageType(String type) {
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => MessageType.text,
    );
  }

  MessageSender _parseMessageSender(String sender) {
    return MessageSender.values.firstWhere(
      (e) => e.toString().split('.').last == sender,
      orElse: () => MessageSender.tristopher,
    );
  }

  BubbleStyle? _parseBubbleStyle(String? style) {
    if (style == null) return null;
    return BubbleStyle.values.firstWhere(
      (e) => e.toString().split('.').last == style,
      orElse: () => BubbleStyle.normal,
    );
  }

  AnimationType? _parseAnimationType(String? animation) {
    if (animation == null) return AnimationType.slideIn;
    return AnimationType.values.firstWhere(
      (e) => e.toString().split('.').last == animation,
      orElse: () => AnimationType.slideIn,
    );
  }

  TextEffect? _parseTextEffect(String? effect) {
    if (effect == null) return null;
    return TextEffect.values.firstWhere(
      (e) => e.toString().split('.').last == effect,
      orElse: () => TextEffect.none,
    );
  }
}

/// UserConversationState tracks the user's progress through the conversation system.
class UserConversationState {
  final String scriptVersion;
  final int dayInJourney;
  final List<String> activeBranches;
  final Map<String, dynamic> variables;
  final DateTime lastInteraction;

  UserConversationState({
    required this.scriptVersion,
    required this.dayInJourney,
    required this.activeBranches,
    required this.variables,
    required this.lastInteraction,
  });

  factory UserConversationState.fromJson(Map<String, dynamic> json) {
    return UserConversationState(
      scriptVersion: json['script_version'],
      dayInJourney: json['day_in_journey'],
      activeBranches: List<String>.from(json['active_branches']),
      variables: json['variables'],
      lastInteraction: DateTime.parse(json['last_interaction']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'script_version': scriptVersion,
      'day_in_journey': dayInJourney,
      'active_branches': activeBranches,
      'variables': variables,
      'last_interaction': lastInteraction.toIso8601String(),
    };
  }
}
