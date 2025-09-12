import 'package:flutter/widgets.dart';
import 'session_service.dart';
import 'logger_service.dart';

/// Manages app lifecycle events and triggers re-engagement when returning from end states
class AppLifecycleManager {
  final SessionService sessionService;
  final Future<void> Function() onAppResumedFromEndState;
  final LoggerService _logger = LoggerService.instance;
  
  bool _wasInBackground = false;

  AppLifecycleManager({
    required this.sessionService,
    required this.onAppResumedFromEndState,
  });

  /// Handle app lifecycle state changes
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    _logger.info('App lifecycle state: $state', component: LogComponent.ui);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _logger.debug('App moved to background ($state)', component: LogComponent.ui);
        _wasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        _logger.debug('App resumed. wasInBackground=$_wasInBackground', component: LogComponent.ui);
        if (_wasInBackground) {
          await _handleAppResumed();
          _wasInBackground = false;
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
    
    _logger.semantic('resume_detected isAtEndState=$isAtEndState');
    
    if (isAtEndState) {
      _logger.info('At end state on resume → trigger re-engage', component: LogComponent.ui);
      // Let the script clear the flag via dataAction; do not clear here.
      // Trigger the re-engagement callback
      await onAppResumedFromEndState();
      _logger.info('Re-engagement callback completed', component: LogComponent.ui);
    } else {
      _logger.debug('Not at end state on resume → no action', component: LogComponent.ui);
    }
  }
}
