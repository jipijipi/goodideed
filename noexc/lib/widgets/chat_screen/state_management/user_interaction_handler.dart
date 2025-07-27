import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../models/choice.dart';
import '../../../services/chat_service.dart';
import '../../../services/message_queue.dart';
import '../../../services/logger_service.dart';
import '../../../constants/app_constants.dart';
import 'message_display_manager.dart';

/// Handles user interactions including choice selections and text input
class UserInteractionHandler {
  final MessageDisplayManager _messageDisplayManager;
  final ChatService _chatService;
  final MessageQueue _messageQueue;
  
  bool _disposed = false;

  UserInteractionHandler({
    required MessageDisplayManager messageDisplayManager,
    required ChatService chatService,
    required MessageQueue messageQueue,
  }) : _messageDisplayManager = messageDisplayManager,
       _chatService = chatService,
       _messageQueue = messageQueue;

  /// Handle user choice selection
  Future<void> handleChoiceSelection(
    Choice choice, 
    ChatMessage choiceMessage, 
    String currentSequenceId,
    Function(String) onSequenceChange,
    VoidCallback notifyListeners,
  ) async {
    // Store the user's choice if storeKey is provided
    await _chatService.handleUserChoice(choiceMessage, choice);
    
    // Update choice message to mark the selected choice and disable interaction
    _messageDisplayManager.updateChoiceMessage(choiceMessage, choice.text);
    notifyListeners();

    // Check if this choice switches sequences
    if (choice.sequenceId != null) {
      logger.info('Switching to sequence: ${choice.sequenceId}', component: LogComponent.ui);
      await _switchToSequenceFromChoice(choice.sequenceId!, 1, onSequenceChange, notifyListeners);
    } else if (choice.nextMessageId != null) {
      logger.debug('Continuing in current sequence to message: ${choice.nextMessageId}', component: LogComponent.ui);
      await _continueWithChoice(choice.nextMessageId!, notifyListeners);
    } else {
      logger.warning('Choice has no next action - conversation may end here', component: LogComponent.ui);
    }
  }

  /// Handle user text input submission
  Future<void> handleTextInputSubmission(
    String userInput, 
    ChatMessage textInputMessage,
    VoidCallback notifyListeners,
  ) async {
    if (userInput.trim().isEmpty) return;

    // Store the user's input if storeKey is provided
    await _chatService.handleUserTextInput(textInputMessage, userInput.trim());

    // Create user response message
    final userResponseMessage = _chatService.createUserResponseMessage(
      textInputMessage.id + AppConstants.userResponseIdOffset,
      userInput.trim(),
    );

    // Add user response as new message instead of replacing
    _messageDisplayManager.addUserResponseMessage(userResponseMessage);
    _messageDisplayManager.currentTextInputMessage = null;
    notifyListeners();

    // Continue with next messages if available
    if (textInputMessage.nextMessageId != null) {
      await _continueWithTextInput(textInputMessage.nextMessageId!, userInput.trim(), notifyListeners);
    }
  }

  /// Continue conversation after choice selection
  Future<void> _continueWithChoice(int nextMessageId, VoidCallback notifyListeners) async {
    final nextMessages = await _chatService.getMessagesAfterChoice(nextMessageId);
    await _messageDisplayManager.displayMessages(nextMessages, _messageQueue, notifyListeners);
  }

  /// Switch to a different sequence from a choice selection
  Future<void> _switchToSequenceFromChoice(
    String sequenceId, 
    int startMessageId, 
    Function(String) onSequenceChange,
    VoidCallback notifyListeners,
  ) async {
    if (_disposed) return;
    
    try {
      // Clear current text input message and update sequence tracking
      _messageDisplayManager.currentTextInputMessage = null;
      onSequenceChange(sequenceId);
      
      // Load the new sequence and get messages
      await _chatService.loadSequence(sequenceId);
      final nextMessages = await _chatService.getMessagesAfterChoice(startMessageId);
      
      // Display the new sequence messages
      await _messageDisplayManager.displayMessages(nextMessages, _messageQueue, notifyListeners);
      
      notifyListeners();
    } catch (e) {
      logger.error('Error switching sequence from choice: $e', component: LogComponent.ui);
    }
  }

  /// Continue conversation after text input
  Future<void> _continueWithTextInput(int nextMessageId, String userInput, VoidCallback notifyListeners) async {
    final nextMessages = await _chatService.getMessagesAfterTextInput(nextMessageId, userInput);
    await _messageDisplayManager.displayMessages(nextMessages, _messageQueue, notifyListeners);
  }

  /// Dispose of resources
  void dispose() {
    _disposed = true;
  }
}