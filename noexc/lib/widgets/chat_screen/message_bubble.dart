import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/ui_constants.dart';
import '../../constants/theme_constants.dart';
import 'choice_buttons.dart';
import 'text_input_bubble.dart';

/// A widget that displays different types of chat messages
/// Handles regular messages, choice messages, and text input messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(Choice, ChatMessage)? onChoiceSelected;
  final Function(String, ChatMessage)? onTextSubmitted;
  final bool isCurrentTextInput;

  const MessageBubble({
    super.key,
    required this.message,
    this.onChoiceSelected,
    this.onTextSubmitted,
    this.isCurrentTextInput = false,
  });

  @override
  Widget build(BuildContext context) {
    // Route to appropriate message type based on single responsibility
    if (message.isChoice && message.choices != null) {
      return ChoiceButtons(
        message: message,
        onChoiceSelected: onChoiceSelected,
      );
    }
    
    if (message.isTextInput && isCurrentTextInput) {
      return TextInputBubble(
        message: message,
        onSubmitted: onTextSubmitted,
      );
    }
    
    // Skip autoroute messages - they have no visual representation
    if (message.isAutoRoute) {
      return const SizedBox.shrink();
    }
    
    // Regular text messages only
    return _buildRegularBubble(context);
  }

  /// Builds a regular text message bubble (bot or user)
  Widget _buildRegularBubble(BuildContext context) {
    final isBot = message.isFromBot;
    
    return Padding(
      padding: UIConstants.messageBubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            _buildAvatar(context, isBot: true),
            const SizedBox(width: UIConstants.avatarSpacing),
          ],
          Flexible(
            child: _buildMessageContainer(context, isBot),
          ),
          if (!isBot) ...[
            const SizedBox(width: UIConstants.avatarSpacing),
            _buildAvatar(context, isBot: false),
          ],
        ],
      ),
    );
  }

  /// Builds the message container with text content
  Widget _buildMessageContainer(BuildContext context, bool isBot) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * UIConstants.messageMaxWidthFactor,
      ),
      padding: UIConstants.messageBubblePadding,
      decoration: BoxDecoration(
        color: isBot 
            ? ThemeConstants.botMessageBackgroundLight 
            : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(UIConstants.messageBubbleRadius),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: UIConstants.messageFontSize,
          color: isBot 
              ? ThemeConstants.botMessageTextColor 
              : ThemeConstants.userMessageTextColor,
        ),
      ),
    );
  }

  /// Builds the avatar for bot or user messages
  Widget _buildAvatar(BuildContext context, {required bool isBot}) {
    return CircleAvatar(
      backgroundColor: isBot 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isBot ? Icons.smart_toy : Icons.person,
        color: ThemeConstants.avatarIconColor,
      ),
    );
  }
}