import 'dart:async';
import 'dart:math';
import 'enhanced_message_model.dart';
import 'script_model.dart';
import 'script_manager.dart';
import '../../utils/database/conversation_database.dart';

/// The ConversationEngine is the maestro of our conversation system.
/// 
/// Like a conductor directing an orchestra, it coordinates all the different
/// components to create a harmonious conversation experience. It reads the script
/// (the sheet music), evaluates the current state (which instruments should play),
/// and produces messages (the actual music) that the user experiences.
/// 
/// Key responsibilities:
/// 1. **Event Processing**: Determine which events should trigger based on time and conditions
/// 2. **Variant Selection**: Choose the most appropriate variant based on user state
/// 3. **Message Generation**: Transform script messages into actual UI messages
/// 4. **State Management**: Track and update conversation progress
/// 5. **Branching Logic**: Handle user choices and their consequences
/// 
/// The engine uses a streaming approach (Stream<EnhancedMessageModel>) because conversations
/// unfold over time. This allows for natural pacing with delays between messages,
/// creating a more engaging and less overwhelming experience.
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

  ConversationEngine({
    required String language,
  }) : _scriptManager = ScriptManager(),
       _database = ConversationDatabase(),
       _language = language;

  /// Initialize the engine with user state.
  /// 
  /// This is like setting up the stage before a performance - we need to know
  /// where we left off, what props are in place, and what scene we're in.
  Future<void> initialize() async {
    _userState = await _loadUserState();
    _currentScript = await _scriptManager.loadScript(language: _language);
  }

  /// Process daily conversation flow.
  /// 
  /// This is the main entry point that generates the conversation for the day.
  /// It's like running through today's script, considering both scheduled plot
  /// events and dynamic daily events that might trigger.
  /// 
  /// The method returns a Stream because conversations unfold over time.
  /// Each message appears with appropriate delays, creating a natural flow
  /// rather than dumping all messages at once.
  Stream<EnhancedMessageModel> processDaily() async* {
    try {
      // Ensure we're initialized
      if (_currentScript == null) {
        await initialize();
      }
      
      print('🎭 ConversationEngine: Starting daily processing for day ${_userState.dayInJourney}');
      
      // Step 1: Process plot events for the current day
      // These are the "main story" events tied to specific days
      yield* _processPlotEvents();
      
      // Step 2: Process triggered daily events
      // These are recurring events like check-ins that happen based on conditions
      yield* _processDailyEvents();
      
      // Step 3: Save updated state
      await _saveUserState();
      
    } catch (e) {
      print('❌ ConversationEngine: Error in processDaily: $e');
      // Generate an error message that maintains character
      yield EnhancedMessageModel.tristopherText(
        "Something's wrong with my circuits. How typical. Try again later.",
        style: BubbleStyle.error,
      );
    }
  }

  /// Process plot events for the current day.
  /// 
  /// Plot events are like chapters in a book - they advance the main narrative
  /// and are tied to specific days in the user's journey. Day 1 might introduce
  /// Tristopher, Day 7 might unlock new features, etc.
  Stream<EnhancedMessageModel> _processPlotEvents() async* {
    final dayKey = 'day_${_userState.dayInJourney}';
    final plotDay = _currentScript!.plotTimeline[dayKey];
    
    if (plotDay == null) {
      print('📅 No plot events for $dayKey');
      return;
    }
    
    // Check if this day's conditions are met
    if (plotDay.conditions != null) {
      if (!_evaluateConditions(plotDay.conditions!)) {
        print('🚫 Plot day conditions not met');
        return;
      }
    }
    
    // Process each event in sequence
    for (final event in plotDay.events) {
      yield* _processPlotEvent(event);
    }
  }

  /// Process a single plot event.
  Stream<EnhancedMessageModel> _processPlotEvent(PlotEvent event) async* {
    print('🎬 Processing plot event: ${event.id}');
    
    // Check event-specific conditions
    if (event.conditions != null) {
      if (!_evaluateConditions(event.conditions!)) {
        print('🚫 Event conditions not met');
        return;
      }
    }
    
    // Process each message in the event
    for (final scriptMessage in event.messages) {
      final message = await _convertScriptMessage(scriptMessage);
      yield message;
      
      // Apply delay if specified
      if (message.delayMs != null && message.delayMs! > 0) {
        await Future.delayed(Duration(milliseconds: message.delayMs!));
      }
      
      // Save message to history
      await _saveMessageToHistory(message);
    }
    
    // Update variables if specified
    if (event.setVariables != null) {
      _updateVariables(event.setVariables!);
    }
  }

  /// Process daily events that might trigger.
  /// 
  /// Daily events are like routines - they can happen any day when their
  /// conditions are met. Morning check-ins, achievement notifications, and
  /// streak celebrations are all daily events.
  /// 
  /// The engine evaluates all daily events and processes them in priority order.
  Stream<EnhancedMessageModel> _processDailyEvents() async* {
    final triggeredEvents = <DailyEvent>[];
    
    // Evaluate which events should trigger
    for (final event in _currentScript!.dailyEvents) {
      if (_shouldTriggerEvent(event)) {
        triggeredEvents.add(event);
      }
    }
    
    // Sort by priority (higher priority first)
    triggeredEvents.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Process each triggered event
    for (final event in triggeredEvents) {
      yield* _processDailyEvent(event);
    }
  }

  /// Check if a daily event should trigger.
  /// 
  /// This is like checking if all the conditions for a scene are met:
  /// - Is it the right time? (time window)
  /// - Are the prerequisites satisfied? (conditions)
  /// - Has it already happened today? (frequency limits)
  bool _shouldTriggerEvent(DailyEvent event) {
    // Check trigger type
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
    
    // Check general conditions
    return _evaluateConditions(event.trigger.conditions);
  }

  /// Check if current time is within the event's time window.
  bool _isInTimeWindow(EventTrigger trigger) {
    if (trigger.startTime == null || trigger.endTime == null) {
      return true; // No time restriction
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

  /// Process a single daily event.
  /// 
  /// This involves selecting the most appropriate variant and generating messages.
  Stream<EnhancedMessageModel> _processDailyEvent(DailyEvent event) async* {
    print('🎯 Processing daily event: ${event.id}');
    
    // Select the best variant based on conditions and weights
    final variant = _selectVariant(event.variants);
    if (variant == null) {
      print('⚠️ No suitable variant found for event ${event.id}');
      return;
    }
    
    // Process the variant's messages
    for (final scriptMessage in variant.messages) {
      final message = await _convertScriptMessage(scriptMessage);
      
      // If this message has options, set up response handling
      if (message.options != null) {
        // Enhance options with response handling
        message.options!.forEach((option) {
          final response = event.responses[option.id];
          if (response != null) {
            // Wrap the original onTap to include response handling
            final originalOnTap = option.onTap;
            option.onTap = () async {
              // Execute original action
              if (originalOnTap != null) {
                originalOnTap();
              }
              // Handle response
              await _handleEventResponse(response);
            };
          }
        });
      }
      
      yield message;
      
      // Apply delay
      if (message.delayMs != null && message.delayMs! > 0) {
        await Future.delayed(Duration(milliseconds: message.delayMs!));
      }
      
      // Save to history
      await _saveMessageToHistory(message);
    }
    
    // Update variables from variant
    if (variant.setVariables != null) {
      _updateVariables(variant.setVariables!);
    }
  }

  /// Select the most appropriate variant based on conditions and weights.
  /// 
  /// This is like casting for a play - we need to find the variant that:
  /// 1. Meets all the required conditions (actor must fit the role)
  /// 2. Has the highest probability of being selected (weighted random selection)
  /// 
  /// The weight system allows for variety - even if multiple variants are valid,
  /// we don't always pick the same one, keeping conversations fresh.
  EventVariant? _selectVariant(List<EventVariant> variants) {
    // Filter variants whose conditions are met
    final validVariants = variants.where((variant) {
      return _evaluateConditions(variant.conditions);
    }).toList();
    
    if (validVariants.isEmpty) {
      return null;
    }
    
    // If only one valid variant, return it
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
    
    // Fallback to first variant (shouldn't reach here)
    return validVariants.first;
  }

  /// Evaluate conditions against current user state.
  /// 
  /// Conditions are like IF statements in the script. They check things like:
  /// - Is the user's streak greater than 5?
  /// - Have they failed in the last 3 days?
  /// - Is their stake amount above $10?
  /// 
  /// This system is flexible - conditions are just key-value pairs that can
  /// check any aspect of the user's state.
  bool _evaluateConditions(Map<String, dynamic> conditions) {
    for (final entry in conditions.entries) {
      final key = entry.key;
      final expected = entry.value;
      
      // Get actual value from user state
      final actual = _userState.variables[key];
      
      // Handle different condition types
      if (expected is Map) {
        // Range conditions: {"min": 0, "max": 5}
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
        // Simple equality check
        if (actual != expected) {
          return false;
        }
      }
    }
    
    return true; // All conditions passed
  }

  /// Convert a script message into an enhanced message for display.
  /// 
  /// This is where the magic happens - we transform abstract script instructions
  /// into concrete messages with all their visual properties, animations, and content.
  Future<EnhancedMessageModel> _convertScriptMessage(ScriptMessage scriptMessage) async {
    // Get localized content
    String? content;
    if (scriptMessage.contentKey != null) {
      content = await _getLocalizedContent(scriptMessage.contentKey!);
    } else {
      content = scriptMessage.content;
    }
    
    // Apply template variables if needed
    if (content != null && content.contains('{{')) {
      content = _applyTemplateVariables(content);
    }
    
    // Parse visual properties
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
      metadata: properties['metadata'],
    );
  }

  /// Get localized content for a message key.
  /// 
  /// This supports multi-language conversations by looking up the appropriate
  /// translation for the current language.
  Future<String> _getLocalizedContent(String key) async {
    // In a full implementation, this would look up from localization files
    // For now, we'll return the key as placeholder
    return key;
  }

  /// Apply template variables to content.
  /// 
  /// This personalizes messages by replacing placeholders with actual values.
  /// "Hello {{name}}" becomes "Hello John"
  /// "You have a {{streak_count}} day streak!" becomes "You have a 7 day streak!"
  String _applyTemplateVariables(String content) {
    String result = content;
    
    // Find all variables in the format {{variable_name}}
    final variablePattern = RegExp(r'\{\{(\w+)\}\}');
    final matches = variablePattern.allMatches(content);
    
    for (final match in matches) {
      final variableName = match.group(1)!;
      final value = _userState.variables[variableName]?.toString() ?? '';
      result = result.replaceAll('{{$variableName}}', value);
    }
    
    return result;
  }

  /// Handle event response (user choice consequences).
  /// 
  /// When a user makes a choice, this method processes the consequences:
  /// - Trigger follow-up events
  /// - Update variables
  /// - Unlock achievements
  Future<void> _handleEventResponse(EventResponse response) async {
    // Update variables
    if (response.setVariables != null) {
      _updateVariables(response.setVariables!);
    }
    
    // Trigger next event if specified
    if (response.nextEventId != null) {
      // This would queue the next event for processing
      print('📍 Queueing next event: ${response.nextEventId}');
    }
    
    // Check for achievements
    if (response.achievementId != null) {
      // This would trigger achievement processing
      print('🏆 Achievement unlocked: ${response.achievementId}');
    }
  }

  /// Update user state variables.
  /// 
  /// Variables track everything about the user's journey - their choices,
  /// progress, preferences, and history. This method safely updates these
  /// variables and ensures persistence.
  void _updateVariables(Map<String, dynamic> updates) {
    updates.forEach((key, value) {
      _userState.variables[key] = value;
      print('📝 Updated variable: $key = $value');
    });
  }

  /// Save message to conversation history.
  /// 
  /// This creates a permanent record that users can review later and enables
  /// features like conversation search and analytics.
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
    
    // Create new state for first-time users
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
/// 
/// This is like a bookmark that remembers not just what page you're on, but also
/// all the choices you've made, paths you've taken, and achievements you've unlocked.
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
