import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/design_tokens.dart';
import '../../services/logger_service.dart';
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
    
    // Image messages - display image only with consistent spacing
    if (message.isImage && message.imagePath != null) {
      return Padding(
        padding: DesignTokens.messageBubbleMargin,
        child: Image.asset(
          message.imagePath!,
          errorBuilder: (context, error, stackTrace) {
            logger.error('Image not found: ${message.imagePath}', component: LogComponent.ui);
            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Image not found: ${message.imagePath}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          },
        ),
      );
    }
    
    // Regular text messages only
    return _buildRegularBubble(context);
  }

  /// Builds a regular text message bubble (bot or user)
  Widget _buildRegularBubble(BuildContext context) {
    // Don't display messages with empty text
    if (message.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isBot = message.isFromBot;
    
    return Padding(
      padding: DesignTokens.messageBubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            _buildAvatar(context, isBot: true),
            const SizedBox(width: DesignTokens.avatarSpacing),
          ],
          Flexible(
            child: _buildMessageContainer(context, isBot),
          ),
          if (!isBot) ...[
            const SizedBox(width: DesignTokens.avatarSpacing),
            _buildAvatar(context, isBot: false),
          ],
        ],
      ),
    );
  }

  /// Builds the message container with text content
  Widget _buildMessageContainer(BuildContext context, bool isBot) {
    final textColor = isBot 
        ? DesignTokens.botMessageTextColor 
        : DesignTokens.userMessageTextColor;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * DesignTokens.messageMaxWidthFactor,
      ),
      padding: DesignTokens.messageBubblePadding,
      decoration: BoxDecoration(
        color: isBot 
            ? DesignTokens.botMessageBackgroundLight.withValues(alpha: 0.8)
            : DesignTokens.userMessageBackground,
        borderRadius: BorderRadius.circular(DesignTokens.messageBubbleRadius),
      ),
      child: MarkdownBody(
        data: message.text,
        styleSheet: MarkdownStyleSheet(
          // Base text style
          p: TextStyle(
            fontSize: DesignTokens.messageFontSize,
            color: textColor,
            height: 1.4,
          ),
          // Bold text
          strong: TextStyle(
            fontSize: DesignTokens.messageFontSize,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          // Italic text
          em: TextStyle(
            fontSize: DesignTokens.messageFontSize,
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
          // Strikethrough text
          del: TextStyle(
            fontSize: DesignTokens.messageFontSize,
            color: textColor,
            decoration: TextDecoration.lineThrough,
          ),
          // Disable all other markdown elements
          h1: const TextStyle(fontSize: 0, height: 0),
          h2: const TextStyle(fontSize: 0, height: 0),
          h3: const TextStyle(fontSize: 0, height: 0),
          h4: const TextStyle(fontSize: 0, height: 0),
          h5: const TextStyle(fontSize: 0, height: 0),
          h6: const TextStyle(fontSize: 0, height: 0),
          blockquote: const TextStyle(fontSize: 0, height: 0),
          code: TextStyle(
            fontSize: DesignTokens.messageFontSize,
            color: textColor,
          ),
          codeblockDecoration: const BoxDecoration(),
        ),
        // Disable physics to prevent scrolling within message bubbles
        shrinkWrap: true,
        // Disable selection to maintain chat UX
        selectable: false,
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
        color: DesignTokens.avatarIconColor,
      ),
    );
  }
}