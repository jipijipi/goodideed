import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../constants/design_tokens.dart';

/// A widget that displays a text input field for user responses
/// Handles text input validation and submission
class TextInputBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String, ChatMessage)? onSubmitted;

  const TextInputBubble({
    super.key,
    required this.message,
    this.onSubmitted,
  });

  @override
  State<TextInputBubble> createState() => _TextInputBubbleState();
}

class _TextInputBubbleState extends State<TextInputBubble> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DesignTokens.messageBubbleMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: _buildInputContainer(context),
          ),
          if (DesignTokens.showAvatars) ...[
            const SizedBox(width: DesignTokens.avatarSpacing),
            _buildUserAvatar(context),
          ],
        ],
      ),
    );
  }

  /// Builds the text input container
  Widget _buildInputContainer(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * DesignTokens.messageMaxWidthFactor,
        ),
        padding: DesignTokens.messageBubblePadding,
        decoration: BoxDecoration(
          color: DesignTokens.getInputBackground(context),
          borderRadius: BorderRadius.circular(DesignTokens.messageBubbleRadius),
          border: Border.all(
            color: DesignTokens.getInputBorderColor(context),
            width: DesignTokens.inputBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.getInputShadowColor(context),
              offset: DesignTokens.inputShadowOffset,
              blurRadius: DesignTokens.inputShadowBlurRadius,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _buildTextField(),
            ),
            const SizedBox(width: DesignTokens.iconSpacing),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the text input field
  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      style: TextStyle(color: DesignTokens.getInputTextColor(context)),
      decoration: InputDecoration(
        hintText: widget.message.placeholderText,
        hintStyle: TextStyle(color: DesignTokens.getInputHintTextColor(context)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: _handleSubmission,
    );
  }

  /// Builds the send button
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () => _handleSubmission(_textController.text),
      child: const Icon(
        Icons.send,
        color: DesignTokens.userMessageTextColor,
        size: DesignTokens.sendIconSize,
      ),
    );
  }

  /// Builds the user avatar
  Widget _buildUserAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: DesignTokens.getInputAvatarBackground(context),
      child: const Icon(Icons.person, color: DesignTokens.avatarIconColor),
    );
  }

  /// Handles text input submission
  void _handleSubmission(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return;

    widget.onSubmitted?.call(trimmedValue, widget.message);
    _textController.clear();
  }
}