import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/conversation/enhanced_message_model.dart';
import '../../constants/app_constants.dart';

/// EnhancedChatBubble brings messages to life with rich visual effects.
/// 
/// This widget is where the personality of Tristopher truly shines through.
/// Each visual effect serves a psychological purpose:
/// - Glitch effects emphasize his digital, robotic nature
/// - Shake effects show frustration or emphasis
/// - Typewriter effects create anticipation
/// - Rainbow effects celebrate achievements
/// 
/// The widget adapts its appearance based on the message properties,
/// creating a dynamic and engaging conversation experience.
class EnhancedChatBubble extends StatefulWidget {
  final EnhancedMessageModel message;
  final Function(MessageOption)? onOptionSelected;
  final Function(String)? onInputSubmitted;

  const EnhancedChatBubble({
    Key? key,
    required this.message,
    this.onOptionSelected,
    this.onInputSubmitted,
  }) : super(key: key);

  @override
  State<EnhancedChatBubble> createState() => _EnhancedChatBubbleState();
}

class _EnhancedChatBubbleState extends State<EnhancedChatBubble>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _entranceController;
  late AnimationController _effectController;
  late AnimationController _glitchController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _entranceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  // State
  String _displayedText = '';
  Timer? _typewriterTimer;
  bool _isTyping = false;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntrance();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _effectController.dispose();
    _glitchController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _typewriterTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  /// Initialize all animation controllers and animations.
  void _initializeAnimations() {
    // Entrance animation controller
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Effect animation controller (for continuous effects)
    _effectController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Glitch effect controller
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Shake effect controller
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Pulse effect controller
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    // Setup entrance animations based on type
    _setupEntranceAnimations();
  }

  /// Setup entrance animations based on the message's animation type.
  void _setupEntranceAnimations() {
    switch (widget.message.animation) {
      case AnimationType.fadeIn:
        _fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeIn,
        ));
        break;
        
      case AnimationType.slideIn:
        _slideAnimation = Tween<Offset>(
          begin: widget.message.sender == MessageSender.user
              ? const Offset(1.0, 0.0)
              : const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOutCubic,
        ));
        break;
        
      case AnimationType.bounce:
        _bounceAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _entranceController,
          curve: Curves.elasticOut,
        ));
        break;
        
      case AnimationType.drop:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entranceController,
          curve: Curves.bounceOut,
        ));
        break;
        
      default:
        _fadeAnimation = AlwaysStoppedAnimation(1.0);
    }
  }

  /// Start the entrance animation after any specified delay.
  void _startEntrance() async {
    if (widget.message.delayMs != null && widget.message.delayMs! > 0) {
      await Future.delayed(Duration(milliseconds: widget.message.delayMs!));
    }
    
    if (mounted) {
      _entranceController.forward();
      
      // Start special effects
      if (widget.message.bubbleStyle == BubbleStyle.typewriter) {
        _startTypewriterEffect();
      } else if (widget.message.bubbleStyle == BubbleStyle.glitch) {
        _startGlitchEffect();
      } else if (widget.message.bubbleStyle == BubbleStyle.shake) {
        _shakeController.forward();
      }
      
      // Initialize displayed text
      if (widget.message.bubbleStyle != BubbleStyle.typewriter) {
        setState(() {
          _displayedText = widget.message.content ?? '';
        });
      }
    }
  }

  /// Start typewriter effect for gradual text reveal.
  void _startTypewriterEffect() {
    if (widget.message.content == null) return;
    
    _isTyping = true;
    final fullText = widget.message.content!;
    int currentIndex = 0;
    
    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (currentIndex < fullText.length) {
          setState(() {
            _displayedText = fullText.substring(0, currentIndex + 1);
          });
          currentIndex++;
        } else {
          timer.cancel();
          _isTyping = false;
        }
      },
    );
  }

  /// Start glitch effect for digital distortion.
  void _startGlitchEffect() {
    _glitchController.repeat();
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _glitchController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: _buildAnimatedMessage(),
    );
  }

  /// Build the animated message with all effects applied.
  Widget _buildAnimatedMessage() {
    Widget messageWidget = _buildMessageContent();
    
    // Apply entrance animation
    switch (widget.message.animation) {
      case AnimationType.fadeIn:
        messageWidget = FadeTransition(
          opacity: _fadeAnimation,
          child: messageWidget,
        );
        break;
        
      case AnimationType.slideIn:
      case AnimationType.drop:
        messageWidget = SlideTransition(
          position: _slideAnimation,
          child: messageWidget,
        );
        break;
        
      case AnimationType.bounce:
        messageWidget = ScaleTransition(
          scale: _bounceAnimation,
          child: messageWidget,
        );
        break;
        
      case AnimationType.glitch:
        messageWidget = _buildGlitchEffect(messageWidget);
        break;
        
      default:
        break;
    }
    
    // Apply continuous effects
    if (widget.message.bubbleStyle == BubbleStyle.shake ||
        widget.message.textEffect == TextEffect.shake) {
      messageWidget = _buildShakeEffect(messageWidget);
    }
    
    if (widget.message.textEffect == TextEffect.pulsing) {
      messageWidget = _buildPulseEffect(messageWidget);
    }
    
    return messageWidget;
  }

  /// Build the main message content based on message type.
  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
      case MessageType.delay:
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

  /// Build a standard text message bubble.
  Widget _buildTextMessage() {
    final isUser = widget.message.sender == MessageSender.user;
    final isSystem = widget.message.sender == MessageSender.system;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: _getBubbleDecoration(isUser, isSystem),
        child: _buildTextContent(),
      ),
    );
  }

  /// Build the text content with effects applied.
  Widget _buildTextContent() {
    Widget textWidget = Text(
      _displayedText,
      style: _getTextStyle(),
    );
    
    // Apply text effects
    if (widget.message.textEffect == TextEffect.rainbow) {
      textWidget = _buildRainbowText(_displayedText);
    }
    
    // Add typing indicator if still typing
    if (_isTyping) {
      textWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          const SizedBox(width: 2),
          _buildTypingIndicator(),
        ],
      );
    }
    
    return textWidget;
  }

  /// Build message with options (multiple choice).
  Widget _buildOptionsMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.content != null) _buildTextMessage(),
        const SizedBox(height: 8),
        ...widget.message.options!.map((option) => _buildOptionButton(option)),
      ],
    );
  }

  /// Build a single option button.
  Widget _buildOptionButton(MessageOption option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: option.enabled
              ? () => widget.onOptionSelected?.call(option)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor.withAlpha((0.15 * 255).toInt()),
            //foregroundColor: AppColors.primaryText,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          child: Text(
            option.text,
            style: AppTextStyles.userText(alpha: 1,italic: false),
          ),
        ),
      ),
    );
  }

  /// Build input message with text field.
  Widget _buildInputMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.content != null) _buildTextMessage(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _inputController,
            keyboardType: widget.message.inputConfig?.keyboardType,
            maxLength: widget.message.inputConfig?.maxLength,
            decoration: InputDecoration(
              filled: false,
              hintText: widget.message.inputConfig?.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  if (_inputController.text.isNotEmpty) {
                    widget.onInputSubmitted?.call(_inputController.text);
                    _inputController.clear();
                  }
                },
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onInputSubmitted?.call(value);
                _inputController.clear();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Build achievement message with special effects.
  Widget _buildAchievementMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            widget.message.content ?? 'Achievement Unlocked!',
            style: AppTextStyles.header(size: 18).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build streak message with visual flair.
  Widget _buildStreakMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.accentColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            widget.message.content ?? '',
            style: AppTextStyles.body().copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get bubble decoration based on sender and style.
  BoxDecoration _getBubbleDecoration(bool isUser, bool isSystem) {
    if (isSystem) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      );
    }
    
    Color backgroundColor;
    if (widget.message.bubbleStyle == BubbleStyle.error) {
      backgroundColor = Colors.red.shade100;
    } else if (isUser) {
      backgroundColor = AppColors.accentColor.withAlpha(
                (0.15 * 255).toInt());
    } else {
      backgroundColor = const Color.fromARGB(0, 255, 255, 255);
    }
    
    return BoxDecoration(
      color: backgroundColor,
      /* borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isUser ? 16 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 16),
      ), */
      border: widget.message.bubbleStyle == BubbleStyle.glitch
          ? Border.all(color: AppColors.accentColor, width: 1)
          : null,
      /* boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ], */
    );
  }

  /// Get text style based on message properties.
  TextStyle _getTextStyle() {
    TextStyle baseStyle = AppTextStyles.body();
    
    // Apply sender-specific styles
    if (widget.message.sender == MessageSender.user) {
      baseStyle = AppTextStyles.userText();
    } else if (widget.message.sender == MessageSender.system) {
      baseStyle = AppTextStyles.tristopherText();
    } else if (widget.message.sender == MessageSender.tristopher) {
      baseStyle = AppTextStyles.tristopherText();
    }
    
    // Apply text effects
    switch (widget.message.textEffect) {
      case TextEffect.bold:
        baseStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
        break;
      case TextEffect.italic:
        baseStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      case TextEffect.strikethrough:
        baseStyle = baseStyle.copyWith(decoration: TextDecoration.lineThrough);
        break;
      default:
        break;
    }
    
    // Apply bubble style modifications
    if (widget.message.bubbleStyle == BubbleStyle.error) {
      baseStyle = baseStyle.copyWith(color: Colors.red.shade700);
    }
    
    return baseStyle;
  }

  /// Build glitch effect animation.
  Widget _buildGlitchEffect(Widget child) {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, _) {
        final offset = math.sin(_glitchController.value * math.pi * 2) * 2;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              1, 0, 0, 0, offset * 10,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, -offset * 10,
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
        );
      },
    );
  }

  /// Build shake effect animation.
  Widget _buildShakeEffect(Widget child) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, _) {
        final offset = math.sin(_shakeController.value * math.pi * 10) * 3;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
    );
  }

  /// Build pulse effect animation.
  Widget _buildPulseEffect(Widget child) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  /// Build rainbow text effect.
  Widget _buildRainbowText(String text) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
        ],
        tileMode: TileMode.mirror,
        transform: GradientRotation(_effectController.value * 2 * math.pi),
      ).createShader(bounds),
      child: Text(
        text,
        style: _getTextStyle(),
      ),
    );
  }

  /// Build typing indicator for typewriter effect.
  Widget _buildTypingIndicator() {
    return Container(
      width: 2,
      height: 16,
      color: AppColors.primaryText,
      child: AnimatedOpacity(
        opacity: _isTyping ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(),
      ),
    );
  }
}
