import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/ui_constants.dart';
import '../../constants/theme_constants.dart';
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
    logger.debug('MessageBubble - ID: ${message.id}, type: ${message.type}, isImage: ${message.isImage}, imagePath: ${message.imagePath}, text: "${message.text}"', component: LogComponent.ui);
    
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
      logger.debug('Rendering image message with path: ${message.imagePath}', component: LogComponent.ui);
      return Padding(
        padding: UIConstants.messageBubbleMargin,
        child: Image.asset(
          message.imagePath!,
          errorBuilder: (context, error, stackTrace) {
            logger.error('Image loading failed for path: ${message.imagePath} - $error', component: LogComponent.ui);
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
    logger.debug('Falling through to regular bubble for message ID: ${message.id}', component: LogComponent.ui);
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
    final textColor = isBot 
        ? ThemeConstants.botMessageTextColor 
        : ThemeConstants.userMessageTextColor;
    
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
      child: MarkdownBody(
        data: message.text,
        styleSheet: MarkdownStyleSheet(
          // Base text style
          p: TextStyle(
            fontSize: UIConstants.messageFontSize,
            color: textColor,
            height: 1.4,
          ),
          // Bold text
          strong: TextStyle(
            fontSize: UIConstants.messageFontSize,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          // Italic text
          em: TextStyle(
            fontSize: UIConstants.messageFontSize,
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
          // Strikethrough text
          del: TextStyle(
            fontSize: UIConstants.messageFontSize,
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
            fontSize: UIConstants.messageFontSize,
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
        color: ThemeConstants.avatarIconColor,
      ),
    );
  }
}