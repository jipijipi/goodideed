import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../models/chat_sequence.dart';
import '../../services/chat_service.dart';
import '../../services/user_data_service.dart';
import '../../services/text_templating_service.dart';
import '../../services/text_variants_service.dart';
import '../../services/message_queue.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';

/// Manages the state and business logic for the chat screen
/// Handles message loading, user interactions, and conversation flow
class ChatStateManager extends ChangeNotifier {
  // Services
  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final TextVariantsService _variantsService;
  late final ChatService _chatService;
  late final MessageQueue _messageQueue;

  // State
  List<ChatMessage> _displayedMessages = [];
  ChatMessage? _currentTextInputMessage;
  bool _isPanelVisible = false;
  bool _disposed = false;
  String _currentSequenceId = AppConstants.defaultSequenceId;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // Getters
  List<ChatMessage> get displayedMessages => _displayedMessages;
  ChatMessage? get currentTextInputMessage => _currentTextInputMessage;
  bool get isPanelVisible => _isPanelVisible;
  ScrollController get scrollController => _scrollController;
  UserDataService get userDataService => _userDataService;
  String get currentSequenceId => _currentSequenceId;
  ChatSequence? get currentSequence => _chatService.currentSequence;

  /// Initialize the chat state manager
  Future<void> initialize() async {
    _initializeServices();
    await _loadAndDisplayMessages();
  }

  /// Initialize all required services
  void _initializeServices() {
    _userDataService = UserDataService();
    _templatingService = TextTemplatingService(_userDataService);
    _variantsService = TextVariantsService();
    _chatService = ChatService(
      userDataService: _userDataService,
      templatingService: _templatingService,
      variantsService: _variantsService,
    );
    _messageQueue = MessageQueue();
    
    // Set up callback for autoroute sequence switching
    _chatService.setSequenceSwitchCallback(_switchToSequenceFromAutoroute);
  }

  /// Load chat script and display initial messages
  Future<void> _loadAndDisplayMessages() async {
    try {
      await _chatService.getInitialMessages(sequenceId: _currentSequenceId);
      if (!_disposed) {
        await _simulateInitialChat();
      }
    } catch (e) {
      // Handle error silently or add error handling as needed
      debugPrint('Error loading chat script: $e');
    }
  }

  /// Start the initial chat conversation
  Future<void> _simulateInitialChat() async {
    final initialMessages = await _chatService.getInitialMessages(sequenceId: _currentSequenceId);
    await _displayMessages(initialMessages);
  }

  /// Display a list of messages with delays and animations
  Future<void> _displayMessages(List<ChatMessage> messages) async {
    debugPrint('📱 DISPLAY_MESSAGES: Starting to display ${messages.length} messages');
    
    // Filter out duplicates and empty messages
    final filteredMessages = messages.where((message) {
      // Skip messages that are already displayed to prevent duplicates
      final isDuplicate = _displayedMessages.any((existing) => 
        existing.id == message.id && 
        existing.text == message.text &&
        existing.sender == message.sender
      );
      
      if (isDuplicate) {
        debugPrint('📱 DISPLAY_MESSAGES: Skipping duplicate message ID ${message.id}: "${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}..."');
        return false;
      }
      
      // Skip messages with empty text that are not interactive
      if (message.text.trim().isEmpty && !message.isChoice && !message.isTextInput) {
        debugPrint('📱 DISPLAY_MESSAGES: Skipping empty non-interactive message ID ${message.id}');
        return false;
      }
      
      return true;
    }).toList();
    
    debugPrint('📱 DISPLAY_MESSAGES: After filtering: ${filteredMessages.length} messages to display');
    
    // Log filtered messages for debugging
    for (int i = 0; i < filteredMessages.length && i < 5; i++) {
      final msg = filteredMessages[i];
      debugPrint('📱 DISPLAY_MESSAGES: Filtered message ${i + 1}: ID=${msg.id}, Text="${msg.text.substring(0, msg.text.length > 30 ? 30 : msg.text.length)}...", Delay=${msg.delay}ms');
    }
    
    // Enqueue messages for processing
    debugPrint('📱 DISPLAY_MESSAGES: Enqueueing ${filteredMessages.length} messages to MessageQueue');
    await _messageQueue.enqueue(filteredMessages, (message) async {
      if (_disposed) return;
      
      debugPrint('📱 DISPLAY_MESSAGES: Actually displaying message ID ${message.id}: "${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}..."');
      _displayedMessages.add(message);
      notifyListeners();
      
      // Scroll to bottom after adding message
      _scrollToBottom();
      
      // Handle interactive messages
      if (message.isTextInput) {
        debugPrint('📱 DISPLAY_MESSAGES: Setting text input message ID ${message.id}');
        _currentTextInputMessage = message;
        notifyListeners();
      }
    });
    
    debugPrint('📱 DISPLAY_MESSAGES: Completed displaying messages. Total displayed: ${_displayedMessages.length}');
  }

  /// Scroll to the bottom of the message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: UIConstants.scrollAnimationDuration,
          curve: UIConstants.scrollAnimationCurve,
        );
      }
    });
  }

  /// Handle user choice selection
  Future<void> onChoiceSelected(Choice choice, ChatMessage choiceMessage) async {
    // Store the user's choice if storeKey is provided
    await _chatService.handleUserChoice(choiceMessage, choice);
    
    // Update choice message to mark the selected choice and disable interaction
    final choiceIndex = _displayedMessages.indexOf(choiceMessage);
    if (choiceIndex != -1) {
      _displayedMessages[choiceIndex] = ChatMessage(
        id: choiceMessage.id,
        text: choiceMessage.text,
        delay: choiceMessage.delay,
        sender: choiceMessage.sender,
        type: MessageType.choice, // Keep as choice message
        choices: choiceMessage.choices,
        nextMessageId: choiceMessage.nextMessageId,
        storeKey: choiceMessage.storeKey,
        placeholderText: choiceMessage.placeholderText,
        selectedChoiceText: choice.text, // Mark which choice was selected
      );
      notifyListeners();
    }

    // Check if this choice switches sequences
    if (choice.sequenceId != null) {
      debugPrint('SEQUENCE: Switching to sequence: ${choice.sequenceId}');
      await _switchToSequenceFromChoice(choice.sequenceId!, 1);
    } else if (choice.nextMessageId != null) {
      debugPrint('CONTINUE: Continuing in current sequence to message: ${choice.nextMessageId}');
      await _continueWithChoice(choice.nextMessageId!);
    } else {
      debugPrint('END: Choice has no next action - conversation may end here');
    }
  }

  /// Continue conversation after choice selection
  Future<void> _continueWithChoice(int nextMessageId) async {
    final nextMessages = await _chatService.getMessagesAfterChoice(nextMessageId);
    await _displayMessages(nextMessages);
  }

  /// Unified sequence switching method for both choices and autoroutes
  Future<void> _switchSequence(String sequenceId, int startMessageId, {String source = 'unknown'}) async {
    if (_disposed) return;
    
    try {
      debugPrint('🔄 SEQUENCE_SWITCH: Starting sequence switch from $source...');
      debugPrint('🔄 SEQUENCE_SWITCH: Current sequence: $_currentSequenceId');
      debugPrint('🔄 SEQUENCE_SWITCH: Target sequence: $sequenceId');
      debugPrint('🔄 SEQUENCE_SWITCH: Start message ID: $startMessageId');
      debugPrint('🔄 SEQUENCE_SWITCH: Current displayed messages: ${_displayedMessages.length}');
      
      // Clear current text input message
      _currentTextInputMessage = null;
      _currentSequenceId = sequenceId;
      
      // Load the new sequence
      debugPrint('🔄 SEQUENCE_SWITCH: Loading sequence "$sequenceId"...');
      await _chatService.loadSequence(sequenceId);
      debugPrint('🔄 SEQUENCE_SWITCH: New sequence loaded: ${_chatService.currentSequence?.name}');
      debugPrint('🔄 SEQUENCE_SWITCH: Sequence has ${_chatService.currentSequence?.messages.length} messages');
      
      // Get messages starting from the specified message ID
      debugPrint('🔄 SEQUENCE_SWITCH: Getting messages starting from ID $startMessageId...');
      final nextMessages = await _chatService.getMessagesAfterChoice(startMessageId);
      debugPrint('🔄 SEQUENCE_SWITCH: Found ${nextMessages.length} messages to display');
      
      // Log first few messages for debugging
      for (int i = 0; i < nextMessages.length && i < 3; i++) {
        final msg = nextMessages[i];
        debugPrint('🔄 SEQUENCE_SWITCH: Message ${i + 1}: ID=${msg.id}, Text="${msg.text.substring(0, msg.text.length > 30 ? 30 : msg.text.length)}..."');
      }
      
      // Display the new sequence messages
      debugPrint('🔄 SEQUENCE_SWITCH: Displaying ${nextMessages.length} messages...');
      await _displayMessages(nextMessages);
      
      notifyListeners();
      debugPrint('🔄 SEQUENCE_SWITCH: Sequence switch completed successfully');
      debugPrint('🔄 SEQUENCE_SWITCH: Total displayed messages now: ${_displayedMessages.length}');
    } catch (e) {
      debugPrint('🔄 SEQUENCE_SWITCH_ERROR: Error switching sequence from $source: $e');
    }
  }

  /// Switch to a different sequence from a choice selection
  Future<void> _switchToSequenceFromChoice(String sequenceId, int startMessageId) async {
    await _switchSequence(sequenceId, startMessageId, source: 'choice');
  }

  /// Switch to a different sequence from an autoroute
  Future<void> _switchToSequenceFromAutoroute(String sequenceId, int startMessageId) async {
    await _switchSequence(sequenceId, startMessageId, source: 'autoroute');
  }

  /// Handle user text input submission
  Future<void> onTextInputSubmitted(String userInput, ChatMessage textInputMessage) async {
    if (userInput.trim().isEmpty) return;

    // Store the user's input if storeKey is provided
    await _chatService.handleUserTextInput(textInputMessage, userInput.trim());

    // Create user response message
    final userResponseMessage = _chatService.createUserResponseMessage(
      textInputMessage.id + AppConstants.userResponseIdOffset,
      userInput.trim(),
    );

    // Add user response as new message instead of replacing
    _displayedMessages.add(userResponseMessage);
    _currentTextInputMessage = null;
    notifyListeners();
    
    // Scroll to bottom to show the new user response
    _scrollToBottom();

    // Continue with next messages if available
    if (textInputMessage.nextMessageId != null) {
      await _continueWithTextInput(textInputMessage.nextMessageId!, userInput.trim());
    }
  }

  /// Continue conversation after text input
  Future<void> _continueWithTextInput(int nextMessageId, String userInput) async {
    final nextMessages = await _chatService.getMessagesAfterTextInput(nextMessageId, userInput);
    await _displayMessages(nextMessages);
  }

  /// Toggle the user variables panel visibility
  void togglePanel() {
    _isPanelVisible = !_isPanelVisible;
    notifyListeners();
  }

  /// Switch to a different chat sequence
  Future<void> switchSequence(String sequenceId) async {
    if (_disposed || sequenceId == _currentSequenceId) return;
    
    try {
      // Clear current state
      _displayedMessages.clear();
      _currentTextInputMessage = null;
      _currentSequenceId = sequenceId;
      
      // Load new sequence
      await _chatService.getInitialMessages(sequenceId: sequenceId);
      await _simulateInitialChat();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching sequence: $e');
    }
  }

  /// Debug Control: Reset current chat sequence
  Future<void> resetChat() async {
    if (_disposed) return;
    
    try {
      debugPrint('DEBUG: Resetting chat sequence: $_currentSequenceId');
      
      // Clear current state
      _displayedMessages.clear();
      _currentTextInputMessage = null;
      
      // Reload current sequence from beginning
      await _chatService.getInitialMessages(sequenceId: _currentSequenceId);
      await _simulateInitialChat();
      
      notifyListeners();
      debugPrint('DEBUG: Chat reset completed');
    } catch (e) {
      debugPrint('DEBUG ERROR: Failed to reset chat: $e');
    }
  }

  /// Debug Control: Clear displayed messages only
  void clearMessages() {
    if (_disposed) return;
    
    debugPrint('DEBUG: Clearing displayed messages');
    
    // Clear messages but keep sequence loaded
    _displayedMessages.clear();
    _currentTextInputMessage = null;
    
    notifyListeners();
    debugPrint('DEBUG: Messages cleared');
  }

  /// Debug Control: Reload current sequence from file
  Future<void> reloadSequence() async {
    if (_disposed) return;
    
    try {
      debugPrint('DEBUG: Reloading sequence: $_currentSequenceId');
      
      // Force reload sequence from JSON file
      await _chatService.loadSequence(_currentSequenceId);
      
      // Reset chat with newly loaded sequence
      await resetChat();
      
      debugPrint('DEBUG: Sequence reloaded successfully');
    } catch (e) {
      debugPrint('DEBUG ERROR: Failed to reload sequence: $e');
    }
  }

  /// Debug Control: Clear all stored user data
  Future<void> clearAllUserData() async {
    if (_disposed) return;
    
    try {
      debugPrint('DEBUG: Clearing all user data');
      
      // Clear all stored user variables
      await _userDataService.clearAllData();
      
      debugPrint('DEBUG: All user data cleared successfully');
    } catch (e) {
      debugPrint('DEBUG ERROR: Failed to clear user data: $e');
    }
  }

  /// Dispose of resources and cancel timers
  @override
  void dispose() {
    _disposed = true;
    
    // Dispose the message queue
    _messageQueue.dispose();
    
    _scrollController.dispose();
    super.dispose();
  }
}