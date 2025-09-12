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
    print('🔄 AppLifecycleManager: State changed to $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        print('📱 AppLifecycleManager: App went to background (state: $state)');
        _wasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        print('📱 AppLifecycleManager: App resumed, wasInBackground: $_wasInBackground');
        if (_wasInBackground) {
          await _handleAppResumed();
          _wasInBackground = false;
        }
        break;
      case AppLifecycleState.detached:
        print('📱 AppLifecycleManager: App detached');
        break;
    }
  }

  /// Handle app resuming from background
  Future<void> _handleAppResumed() async {
    final isAtEndState = await sessionService.isAtEndState();
    
    print('🔍 AppLifecycleManager: Checking end state - isAtEndState: $isAtEndState');
    
    if (isAtEndState) {
      print('✅ AppLifecycleManager: At end state, triggering re-engagement');
      
      // Clear the end state flag first
      await sessionService.clearEndState();
      print('🧹 AppLifecycleManager: Cleared end state flag');
      
      // Trigger the re-engagement callback
      await onAppResumedFromEndState();
      print('🎯 AppLifecycleManager: Re-engagement callback completed');
    } else {
      print('❌ AppLifecycleManager: Not at end state, no action needed');
    }
  }
}