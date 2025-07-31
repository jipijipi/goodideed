import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../models/chat_sequence.dart';
import '../../services/logger_service.dart';
import '../../services/service_locator.dart';
import '../../constants/app_constants.dart';
import 'state_management/message_display_manager.dart';
import 'state_management/user_interaction_handler.dart';

/// Orchestrates chat state management by coordinating focused components
/// Main controller that handles initialization, user actions, and debug controls
class ChatStateManager extends ChangeNotifier {
  // Component managers - use ServiceLocator for dependency injection
  late final MessageDisplayManager _messageDisplayManager;
  late final UserInteractionHandler _userInteractionHandler;

  // State
  bool _isPanelVisible = false;
  bool _disposed = false;
  String _currentSequenceId = AppConstants.defaultSequenceId;

  // Getters - delegate to appropriate managers
  List<ChatMessage> get displayedMessages => _messageDisplayManager.displayedMessages;
  ChatMessage? get currentTextInputMessage => _messageDisplayManager.currentTextInputMessage;
  bool get isPanelVisible => _isPanelVisible;
  ScrollController get scrollController => _messageDisplayManager.scrollController;
  GlobalKey<AnimatedListState> get animatedListKey => _messageDisplayManager.animatedListKey;
  String get currentSequenceId => _currentSequenceId;
  ChatSequence? get currentSequence => ServiceLocator.instance.chatService.currentSequence;

  // Service access
  get userDataService => ServiceLocator.instance.userDataService;

  /// Initialize the chat state manager
  Future<void> initialize() async {
    // Services are already initialized at app level via ServiceLocator
    
    // Initialize component managers
    _messageDisplayManager = MessageDisplayManager();
    _userInteractionHandler = UserInteractionHandler(
      messageDisplayManager: _messageDisplayManager,
      chatService: ServiceLocator.instance.chatService,
      messageQueue: ServiceLocator.instance.messageQueue,
    );

    await _messageDisplayManager.loadAndDisplayMessages(
      ServiceLocator.instance.chatService, 
      ServiceLocator.instance.messageQueue,
      _currentSequenceId, 
      notifyListeners,
    );
  }

  /// Handle user choice selection
  Future<void> onChoiceSelected(Choice choice, ChatMessage choiceMessage) async {
    await _userInteractionHandler.handleChoiceSelection(
      choice,
      choiceMessage,
      _currentSequenceId,
      _onSequenceChange,
      notifyListeners,
    );
  }

  /// Handle user text input submission
  Future<void> onTextInputSubmitted(String userInput, ChatMessage textInputMessage) async {
    await _userInteractionHandler.handleTextInputSubmission(
      userInput,
      textInputMessage,
      notifyListeners,
    );
  }

  /// Handle sequence change notifications
  void _onSequenceChange(String sequenceId) {
    _currentSequenceId = sequenceId;
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
      _messageDisplayManager.clearMessages();
      _currentSequenceId = sequenceId;
      
      // Load new sequence
      await _messageDisplayManager.loadAndDisplayMessages(
        ServiceLocator.instance.chatService,
        ServiceLocator.instance.messageQueue,
        _currentSequenceId,
        notifyListeners,
      );
      
      notifyListeners();
    } catch (e) {
      logger.error('Error switching sequence: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Reset current chat sequence
  Future<void> resetChat() async {
    if (_disposed) return;
    
    try {
      logger.debug('Resetting chat sequence: $_currentSequenceId', component: LogComponent.ui);
      
      // Clear current state
      _messageDisplayManager.clearMessages();
      
      // Reload current sequence from beginning
      await _messageDisplayManager.loadAndDisplayMessages(
        ServiceLocator.instance.chatService,
        ServiceLocator.instance.messageQueue,
        _currentSequenceId,
        notifyListeners,
      );
      
      notifyListeners();
      logger.debug('Chat reset completed', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to reset chat: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Clear displayed messages only
  void clearMessages() {
    if (_disposed) return;
    
    _messageDisplayManager.clearMessages();
    notifyListeners();
  }

  /// Debug Control: Reload current sequence from file
  Future<void> reloadSequence() async {
    if (_disposed) return;
    
    try {
      logger.debug('Reloading sequence: $_currentSequenceId', component: LogComponent.ui);
      
      // Force reload sequence from JSON file
      await ServiceLocator.instance.chatService.loadSequence(_currentSequenceId);
      
      // Reset chat with newly loaded sequence
      await resetChat();
      
      logger.debug('Sequence reloaded successfully', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to reload sequence: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Clear all stored user data
  Future<void> clearAllUserData() async {
    if (_disposed) return;
    
    try {
      logger.debug('Clearing all user data', component: LogComponent.ui);
      
      // Clear all stored user variables
      await ServiceLocator.instance.userDataService.clearAllData();
      
      logger.debug('All user data cleared successfully', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to clear user data: $e', component: LogComponent.ui);
    }
  }

  /// Dispose of resources and cancel timers
  @override
  void dispose() {
    _disposed = true;
    
    // Dispose component managers (ServiceLocator disposed at app level)
    _messageDisplayManager.dispose();
    _userInteractionHandler.dispose();
    
    super.dispose();
  }
}