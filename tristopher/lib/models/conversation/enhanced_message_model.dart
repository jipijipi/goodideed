import 'package:flutter/material.dart';
import 'dart:convert';

/// EnhancedMessageModel extends the basic message functionality to support
/// the rich, interactive conversations that make Tristopher feel alive.
/// 
/// Think of this model as defining Tristopher's "vocabulary" - not just what
/// he can say, but HOW he can say it. Each property adds a dimension to
/// the conversation that affects the user's emotional experience.
/// 
/// The psychology behind this design:
/// - Visual effects create anticipation and emphasize personality
/// - Delays make conversations feel more natural and human-like
/// - Multiple message types prevent monotony and maintain engagement
/// - Branching allows personalized experiences based on user choices
class EnhancedMessageModel {
  final String id;
  final MessageType type;
  final String? content;
  final MessageSender sender;
  final DateTime timestamp;
  
  // Visual properties - these make Tristopher feel more "alive"
  final BubbleStyle? bubbleStyle;
  final AnimationType? animation;
  final int? delayMs; // Milliseconds to wait before showing
  final TextEffect? textEffect;
  
  // Interaction properties - these enable dynamic conversations
  final List<MessageOption>? options;
  final InputConfig? inputConfig;
  final Map<String, dynamic>? metadata;
  
  // Branching properties - these create personalized storylines
  final String? nextEventId;
  final Map<String, dynamic>? setVariables;
  
  // Localization - enables multi-language support
  final String? contentKey;
  final Map<String, dynamic>? templateVariables;

  EnhancedMessageModel({
    required this.id,
    required this.type,
    this.content,
    required this.sender,
    required this.timestamp,
    this.bubbleStyle,
    this.animation,
    this.delayMs,
    this.textEffect,
    this.options,
    this.inputConfig,
    this.metadata,
    this.nextEventId,
    this.setVariables,
    this.contentKey,
    this.templateVariables,
  });

  /// Create from JSON - used when loading from database or scripts
  factory EnhancedMessageModel.fromJson(Map<String, dynamic> json) {
    return EnhancedMessageModel(
      id: json['id'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      content: json['content'],
      sender: MessageSender.values.firstWhere(
        (e) => e.toString().split('.').last == json['sender'],
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      bubbleStyle: json['bubbleStyle'] != null
          ? BubbleStyle.values.firstWhere(
              (e) => e.toString().split('.').last == json['bubbleStyle'],
            )
          : null,
      animation: json['animation'] != null
          ? AnimationType.values.firstWhere(
              (e) => e.toString().split('.').last == json['animation'],
            )
          : null,
      delayMs: json['delayMs'],
      textEffect: json['textEffect'] != null
          ? TextEffect.values.firstWhere(
              (e) => e.toString().split('.').last == json['textEffect'],
            )
          : null,
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => MessageOption.fromJson(o))
              .toList()
          : null,
      inputConfig: json['inputConfig'] != null
          ? InputConfig.fromJson(json['inputConfig'])
          : null,
      metadata: json['metadata'],
      nextEventId: json['nextEventId'],
      setVariables: json['setVariables'],
      contentKey: json['contentKey'],
      templateVariables: json['templateVariables'],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bubbleStyle': bubbleStyle?.toString().split('.').last,
      'animation': animation?.toString().split('.').last,
      'delayMs': delayMs,
      'textEffect': textEffect?.toString().split('.').last,
      'options': options?.map((o) => o.toJson()).toList(),
      'inputConfig': inputConfig?.toJson(),
      'metadata': metadata,
      'nextEventId': nextEventId,
      'setVariables': setVariables,
      'contentKey': contentKey,
      'templateVariables': templateVariables,
    };
  }

  /// Factory constructors for common message patterns.
  /// These make it easy to create messages with appropriate defaults.
  
  /// Standard text message from Tristopher
  factory EnhancedMessageModel.tristopherText(
    String content, {
    BubbleStyle? style,
    int? delayMs,
  }) {
    return EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      content: content,
      sender: MessageSender.tristopher,
      timestamp: DateTime.now(),
      bubbleStyle: style ?? BubbleStyle.normal,
      animation: AnimationType.slideIn,
      delayMs: delayMs ?? 1500, // Default 1.5 second delay for natural feel
    );
  }

  /// Achievement message with special effects
  factory EnhancedMessageModel.achievement(
    String achievementText, {
    Map<String, dynamic>? achievementData,
  }) {
    return EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.achievement,
      content: achievementText,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
      bubbleStyle: BubbleStyle.glitch,
      animation: AnimationType.bounce,
      textEffect: TextEffect.rainbow,
      metadata: {
        'achievement': achievementData,
        'special_effect': 'confetti',
      },
    );
  }

  /// Message with options for user to choose
  factory EnhancedMessageModel.withOptions(
    String content,
    List<MessageOption> options, {
    String? nextEventId,
  }) {
    return EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.options,
      content: content,
      sender: MessageSender.tristopher,
      timestamp: DateTime.now(),
      options: options,
      animation: AnimationType.slideIn,
      nextEventId: nextEventId,
    );
  }
}

/// Extended message types that support richer interactions
enum MessageType {
  text,           // Standard text message
  options,        // Multiple choice question
  input,          // Free text input field
  sequence,       // Multiple messages shown in sequence
  conditional,    // Message shown based on conditions
  achievement,    // Special achievement notification
  streak,         // Streak milestone display
  animation,      // Pure animation/effect without text
  delay,          // Timed pause in conversation
  branch,         // Branching point in conversation
}

/// Message sender types
enum MessageSender {
  tristopher,  // The pessimistic robot
  user,        // The human user
  system,      // System notifications
}

/// Bubble styles affect how messages appear visually.
/// Each style reinforces Tristopher's personality and the message context.
enum BubbleStyle {
  normal,      // Standard appearance
  glitch,      // Digital glitching effect - emphasizes robot nature
  typewriter,  // Letters appear one by one - creates anticipation
  shake,       // Shaking animation - shows frustration or emphasis
  fade,        // Gentle fade in - for softer moments
  matrix,      // Digital rain effect - for dramatic moments
  error,       // Red error styling - for failures
}

/// Animation types for message entrance
enum AnimationType {
  none,        // No animation
  slideIn,     // Slide in from side
  fadeIn,      // Fade in gradually
  bounce,      // Bounce in playfully
  glitch,      // Glitch into existence
  typewriter,  // Typewriter effect
  drop,        // Drop from top
}

/// Text effects for emphasis
enum TextEffect {
  none,
  bold,
  italic,
  strikethrough,
  rainbow,      // Animated rainbow colors - for achievements
  pulsing,      // Pulsing glow - for important info
  shake,        // Shaking text - for emphasis
}

/// Configuration for input messages
class InputConfig {
  final String? hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? validationRegex;
  final String? errorMessage;
  
  InputConfig({
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validationRegex,
    this.errorMessage,
  });

  factory InputConfig.fromJson(Map<String, dynamic> json) {
    return InputConfig(
      hint: json['hint'],
      keyboardType: _parseKeyboardType(json['keyboardType']),
      maxLength: json['maxLength'],
      validationRegex: json['validationRegex'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hint': hint,
      'keyboardType': keyboardType.toString(),
      'maxLength': maxLength,
      'validationRegex': validationRegex,
      'errorMessage': errorMessage,
    };
  }

  static TextInputType _parseKeyboardType(String? type) {
    switch (type) {
      case 'TextInputType.number':
        return TextInputType.number;
      case 'TextInputType.emailAddress':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }
}

/// Enhanced message option with more capabilities
class MessageOption {
  final String id;
  final String text;
  final Function? onTap;
  final String? nextEventId;
  final Map<String, dynamic>? setVariables;
  final bool enabled;
  final String? disabledReason;
  
  MessageOption({
    required this.id,
    required this.text,
    this.onTap,
    this.nextEventId,
    this.setVariables,
    this.enabled = true,
    this.disabledReason,
  });

  factory MessageOption.fromJson(Map<String, dynamic> json) {
    return MessageOption(
      id: json['id'],
      text: json['text'],
      nextEventId: json['nextEventId'],
      setVariables: json['setVariables'],
      enabled: json['enabled'] ?? true,
      disabledReason: json['disabledReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'nextEventId': nextEventId,
      'setVariables': setVariables,
      'enabled': enabled,
      'disabledReason': disabledReason,
    };
  }
}
