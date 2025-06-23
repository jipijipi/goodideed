import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import '../../models/conversation/enhanced_message_model.dart';
import '../../models/conversation/conversation_engine.dart';
import '../../models/conversation/localization_manager.dart';
import '../../models/conversation/script_manager.dart';
import '../../utils/database/conversation_database.dart';

/// ConversationProvider is the bridge between our conversation system and the UI.
/// 
/// DAILY CONVERSATION STATE MANAGEMENT:
/// This provider orchestrates the complex state management required for
/// Tristopher's daily conversations, handling 10 key steps:
///
/// STEP 10: CONVERSATION LIFECYCLE MANAGEMENT
/// - Initialize conversation engine with user's language preference
/// - Load user state (streak, task, wager info) from database
/// - Determine which conversation variant to trigger based on user status
///
/// STEP 11: MESSAGE FLOW COORDINATION
/// - Receive message stream from conversation engine
/// - Update UI state as messages arrive from Tristopher
/// - Handle delays between messages for natural conversation pacing
///
/// STEP 12: INTERACTIVE RESPONSE COORDINATION
/// - Pause conversation flow when interactive messages appear
/// - Wait for user responses (option selection or text input)
/// - Resume conversation flow after user interaction
///
/// STEP 13: USER CHOICE PROCESSING
/// - Process option selections (success/failure/excuse responses)
/// - Handle text inputs (name, task description, etc.)
/// - Update user variables based on choices
///
/// STEP 14: CONSEQUENCE EXECUTION
/// - Trigger wager loss when user fails tasks
/// - Update streak counters for successes/failures
/// - Execute "on notice" system for excuse handling
///
/// STEP 15: STATE PERSISTENCE
/// - Save all conversation messages to database
/// - Persist updated user state for next day's conversation
/// - Cache conversation history for UI display
class ConversationNotifier extends StateNotifier<ConversationState> {
  final ConversationEngine _engine;
  final LocalizationManager _localization;
  final ConversationDatabase _database;
  
  // Stream subscription for engine messages
  StreamSubscription<EnhancedMessageModel>? _messageSubscription;

  ConversationNotifier({
    required String language,
  }) : _engine = ConversationEngine(language: language),
       _localization = LocalizationManager(),
       _database = ConversationDatabase(),
       super(const ConversationState()) {
    _initialize();
  }

  /// Initialize the conversation system.
  /// 
  /// STEP 16: SYSTEM INITIALIZATION & USER STATE ASSESSMENT
  /// This critical step determines which conversation path the user will experience
  /// based on their current status (new user, returning user, overdue task, etc.)
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Initialize conversation engine with user's historical data
      await _engine.initialize();
      await _localization.setLanguage(state.language);
      
      // Load today's conversation history (if user already interacted)
      await _loadConversationHistory();
      
      // STEP 17: DAILY FLOW DECISION POINT
      // Determine if we need to start a new daily conversation
      // or if user has already completed today's interaction
      await _checkAndStartDailyFlow();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('❌ ConversationNotifier: Initialization error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize conversation system',
      );
    }
  }

  /// Load existing conversation history.
  Future<void> _loadConversationHistory() async {
    try {
      // Load today's messages from database
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final historicalMessages = await _database.getMessages(
        startDate: startOfDay,
      );
      
      // Convert database records to EnhancedMessage objects
      final messages = historicalMessages.map((record) {
        return EnhancedMessageModel.fromJson(
          json.decode(record['metadata'] as String),
        );
      }).toList();
      
      // Reverse to get chronological order (database returns newest first)
      messages.reversed;
      
      state = state.copyWith(messages: messages);
    } catch (e) {
      print('⚠️ ConversationNotifier: Error loading history: $e');
    }
  }

  /// Check if daily conversation flow should start.
  Future<void> _checkAndStartDailyFlow() async {
    // Check if user has already interacted today
    final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;
    final hasInteractedToday = lastMessage != null && 
        _isSameDay(lastMessage.timestamp, DateTime.now());
    
    if (!hasInteractedToday) {
      // Start the daily conversation flow
      await startDailyConversation();
    }
  }

  /// Start the daily conversation flow.
  /// 
  /// This triggers the engine to process today's events and messages.
  /// The engine will now properly pause at interactive messages.
  Future<void> startDailyConversation() async {
    try {
      state = state.copyWith(isProcessing: true);
      
      // Cancel any existing subscription
      await _messageSubscription?.cancel();
      
      // Subscribe to engine messages using new startConversation method
      _messageSubscription = _engine.startConversation().listen(
        (message) => _handleEngineMessage(message),
        onError: (error) => _handleEngineError(error),
        onDone: () => _handleEngineComplete(),
      );
    } catch (e) {
      print('❌ ConversationNotifier: Error starting conversation: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to start conversation',
      );
    }
  }

  /// Handle a message from the conversation engine.
  /// 
  /// STEP 18: MESSAGE DELIVERY & INTERACTION DETECTION
  /// As Tristopher's messages arrive, we update the UI and detect
  /// when the conversation requires user input to continue.
  void _handleEngineMessage(EnhancedMessageModel message) {
    // Add Tristopher's message to the conversation display
    state = state.copyWith(
      messages: [...state.messages, message],
      error: null,
    );
    
    // STEP 19: CONVERSATION FLOW CONTROL
    // Check if this message requires user interaction (options or text input)
    if (message.options != null || message.inputConfig != null) {
      // Pause conversation flow - wait for user response
      state = state.copyWith(
        awaitingResponse: true,
        currentInteractionId: message.id,
        isProcessing: false, // Stop "Tristopher is thinking..." indicator
      );
    } else {
      // Continue conversation flow for non-interactive messages
      state = state.copyWith(
        awaitingResponse: false,
        currentInteractionId: null,
      );
    }
  }

  /// Handle engine errors.
  void _handleEngineError(dynamic error) {
    print('❌ ConversationNotifier: Engine error: $error');
    state = state.copyWith(
      isProcessing: false,
      error: 'Conversation error occurred',
    );
  }

  /// Handle engine completion.
  void _handleEngineComplete() {
    state = state.copyWith(
      isProcessing: false,
      awaitingResponse: false,
    );
    print('✅ ConversationNotifier: Engine processing complete');
  }

  /// Send a user message (free text).
  /// 
  /// This handles when the user types a custom message.
  Future<void> sendUserMessage(String text) async {
    // Create user message
    final userMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Add to state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      awaitingResponse: false,
    );
    
    // Save to database
    await _saveMessage(userMessage);
  }

  /// Select an option from a multiple choice message.
  /// 
  /// STEP 20: CRITICAL DECISION PROCESSING
  /// This handles the most important moments in the daily conversation:
  /// - "I completed it!" vs "I failed..." (determines streak/wager consequences)
  /// - Excuse vs no excuse (triggers "on notice" system)
  /// - Task continuation vs change (affects next day's conversation)
  Future<void> selectOption(String messageId, MessageOption option) async {
    // Show user's choice in the conversation immediately
    final userMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: option.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Update UI state to show user response and indicate Tristopher is processing
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      awaitingResponse: false,
      isProcessing: true, // Show "Tristopher is thinking..." while consequences execute
    );
    
    // Persist user choice for streak/failure tracking
    await _saveMessage(userMessage);
    
    // Execute any immediate consequences (UI updates, navigation, etc.)
    if (option.onTap != null) {
      option.onTap!();
    }
    
    // STEP 21: CONSEQUENCE CHAIN TRIGGER
    // Send user's choice to engine which will:
    // - Update user variables (streak, wager status, etc.)
    // - Execute financial consequences (wager losses)
    // - Determine and deliver Tristopher's response messages
    await _engine.selectOption(messageId, option.id);
  }

  /// Submit input from an input field message.
  /// 
  /// STEP 22: PERSONALIZATION DATA CAPTURE
  /// This handles when users provide personal information that shapes
  /// their unique experience with Tristopher:
  /// - Name (used in all future conversations: "Well, well, {{user_name}}")
  /// - Task description ("{{current_task}} by {{daily_deadline}}")
  /// - Custom responses that affect conversation flow
  Future<void> submitInput(String messageId, String input) async {
    // Display user's input in the conversation
    final userMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: input,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Update conversation state and show processing indicator
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      awaitingResponse: false,
      isProcessing: true, // Show processing while engine handles the personalization
    );
    
    // Store user input for future conversation personalization
    await _saveMessage(userMessage);
    
    // STEP 23: PERSONALIZATION PROCESSING
    // Send input to engine which will:
    // - Store data in user variables (user_name, current_task, etc.)
    // - Use the data to personalize Tristopher's responses
    // - Continue to next phase of conversation setup
    await _engine.submitInput(messageId, input);
  }

  /// Save a message to the database.
  Future<void> _saveMessage(EnhancedMessageModel message) async {
    try {
      await _database.saveMessage(
        id: message.id,
        sender: message.sender.toString().split('.').last,
        type: message.type.toString().split('.').last,
        content: message.content ?? '',
        metadata: message.toJson(),
      );
    } catch (e) {
      print('⚠️ ConversationNotifier: Error saving message: $e');
    }
  }

  /// Change the conversation language.
  Future<void> changeLanguage(String languageCode) async {
    state = state.copyWith(language: languageCode);
    await _localization.setLanguage(languageCode);
    
    // Restart conversation with new language
    await _initialize();
  }

  /// Clear conversation history.
  Future<void> clearHistory() async {
    state = state.copyWith(messages: []);
    // Database cleanup would be implemented here
  }

  /// Reset all user data and start fresh.
  Future<void> resetAllData() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Cancel any existing message subscription
      await _messageSubscription?.cancel();
      
      // Clear in-memory state
      state = state.copyWith(
        messages: [],
        isProcessing: false,
        awaitingResponse: false,
        currentInteractionId: null,
        error: null,
      );
      
      // Clear script cache
      final scriptManager = ScriptManager();
      await scriptManager.clearCache();
      
      // Clear database data
      await _database.clearUserState();
      await _database.clearMessages();
      await _database.clearScripts();
      
      // Reinitialize everything
      await _initialize();
      
      print('✅ ConversationNotifier: All data reset successfully');
    } catch (e) {
      print('❌ ConversationNotifier: Error resetting data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset data',
      );
    }
  }

  /// Check if engine is currently waiting for a response.
  bool get isEngineAwaitingResponse => _engine.isAwaitingResponse;
  
  /// Get the message ID the engine is waiting for a response to.
  String? get awaitingResponseForMessageId => _engine.awaitingResponseForMessageId;

  /// Check if two dates are the same day.
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Clear the current error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

/// ConversationState represents the current state of the conversation UI.
/// 
/// This is what the UI components react to - any change here triggers a rebuild
/// of relevant widgets.
class ConversationState {
  final List<EnhancedMessageModel> messages;
  final bool isLoading;
  final bool isProcessing;
  final bool awaitingResponse;
  final String? currentInteractionId;
  final String language;
  final String? error;

  const ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.awaitingResponse = false,
    this.currentInteractionId,
    this.language = 'en',
    this.error,
  });

  ConversationState copyWith({
    List<EnhancedMessageModel>? messages,
    bool? isLoading,
    bool? isProcessing,
    bool? awaitingResponse,
    String? currentInteractionId,
    String? language,
    String? error,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      awaitingResponse: awaitingResponse ?? this.awaitingResponse,
      currentInteractionId: currentInteractionId ?? this.currentInteractionId,
      language: language ?? this.language,
      error: error ?? this.error,
    );
  }
}

/// Provider definition for the conversation system.
/// 
/// This makes the conversation system available throughout the app via Riverpod.
final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  // Get user's preferred language (could come from settings)
  const language = 'en'; // Default to English
  
  return ConversationNotifier(language: language);
});

/// Convenience providers for specific aspects of the conversation state.

/// Provider for just the messages list
final conversationMessagesProvider = Provider<List<EnhancedMessageModel>>((ref) {
  return ref.watch(conversationProvider).messages;
});

/// Provider for checking if waiting for user response
final isAwaitingResponseProvider = Provider<bool>((ref) {
  return ref.watch(conversationProvider).awaitingResponse;
});

/// Provider for checking if conversation is processing
final isProcessingProvider = Provider<bool>((ref) {
  return ref.watch(conversationProvider).isProcessing;
});

/// Provider for current error state
final conversationErrorProvider = Provider<String?>((ref) {
  return ref.watch(conversationProvider).error;
});
