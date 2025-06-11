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
/// This updated provider works with the enhanced conversation engine that properly
/// handles response waiting. It coordinates between:
/// - Message flow from the engine to the UI
/// - User interactions and responses  
/// - State persistence
/// - Error handling and recovery
/// 
/// Key improvement: The system now properly pauses after interactive messages
/// and waits for user responses before continuing the conversation flow.
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
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Initialize components
      await _engine.initialize();
      await _localization.setLanguage(state.language);
      
      // Load conversation history
      await _loadConversationHistory();
      
      // Start daily conversation flow if needed
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
  /// This is where messages from the engine are added to the UI state.
  void _handleEngineMessage(EnhancedMessageModel message) {
    // Add message to state
    state = state.copyWith(
      messages: [...state.messages, message],
      error: null,
    );
    
    // If this message expects a response, update the state
    if (message.options != null || message.inputConfig != null) {
      state = state.copyWith(
        awaitingResponse: true,
        currentInteractionId: message.id,
        isProcessing: false, // Stop processing indicator when waiting for user
      );
    } else {
      // Clear awaiting response if this is not an interactive message
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
  /// This handles when the user clicks one of the provided options.
  /// The engine will process the response and continue the conversation.
  Future<void> selectOption(String messageId, MessageOption option) async {
    // Create user message showing their choice
    final userMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: option.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Add to state immediately for UI feedback
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      awaitingResponse: false,
      isProcessing: true, // Show processing while engine handles response
    );
    
    // Save to database
    await _saveMessage(userMessage);
    
    // Execute option callback if it exists
    if (option.onTap != null) {
      option.onTap!();
    }
    
    // Notify engine of user's choice - this will trigger follow-up messages
    await _engine.selectOption(messageId, option.id);
  }

  /// Submit input from an input field message.
  /// 
  /// This handles when the user submits text in response to an input request.
  /// The engine will process the input and continue the conversation.
  Future<void> submitInput(String messageId, String input) async {
    // Create user message with their input
    final userMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: input,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Add to state immediately for UI feedback
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      awaitingResponse: false,
      isProcessing: true, // Show processing while engine handles input
    );
    
    // Save to database
    await _saveMessage(userMessage);
    
    // Notify engine of user's input - this will trigger follow-up messages
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
