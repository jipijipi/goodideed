import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/ui_constants.dart';
import '../../constants/design_tokens.dart';
import 'message_bubble.dart';

/// A widget that displays a scrollable list of chat messages with slide-in animations
/// Handles message ordering, scrolling, message rendering, and animations
class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function(Choice, ChatMessage)? onChoiceSelected;
  final Function(String, ChatMessage)? onTextSubmitted;
  final ChatMessage? currentTextInputMessage;
  final GlobalKey<AnimatedListState>? animatedListKey;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    this.onChoiceSelected,
    this.onTextSubmitted,
    this.currentTextInputMessage,
    this.animatedListKey,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  @override
  Widget build(BuildContext context) {
    // Use AnimatedList if key is provided, otherwise fallback to ListView
    if (widget.animatedListKey != null) {
      return AnimatedList(
        key: widget.animatedListKey,
        reverse: true, // Show newest messages at bottom
        controller: widget.scrollController,
        padding: UIConstants.chatListPadding,
        initialItemCount: widget.messages.length,
        itemBuilder: (context, index, animation) {
          final message = widget.messages.reversed.toList()[index];
          return _buildAnimatedMessageItem(message, animation);
        },
      );
    } else {
      // Fallback to original ListView for compatibility
      return ListView.builder(
        reverse: true, // Show newest messages at bottom
        controller: widget.scrollController,
        padding: UIConstants.chatListPadding,
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages.reversed.toList()[index];
          return _buildMessageItem(message);
        },
      );
    }
  }

  /// Builds an animated message item that slides in from the bottom
  Widget _buildAnimatedMessageItem(ChatMessage message, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1), // Start below the screen
        end: Offset.zero, // End at normal position
      ).animate(CurvedAnimation(
        parent: animation,
        curve: DesignTokens.curveStandard,
      )),
      child: FadeTransition(
        opacity: animation,
        child: _buildMessageItem(message),
      ),
    );
  }

  /// Builds an individual message item
  Widget _buildMessageItem(ChatMessage message) {
    return MessageBubble(
      message: message,
      onChoiceSelected: widget.onChoiceSelected,
      onTextSubmitted: widget.onTextSubmitted,
      isCurrentTextInput: message == widget.currentTextInputMessage,
    );
  }
}