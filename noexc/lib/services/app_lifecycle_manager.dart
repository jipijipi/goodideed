import 'package:flutter/widgets.dart';
import 'session_service.dart';

/// Manages app lifecycle events and triggers re-engagement when returning from end states
class AppLifecycleManager {
  final SessionService sessionService;
  final Future<void> Function() onAppResumedFromEndState;
  
  bool _wasInBackground = false;

  AppLifecycleManager({
    required this.sessionService,
    required this.onAppResumedFromEndState,
  });

  /// Handle app lifecycle state changes
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _wasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        if (_wasInBackground) {
          await _handleAppResumed();
          _wasInBackground = false;
        }
        break;
      case AppLifecycleState.detached:
        // Handle gracefully, no action needed
        break;
    }
  }

  /// Handle app resuming from background
  Future<void> _handleAppResumed() async {
    final isAtEndState = await sessionService.isAtEndState();
    
    if (isAtEndState) {
      // Clear the end state flag first
      await sessionService.clearEndState();
      
      // Trigger the re-engagement callback
      await onAppResumedFromEndState();
    }
  }
}