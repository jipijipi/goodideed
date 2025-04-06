import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/message_model.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
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
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
            color: Colors.black.withOpacity(0.05),
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
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) _buildAvatarIcon(),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            margin: EdgeInsets.only(
              left: isUser ? 48.0 : 8.0,
              right: isUser ? 8.0 : 48.0,
            ),
            decoration: BoxDecoration(
              color: isUser 
                ? Colors.white 
                : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Text(
              widget.message.content,
              style: isUser 
                ? AppTextStyles.userText() 
                : AppTextStyles.tristopherText(),
            ),
          ),
        ),
        if (isUser) _buildUserAvatar(),
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
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.black.withOpacity(0.2)),
          ),
          textStyle: AppTextStyles.userText(),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(option.text),
        ),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: widget.message.inputHint ?? 'Type your answer...',
                    hintStyle: AppTextStyles.userText().copyWith(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: AppColors.accentColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  style: AppTextStyles.userText(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.accentColor,
                onPressed: () {
                  if (_inputController.text.isNotEmpty) {
                    widget.message.onInputSubmit!(_inputController.text);
                    _inputController.clear();
                  }
                },
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
        border: Border.all(
          color: AppColors.accentColor,
          width: 2.0,
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1.0,
        ),
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

  Widget _buildAvatarIcon() {
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
  }
}
