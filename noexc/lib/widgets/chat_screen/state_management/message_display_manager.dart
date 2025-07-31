import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../../services/message_queue.dart';
import '../../../services/logger_service.dart';
import '../../../constants/design_tokens.dart';

/// Manages message display, filtering, queue processing, and animations
class MessageDisplayManager {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _displayedMessages = [];
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  
  /// Current text input message
  ChatMessage? currentTextInputMessage;
  bool _disposed = false;

  /// Get the scroll controller
  ScrollController get scrollController => _scrollController;
  
  /// Get the displayed messages
  List<ChatMessage> get displayedMessages => _displayedMessages;
  
  /// Get the animated list key
  GlobalKey<AnimatedListState> get animatedListKey => _animatedListKey;
  

  /// Load chat script and display initial messages
  Future<void> loadAndDisplayMessages(ChatService chatService, MessageQueue messageQueue, String currentSequenceId, VoidCallback notifyListeners) async {
    try {
      final initialMessages = await chatService.getInitialMessages(sequenceId: currentSequenceId);
      
      if (!_disposed) {
        await displayMessages(initialMessages, messageQueue, notifyListeners);
      }
    } catch (e) {
      // Handle error silently or add error handling as needed
      logger.error('Error loading chat script: $e', component: LogComponent.ui);
    }
  }

  /// Display a list of messages with delays and animations
  Future<void> displayMessages(List<ChatMessage> messages, MessageQueue messageQueue, VoidCallback notifyListeners) async {
    // Filter out empty messages only
    final filteredMessages = messages.where((message) {
      // Skip messages with empty text that are not interactive or image messages
      if (message.text.trim().isEmpty && !message.isChoice && !message.isTextInput && !message.isImage) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Enqueue messages for processing
    await messageQueue.enqueue(filteredMessages, (message) async {
      if (_disposed) return;
      
      // Add message to list
      _displayedMessages.add(message);
      
      // Only animate bot messages, skip animation for user messages
      final animatedListState = _animatedListKey.currentState;
      if (animatedListState != null && message.isFromBot) {
        // Insert at the correct index for reverse list
        // Since we add to end of _displayedMessages but display in reverse,
        // the new message appears at index 0 in the reversed view
        animatedListState.insertItem(0, duration: DesignTokens.messageSlideAnimationDuration);
      }
      
      notifyListeners();
      
      // Scroll to bottom after adding message
      _scrollToBottom();
      
      // Handle interactive messages
      if (message.isTextInput) {
        currentTextInputMessage = message;
        notifyListeners();
      }
    });
  }

  /// Scroll to the bottom of the message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: DesignTokens.scrollAnimationDuration,
          curve: DesignTokens.scrollAnimationCurve,
        );
      }
    });
  }

  /// Clear displayed messages
  void clearMessages() {
    if (_disposed) return;
    
    // Get the current number of messages before clearing
    final messageCount = _displayedMessages.length;
    
    // Remove all items from AnimatedList state first (in reverse order)
    final animatedListState = _animatedListKey.currentState;
    if (animatedListState != null && messageCount > 0) {
      // Remove items from index 0 to messageCount-1 (since we use reverse: true)
      for (int i = 0; i < messageCount; i++) {
        animatedListState.removeItem(
          0, // Always remove from index 0 since each removal shifts items down
          (context, animation) => const SizedBox.shrink(), // Empty widget during removal
          duration: Duration.zero, // Instant removal for reset/clear operations
        );
      }
    }
    
    // Clear messages but keep sequence loaded
    _displayedMessages.clear();
    currentTextInputMessage = null;
  }

  /// Add a user response message
  void addUserResponseMessage(ChatMessage message) {
    _displayedMessages.add(message);
    
    // Notify AnimatedList about the new user message, but without animation
    // This keeps the data structure and AnimatedList state in sync
    final animatedListState = _animatedListKey.currentState;
    if (animatedListState != null) {
      // Insert at index 0 since we're using reverse: true, but with no duration (instant)
      animatedListState.insertItem(0, duration: Duration.zero);
    }
    
    _scrollToBottom();
  }

  /// Update a choice message with selected choice
  void updateChoiceMessage(ChatMessage choiceMessage, String selectedChoiceText) {
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
        selectedChoiceText: selectedChoiceText, // Mark which choice was selected
      );
    }
  }

  /// Dispose of resources
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
  }
}