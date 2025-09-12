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
    VoidCallback notifyListeners,
  ) async {
    // Persist and continue flow via facade
    await _chatService.handleUserChoice(choiceMessage, choice);

    // Update choice message to mark the selected choice and disable interaction
    _messageDisplayManager.updateChoiceMessage(choiceMessage, choice.text);
    notifyListeners();

    try {
      // If choice targets a new sequence, engine will notify via sequence-changed callback
      if (choice.sequenceId != null && choice.sequenceId!.isNotEmpty) {
        _messageDisplayManager.currentTextInputMessage = null;
      }

      final flow = await _chatService.applyChoiceAndContinue(
        choiceMessage,
        choice,
      );

      // Display returned messages
      await _messageDisplayManager.displayMessages(
        flow.messages,
        _messageQueue,
        notifyListeners,
      );
    } catch (e) {
      logger.error(
        'Error continuing after choice: $e',
        component: LogComponent.ui,
      );
    }
  }

  /// Handle user text input submission
  Future<void> handleTextInputSubmission(
    String userInput,
    ChatMessage textInputMessage,
    VoidCallback notifyListeners,
  ) async {
    if (userInput.trim().isEmpty) return;

    // Persist input and echo user message
    await _chatService.handleUserTextInput(textInputMessage, userInput.trim());

    final userResponseMessage = _chatService.createUserResponseMessage(
      textInputMessage.id + AppConstants.userResponseIdOffset,
      userInput.trim(),
    );

    _messageDisplayManager.addUserResponseMessage(userResponseMessage);
    _messageDisplayManager.currentTextInputMessage = null;
    notifyListeners();

    try {
      final flow = await _chatService.applyTextAndContinue(
        textInputMessage,
        userInput.trim(),
      );
      await _messageDisplayManager.displayMessages(
        flow.messages,
        _messageQueue,
        notifyListeners,
      );
    } catch (e) {
      logger.error(
        'Error continuing after text input: $e',
        component: LogComponent.ui,
      );
    }
  }

  // Old continuation helpers removed in favor of ChatService facades

  /// Dispose of resources
  void dispose() {}
}
