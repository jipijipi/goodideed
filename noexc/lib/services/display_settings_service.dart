import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Global runtime settings that influence chat display behavior.
class DisplaySettingsService extends ChangeNotifier {
  final _logger = LoggerService.instance;

  /// When true, bot messages display instantly (no delays).
  // Default: true in debug for faster TDD, false in release
  bool _instantDisplay = kDebugMode;

  bool get instantDisplay => _instantDisplay;

  set instantDisplay(bool value) {
    if (_instantDisplay == value) return;
    _instantDisplay = value;
    _logger.info('DisplaySettings: instantDisplay=${value ? 'ON' : 'OFF'}');
    notifyListeners();
  }
}
