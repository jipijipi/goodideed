/// A widget that represents a chat bubble in a chat interface. The chat bubble
/// can display different types of messages such as text, options, input fields,
/// achievements, and streaks. It also includes animations for fade and slide
/// transitions when the widget is built.
///
/// The appearance and behavior of the chat bubble depend on the type of message
/// and the sender of the message.
///
/// This widget is stateful and uses an [AnimationController] to handle the
/// animations.
///
/// ### Parameters:
/// - [message]: The [MessageModel] object that contains the content and metadata
///   of the message to be displayed.
///
/// ### Message Types:
/// - [MessageType.text]: Displays a simple text message.
/// - [MessageType.options]: Displays a text message followed by a list of
///   selectable options.
/// - [MessageType.input]: Displays a text message followed by an input field
///   where the user can type a response.
/// - [MessageType.achievement]: Displays a styled message indicating an
///   achievement.
/// - [MessageType.streak]: Displays a styled message indicating a streak.
///
/// ### Animations:
/// - Fade transition: The chat bubble fades in when it appears.
/// - Slide transition: The chat bubble slides in from a slight offset.
///
/// ### Methods:
/// - [_buildMessageContent]: Determines the widget to display based on the
///   message type.
/// - [_buildTextMessage]: Builds a text message bubble.
/// - [_buildOptionsMessage]: Builds a message bubble with selectable options.
/// - [_buildOptionButton]: Builds a button for each option in an options message.
/// - [_buildInputMessage]: Builds a message bubble with an input field.
/// - [_buildAchievementMessage]: Builds a styled message for achievements.
/// - [_buildStreakMessage]: Builds a styled message for streaks.
/// - [_buildAvatarIcon]: Builds a default avatar icon for non-user messages.
/// - [_buildUserAvatar]: Builds a default avatar icon for user messages.
///
/// ### Lifecycle:
/// - [initState]: Initializes the animation controller and starts the animation.
/// - [dispose]: Disposes of the animation controller and input controller to
///   free up resources.
///
/// ### Example Usage:
/// ```dart
/// ChatBubble(
///   message: MessageModel(
///     sender: MessageSender.user,
///     type: MessageType.text,
///     content: "Hello, how are you?",
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/message_model.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Different styles based on message sender
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: _buildMessageContent(),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.options:
        return _buildOptionsMessage();
      case MessageType.input:
        return _buildInputMessage();
      case MessageType.achievement:
        return _buildAchievementMessage();
      case MessageType.streak:
        return _buildStreakMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    final isUser = widget.message.sender == MessageSender.user;
    final isSystem = widget.message.sender == MessageSender.system;

    if (isSystem) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            widget.message.content,
            style: AppTextStyles.userText(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              top: 16.0, // 14.0 + 2.0 = 16.0 for 2px extra top padding
              bottom: 14.0,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: isUser
            ? AppColors.accentColor.withAlpha(
                (0.15 * 255).toInt(),
              ) // Highlighter effect
            : Colors.transparent, // Transparent background for non-user
              borderRadius: BorderRadius.circular(0.0),
              border: isUser
            ? Border.all(
                color: AppColors.accentColor.withAlpha(
            (0.0 * 255).toInt(),
                ),
                width: 2.0,
              )
            : null, // No border for non-user messages
            ),
            child: Text(
              widget.message.content,
              style: isUser
            ? AppTextStyles.userText()
            : AppTextStyles.tristopherText(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextMessage(),
        const SizedBox(height: 8.0),
        ...widget.message.options!.map((option) => _buildOptionButton(option)),
      ],
    );
  }

  Widget _buildOptionButton(MessageOption option) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 32.0),
      child: ElevatedButton(
        onPressed: () => option.onTap(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withAlpha(
            (0.4 * 255).toInt(),
          ), // Highlighter effect
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              0.0,
            ), // Square corners like user bubbles
            side: BorderSide(
              color: Colors.yellow.withAlpha((0.0 * 255).toInt()),
              width: 2.0,
            ),
          ),
          textStyle: AppTextStyles.userText(),
        ),
        child: Align(alignment: Alignment.centerLeft, child: Text(option.text)),
      ),
    );
  }

  Widget _buildInputMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextMessage(),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, right: 8.0),
          child: Column(
            children: [
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: widget.message.inputHint ?? 'Type your answer...',
                  hintStyle: AppTextStyles.userText().copyWith(
                    color: Colors.black.withAlpha((0.5 * 255).toInt()),
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha((0.25 * 255).toInt()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0.0),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha((0.0 * 255).toInt()),
                      width: 0.0,

                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0.0),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha((0.0 * 255).toInt()),
                      width: 0.0,

                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0.0),
                    borderSide: BorderSide(
                      color: AppColors.accentColor.withAlpha(
                        (0.3 * 255).toInt(),
                      ),
                      width: 0.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                style: AppTextStyles.userText(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withAlpha(
                      (0.15 * 255).toInt(),
                    ),
                    border: Border.all(
                      color: AppColors.accentColor.withAlpha(
                        (0.15 * 255).toInt(),
                      ),
                      width: 0.0,
                    ),
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.accentColor.withAlpha(
                      (0.95 * 255).toInt(),
                    ),
                    onPressed: () {
                      if (_inputController.text.isNotEmpty) {
                        widget.message.onInputSubmit!(_inputController.text);
                        _inputController.clear();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        border: Border.all(color: AppColors.accentColor, width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: AppColors.accentColor,
            size: 32.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            'ACHIEVEMENT UNLOCKED',
            style: AppTextStyles.header(size: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.message.content,
            style: AppTextStyles.userText(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            'YOUR STREAK',
            style: AppTextStyles.header(size: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.message.content,
            style: AppTextStyles.userText(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* Widget _buildAvatarIcon() {
    return Container(
      width: 32.0,
      height: 32.0,
      margin: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(
          Icons.android_outlined,
          size: 20.0,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32.0,
      height: 32.0,
      margin: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(
          Icons.person_outline,
          size: 20.0,
          color: Colors.black54,
        ),
      ),
    );
  }*/
}
