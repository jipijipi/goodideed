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
/// This version of the engine properly handles interactive conversations by:
/// 1. Stopping message flow after interactive messages (options/input)
/// 2. Waiting for user responses before continuing
/// 3. Processing responses and triggering follow-up events
/// 4. Maintaining conversation state across interactions
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
  Future<void> _processConversation() async {
    try {
      if (_currentScript == null) {
        await initialize();
      }
      
      print('🎭 ConversationEngine: Starting conversation for day ${_userState.dayInJourney}');
      
      // Process plot events first
      await _processPlotEvents();
      
      // Then process daily events if no response is pending
      if (_awaitingResponseForMessageId == null) {
        await _processDailyEvents();
      }
      
      // Save state
      await _saveUserState();
      
    } catch (e) {
      print('❌ ConversationEngine: Error in conversation: $e');
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
  Future<void> _processDailyEvents() async {
    final triggeredEvents = <DailyEvent>[];
    
    for (final event in _currentScript!.dailyEvents) {
      if (_shouldTriggerEvent(event)) {
        triggeredEvents.add(event);
      }
    }
    
    triggeredEvents.sort((a, b) => b.priority.compareTo(a.priority));
    
    for (final event in triggeredEvents) {
      await _processDailyEvent(event);
      
      // Stop if waiting for response
      if (_awaitingResponseForMessageId != null) {
        return;
      }
    }
  }

  /// Process a single daily event.
  Future<void> _processDailyEvent(DailyEvent event) async {
    print('🎯 Processing daily event: ${event.id}');
    
    final variant = _selectVariant(event.variants);
    if (variant == null) {
      print('⚠️ No suitable variant found for event ${event.id}');
      return;
    }
    
    _currentEventId = event.id;
    
    // Process messages until we hit an interactive one
    for (int i = 0; i < variant.messages.length; i++) {
      final scriptMessage = variant.messages[i];
      final message = await _convertScriptMessage(scriptMessage);
      
      // Enhance options with response callbacks if this is a daily event
      if (message.options != null) {
        final enhancedOptions = <MessageOption>[];
        for (final option in message.options!) {
          final response = event.responses[option.id];
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
        
        // Create new message with enhanced options
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
        // Add delay before message if specified
        if (message.delayMs != null && message.delayMs! > 0) {
          await Future.delayed(Duration(milliseconds: message.delayMs!));
        }
        
        _addMessage(message);
      }
      
      await _saveMessageToHistory(message);
      
      // Check if this message requires user interaction
      if (_requiresUserResponse(message)) {
        _awaitingResponseForMessageId = message.id;
        
        // Store remaining messages for after response
        if (i + 1 < variant.messages.length) {
          _pendingMessages = variant.messages.sublist(i + 1);
        }
        
        print('⏸️ Waiting for user response to message: ${message.id}');
        return; // Stop processing here
      }
    }
    
    // Update variables from variant
    if (variant.setVariables != null) {
      _updateVariables(variant.setVariables!);
    }
  }

  /// Handle user option selection.
  Future<void> selectOption(String messageId, String optionId) async {
    if (_awaitingResponseForMessageId != messageId) {
      print('⚠️ Not awaiting response for this message: $messageId');
      return;
    }
    
    print('✅ User selected option: $optionId for message: $messageId');
    
    // Clear awaiting state
    _awaitingResponseForMessageId = null;
    
    // Find the message and option
    final message = await _findMessage(messageId);
    final option = message?.options?.firstWhere((o) => o.id == optionId);
      print(message);
    if (option == null) {
      print('❌ Option not found: $optionId');
      return;
    }
    
    // Update variables from option
    if (option.setVariables != null) {
      _updateVariables(option.setVariables!);
    }
    
    // Handle next event or continue with pending messages
    if (option.nextEventId != null) {
      await _processEventById(option.nextEventId!);
    } else {
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
    
    // Save input to variables (you might want to customize this)
    _updateVariables({'last_input': input});
    
    // Continue with pending messages
    await _continuePendingMessages();
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
  bool _shouldTriggerEvent(DailyEvent event) {
    switch (event.trigger.type) {
      case 'time_window':
        if (!_isInTimeWindow(event.trigger)) {
          return false;
        }
        break;
      case 'user_action':
        // Would check for specific user actions
        break;
      case 'achievement':
        // Would check for achievement conditions
        break;
    }
    
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
  bool _evaluateConditions(Map<String, dynamic> conditions) {
    for (final entry in conditions.entries) {
      final key = entry.key;
      final expected = entry.value;
      final actual = _userState.variables[key];
      
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
        if (actual != expected) {
          return false;
        }
      }
    }
    
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
