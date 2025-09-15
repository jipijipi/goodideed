import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import 'display_settings_service.dart';

enum DelayMode { adaptive, instant }

/// Encapsulates how message delays are computed.
///
/// In adaptive mode, the delay before showing the next message is primarily
/// driven by the reading time of the previous message.
class MessageDelayPolicy {
  final DelayMode _mode;
  final DisplaySettingsService? _settings;

  MessageDelayPolicy({DelayMode? mode, DisplaySettingsService? settings})
      : _mode = mode ?? DelayMode.adaptive,
        _settings = settings;

  /// Compute the delay (ms) before displaying [next], based on [previous].
  int delayBefore(ChatMessage? previous, ChatMessage next) {
    // Instant mode via explicit mode parameter or global settings
    if (_mode == DelayMode.instant || _settings?.instantDisplay == true) {
      return 0;
    }

    // No delay before user-authored messages
    if (next.type == MessageType.user) return 0;

    // Explicit delay on the next message takes precedence
    if (next.hasExplicitDelay || next.delay != AppConstants.defaultMessageDelay) {
      return next.delay;
    }

    // Choice options: constant delay in production mode
    if (next.type == MessageType.choice) {
      return AppConstants.choiceDisplayDelayMs;
    }

    // Reading-based delay derived from previous message's content
    final words = _wordCount(previous?.text ?? '');
    final raw = AppConstants.dynamicDelayBaseMs +
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
