import 'package:flutter/widgets.dart';
import 'session_service.dart';
import 'logger_service.dart';
import 'dart:async';

/// Manages app lifecycle events and triggers re-engagement when returning from end states
class AppLifecycleManager {
  final SessionService sessionService;
  final Future<void> Function() onAppResumedFromEndState;
  final LoggerService _logger = LoggerService.instance;
  
  bool _wasInBackground = false;
  Timer? _resumeDebounce;
  static const Duration _resumeDebounceDuration = Duration(milliseconds: 400);

  AppLifecycleManager({
    required this.sessionService,
    required this.onAppResumedFromEndState,
  });

  /// Handle app lifecycle state changes
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Keep lifecycle noise minimal; only log resume at info level
    if (state == AppLifecycleState.resumed) {
      _logger.info('lifecycle_resumed', component: LogComponent.ui);
    } else {
      _logger.debug('lifecycle_state=$state', component: LogComponent.ui);
    }
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Background states logged at debug level only
        _logger.debug('background_state=$state', component: LogComponent.ui);
        _wasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        _logger.debug('resumed wasInBackground=$_wasInBackground', component: LogComponent.ui);
        if (_wasInBackground) {
          // Debounce resume handling to avoid flapping
          _resumeDebounce?.cancel();
          _resumeDebounce = Timer(_resumeDebounceDuration, () async {
            try {
              if (_wasInBackground) {
                await _handleAppResumed();
              }
            } finally {
              _wasInBackground = false;
            }
          });
        }
        break;
      case AppLifecycleState.detached:
        _logger.debug('App detached', component: LogComponent.ui);
        break;
    }
  }

  /// Handle app resuming from background
  Future<void> _handleAppResumed() async {
    final isAtEndState = await sessionService.isAtEndState();

    _logger.semantic('resume_detected end_state=$isAtEndState');

    if (isAtEndState) {
      _logger.info('reengage_start', component: LogComponent.ui);
      // Let the script clear the flag via dataAction; do not clear here.
      // Trigger the re-engagement callback
      await onAppResumedFromEndState();
      _logger.info('reengage_done', component: LogComponent.ui);
    } else {
      // No action needed if not at end-state
      _logger.debug('reengage_skip end_state=false', component: LogComponent.ui);
    }
  }

  /// Dispose and cancel any pending timers
  void dispose() {
    _resumeDebounce?.cancel();
    _resumeDebounce = null;
  }
}
