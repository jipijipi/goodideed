import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../models/chat_sequence.dart';
import '../../services/chat_service.dart';
import '../../services/user_data_service.dart';
import '../../services/text_templating_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';

/// Manages the state and business logic for the chat screen
/// Handles message loading, user interactions, and conversation flow
class ChatStateManager extends ChangeNotifier {
  // Services
  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final ChatService _chatService;

  // State
  List<ChatMessage> _displayedMessages = [];
  ChatMessage? _currentTextInputMessage;
  bool _isPanelVisible = false;
  bool _disposed = false;
  String _currentSequenceId = AppConstants.defaultSequenceId;

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final List<Timer> _activeTimers = [];

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
    _chatService = ChatService(
      userDataService: _userDataService,
      templatingService: _templatingService,
    );
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
    // Process templates in messages before displaying
    final processedMessages = await _chatService.processMessageTemplates(messages);
    
    for (ChatMessage message in processedMessages) {
      if (_disposed) break;
      
      // Use Timer instead of Future.delayed for better control
      final completer = Completer<void>();
      final timer = Timer(Duration(milliseconds: message.delay), () {
        if (!_disposed) {
          _displayedMessages.add(message);
          notifyListeners();
          
          // Scroll to bottom after adding message
          _scrollToBottom();
        }
        completer.complete();
      });
      
      _activeTimers.add(timer);
      await completer.future;
      _activeTimers.remove(timer);
      
      if (_disposed) break;
      
      // Stop at choice messages or text input messages to wait for user interaction
      if (message.isChoice || message.isTextInput) {
        if (message.isTextInput) {
          _currentTextInputMessage = message;
          notifyListeners();
        }
        break;
      }
    }
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
    await _chatService.handleUserChoice(choiceMessage, choice.text);
    
    // Update choice message to mark the selected choice and disable interaction
    final choiceIndex = _displayedMessages.indexOf(choiceMessage);
    if (choiceIndex != -1) {
      _displayedMessages[choiceIndex] = ChatMessage(
        id: choiceMessage.id,
        text: choiceMessage.text,
        delay: choiceMessage.delay,
        sender: choiceMessage.sender,
        isChoice: true, // Keep as choice message
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
      await _switchToSequenceFromChoice(choice.sequenceId!, choice.nextMessageId ?? 1);
    } else if (choice.nextMessageId != null) {
      debugPrint('CONTINUE: Continuing in current sequence to message: ${choice.nextMessageId}');
      await _continueWithChoice(choice.nextMessageId!);
    } else {
      debugPrint('END: Choice has no next action - conversation may end here');
    }
  }

  /// Continue conversation after choice selection
  Future<void> _continueWithChoice(int nextMessageId) async {
    final nextMessages = _chatService.getMessagesAfterChoice(nextMessageId);
    await _displayMessages(nextMessages);
  }

  /// Switch to a different sequence from a choice selection
  Future<void> _switchToSequenceFromChoice(String sequenceId, int startMessageId) async {
    if (_disposed) return;
    
    try {
      debugPrint('SEQUENCE_SWITCH: Starting sequence switch from choice...');
      debugPrint('SEQUENCE_SWITCH: Target sequence: $sequenceId');
      debugPrint('SEQUENCE_SWITCH: Start message ID: $startMessageId');
      
      // Clear active timers but keep displayed messages for context
      _clearActiveTimers();
      _currentTextInputMessage = null;
      _currentSequenceId = sequenceId;
      
      // Load the new sequence
      await _chatService.loadSequence(sequenceId);
      debugPrint('SEQUENCE_SWITCH: New sequence loaded: ${_chatService.currentSequence?.name}');
      
      // Get messages starting from the specified message ID
      final nextMessages = _chatService.getMessagesAfterChoice(startMessageId);
      debugPrint('SEQUENCE_SWITCH: Found ${nextMessages.length} messages to display');
      
      // Display the new sequence messages
      await _displayMessages(nextMessages);
      
      notifyListeners();
      debugPrint('SEQUENCE_SWITCH: Sequence switch completed successfully');
    } catch (e) {
      debugPrint('SEQUENCE_SWITCH_ERROR: Error switching sequence from choice: $e');
    }
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

    // Replace text input bubble with user response
    final textInputIndex = _displayedMessages.indexOf(textInputMessage);
    if (textInputIndex != -1) {
      _displayedMessages[textInputIndex] = userResponseMessage;
      _currentTextInputMessage = null;
      notifyListeners();
    }

    // Continue with next messages if available
    if (textInputMessage.nextMessageId != null) {
      await _continueWithTextInput(textInputMessage.nextMessageId!, userInput.trim());
    }
  }

  /// Continue conversation after text input
  Future<void> _continueWithTextInput(int nextMessageId, String userInput) async {
    final nextMessages = _chatService.getMessagesAfterTextInput(nextMessageId, userInput);
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
      _clearActiveTimers();
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
      _clearActiveTimers();
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
    
    // Clear timers and messages but keep sequence loaded
    _clearActiveTimers();
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

  /// Clear all active timers
  void _clearActiveTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// Dispose of resources and cancel timers
  @override
  void dispose() {
    _disposed = true;
    
    // Cancel all active timers
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    _scrollController.dispose();
    super.dispose();
  }
}