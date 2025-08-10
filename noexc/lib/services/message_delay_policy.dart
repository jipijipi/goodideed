import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import 'display_settings_service.dart';

enum DelayMode { adaptive, instant }

/// Encapsulates how message delays are computed.
class MessageDelayPolicy {
  final DelayMode _mode;
  final DisplaySettingsService? _settings;

  MessageDelayPolicy({DelayMode? mode, DisplaySettingsService? settings})
    : _mode = mode ?? DelayMode.adaptive,
      _settings = settings;

  /// Compute the effective delay for a message in milliseconds.
  int effectiveDelay(ChatMessage message) {
    // Instant mode via explicit mode parameter or global settings
    if (_mode == DelayMode.instant || _settings?.instantDisplay == true) {
      return 0;
    }

    // Choice options: constant delay in production mode
    if (message.type == MessageType.choice) {
      return AppConstants.choiceDisplayDelayMs;
    }

    // No delay for user-authored messages
    if (message.type == MessageType.user) return 0;

    // Explicit delay (from script or non-default constructor) takes precedence
    if (message.hasExplicitDelay ||
        message.delay != AppConstants.defaultMessageDelay) {
      return message.delay;
    }

    // Adaptive delay for bot text/image messages based on word count
    final words = _wordCount(message.text);
    final raw =
        AppConstants.dynamicDelayBaseMs +
        words * AppConstants.dynamicDelayPerWordMs;
    final clamped = raw.clamp(
      AppConstants.dynamicDelayMinMs,
      AppConstants.dynamicDelayMaxMs,
    );
    return clamped;
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r"\s+")).where((w) => w.isNotEmpty).length;
  }
}
