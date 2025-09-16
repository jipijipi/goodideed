import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rive/rive.dart';
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
    if (message.type == MessageType.choice && message.choices != null) {
      return ChoiceButtons(
        message: message,
        onChoiceSelected: onChoiceSelected,
      );
    }

    if (message.type == MessageType.textInput && isCurrentTextInput) {
      return TextInputBubble(message: message, onSubmitted: onTextSubmitted);
    }

    // Skip autoroute messages - they have no visual representation
    if (message.type == MessageType.autoroute) {
      return const SizedBox.shrink();
    }

    // Image messages - display image or Rive animation with consistent spacing
    if (message.type == MessageType.image && message.imagePath != null) {
      return Padding(
        padding: DesignTokens.messageBubbleMargin,
        child: _buildImageOrAnimation(context, message.imagePath!),
      );
    }

    // System messages - centered, no bubble, monospace font
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    // Regular text messages only
    return _buildRegularBubble(context);
  }

  /// Builds a regular text message bubble (bot or user)
  Widget _buildRegularBubble(BuildContext context) {
    final isBot = message.isFromBot;

    // Typing placeholder: render a lightweight three-dots indicator
    if (isBot && message.type == MessageType.bot && message.text == "\u200B") {
      return const _TypingIndicatorBubble(key: ValueKey('typing_indicator_bubble'));
    }

    // Don't display messages with empty text
    if (message.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: DesignTokens.messageBubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot && DesignTokens.showAvatars) ...[
            _buildAvatar(context, isBot: true),
            const SizedBox(width: DesignTokens.avatarSpacing),
          ],
          Flexible(child: _buildMessageContainer(context, isBot)),
          if (!isBot && DesignTokens.showAvatars) ...[
            const SizedBox(width: DesignTokens.avatarSpacing),
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
        maxWidth:
            MediaQuery.of(context).size.width *
            DesignTokens.messageMaxWidthFactor,
      ),
      padding: DesignTokens.messageBubblePadding,
      decoration: BoxDecoration(
        color:
            isBot
                ? DesignTokens.botMessageBackgroundLightWithAlpha
                : DesignTokens.userMessageBackground,
        borderRadius: BorderRadius.circular(DesignTokens.messageBubbleRadius),
      ),
      child: MarkdownBody(
        data: message.text,
        styleSheet: DesignTokens.getMessageMarkdownStyle(context, isBot: isBot),
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
      backgroundColor:
          isBot
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isBot ? Icons.smart_toy : Icons.person,
        color: DesignTokens.avatarIconColor,
      ),
    );
  }

  /// Builds a system message with full width, lighter background, faint border, and monospace font
  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: DesignTokens.messageBubbleMargin,
      child: Container(
        width: double.infinity, // Full width
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: DesignTokens.getSystemMessageBackground(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          border: Border.all(
            color: DesignTokens.getSystemMessageBorder(context),
            width: DesignTokens.borderThin,
          ),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: DesignTokens.getSystemMessageMarkdownStyle(context),
          shrinkWrap: true,
          selectable: false,
        ),
      ),
    );
  }

  /// Builds either a static image or Rive animation based on file extension
  Widget _buildImageOrAnimation(BuildContext context, String imagePath) {
    final isRiveAnimation = imagePath.toLowerCase().endsWith('.riv');

    if (isRiveAnimation) {
      return _buildRiveAnimation(context, imagePath);
    } else {
      return _buildStaticImage(context, imagePath);
    }
  }

  /// Builds a Rive animation widget with error handling
  Widget _buildRiveAnimation(BuildContext context, String animationPath) {
    return SizedBox(
      height: 200, // Fixed height for consistent chat bubble sizing
      child: _RiveAnimationWrapper(
        key: GlobalObjectKey(message),
        animationPath: animationPath,
        onError: (error) {
          logger.error(
            'Rive animation failed to load: $animationPath - $error',
            component: LogComponent.ui,
          );
        },
      ),
    );
  }

  /// Builds a static image widget with error handling
  Widget _buildStaticImage(BuildContext context, String imagePath) {
    return Image.asset(
      imagePath,
      errorBuilder: (context, error, stackTrace) {
        logger.error('Image not found: $imagePath', component: LogComponent.ui);
        return _buildErrorContainer(context, 'Image not found: $imagePath');
      },
    );
  }

  /// Builds error container for both images and animations
  Widget _buildErrorContainer(BuildContext context, String errorMessage) {
    return Container(
      padding: DesignTokens.statusMessagePadding,
      decoration: BoxDecoration(
        color: DesignTokens.getStatusErrorBackground(context),
        borderRadius: BorderRadius.circular(DesignTokens.statusMessageRadius),
        border: Border.all(
          color: DesignTokens.getStatusErrorBorder(context),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Text(
        errorMessage,
        style: TextStyle(color: DesignTokens.getStatusErrorText(context)),
      ),
    );
  }
}

/// A lightweight three-dots typing indicator styled like a bot bubble.
class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble({super.key});

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bgColor = DesignTokens.botMessageBackgroundLightWithAlpha;
    final radius = BorderRadius.circular(DesignTokens.messageBubbleRadius);

    return Padding(
      padding: DesignTokens.messageBubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (DesignTokens.showAvatars) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: DesignTokens.avatarSpacing),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    DesignTokens.messageMaxWidthFactor,
              ),
              padding: DesignTokens.messageBubblePadding,
              decoration: BoxDecoration(color: bgColor, borderRadius: radius),
              child: Semantics(
                label: 'Assistant is typing',
                liveRegion: true,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final v = (_controller.value + i * 0.2) % 1.0;
                        // Smooth wave for scale/opacity in [0,1]
                        final wave = 0.5 * (math.cos(2 * math.pi * v) + 1.0);
                        final scale = 0.7 + 0.3 * wave; // 0.7..1.0
                        final opacity = 0.4 + 0.6 * wave; // 0.4..1.0
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// End typing indicator helpers

/// Wrapper widget for Rive animations with error handling
class _RiveAnimationWrapper extends StatefulWidget {
  final String animationPath;
  final Function(String error)? onError;

  const _RiveAnimationWrapper({
    super.key,
    required this.animationPath,
    this.onError,
  });

  @override
  State<_RiveAnimationWrapper> createState() => _RiveAnimationWrapperState();
}

class _RiveAnimationWrapperState extends State<_RiveAnimationWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _hasError = false;
  File? _file;
  RiveWidgetController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      _file = await File.asset(widget.animationPath, riveFactory: Factory.rive);

      _controller = RiveWidgetController(_file!);

      setState(() {
        _isLoading = false;
      });

      logger.info(
        'Rive animation loaded: ${widget.animationPath}',
        component: LogComponent.ui,
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });

      logger.error(
        'Rive animation failed to load: ${widget.animationPath} - $e',
        component: LogComponent.ui,
      );
      widget.onError?.call(e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_hasError) {
      return Container(
        padding: DesignTokens.statusMessagePadding,
        decoration: BoxDecoration(
          color: DesignTokens.getStatusErrorBackground(context),
          borderRadius: BorderRadius.circular(DesignTokens.statusMessageRadius),
          border: Border.all(
            color: DesignTokens.getStatusErrorBorder(context),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Text(
          'Animation not found: ${widget.animationPath}',
          style: TextStyle(color: DesignTokens.getStatusErrorText(context)),
        ),
      );
    }

    if (_isLoading || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      child: RiveWidget(controller: _controller!, fit: Fit.contain),
    );
  }
}
