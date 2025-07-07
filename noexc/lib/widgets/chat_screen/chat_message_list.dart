import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/ui_constants.dart';
import 'message_bubble.dart';

/// A widget that displays a scrollable list of chat messages
/// Handles message ordering, scrolling, and message rendering
class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function(Choice, ChatMessage)? onChoiceSelected;
  final Function(String, ChatMessage)? onTextSubmitted;
  final ChatMessage? currentTextInputMessage;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    this.onChoiceSelected,
    this.onTextSubmitted,
    this.currentTextInputMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true, // Show newest messages at bottom
      controller: scrollController,
      padding: UIConstants.chatListPadding,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages.reversed.toList()[index];
        return _buildMessageItem(message);
      },
    );
  }

  /// Builds an individual message item
  Widget _buildMessageItem(ChatMessage message) {
    return MessageBubble(
      message: message,
      onChoiceSelected: onChoiceSelected,
      onTextSubmitted: onTextSubmitted,
      isCurrentTextInput: message == currentTextInputMessage,
    );
  }
}