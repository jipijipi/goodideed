import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/app_lifecycle_manager.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import '../test_helpers.dart';

void main() {
  group('AppLifecycleManager', () {
    late AppLifecycleManager lifecycleManager;
    late SessionService sessionService;
    late UserDataService userDataService;
    late List<String> callbackLog;

    setUp(() async {
      setupQuietTesting();
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
      callbackLog = [];
      
      lifecycleManager = AppLifecycleManager(
        sessionService: sessionService,
        onAppResumedFromEndState: () async {
          callbackLog.add('onAppResumedFromEndState');
        },
      );
    });

    group('lifecycle state changes', () {
      test('should not trigger callback when app goes to background', () async {
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        expect(callbackLog, isEmpty);
      });

      test('should not trigger callback when resuming if not at end state', () async {
        // Set up: app goes to background and comes back, but not at end state
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(callbackLog, isEmpty);
      });

      test('should trigger callback when resuming from background while at end state', () async {
        // Set up: mark as at end state
        await sessionService.setEndState(true);
        
        // App goes to background
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // App comes back to foreground
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(callbackLog, contains('onAppResumedFromEndState'));
      });

      test('should clear end state flag when callback is triggered', () async {
        // Set up: mark as at end state
        await sessionService.setEndState(true);
        expect(await sessionService.isAtEndState(), true);
        
        // App goes to background and returns
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // End state should be cleared
        expect(await sessionService.isAtEndState(), false);
      });

      test('should handle inactive state as background state', () async {
        // Set up: mark as at end state
        await sessionService.setEndState(true);
        
        // App goes inactive then resumes
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.inactive);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(callbackLog, contains('onAppResumedFromEndState'));
      });

      test('should not trigger callback on multiple resume events without background', () async {
        // Set up: mark as at end state
        await sessionService.setEndState(true);
        
        // Multiple resume events without going to background first
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(callbackLog, isEmpty);
      });

      test('should handle detached state gracefully', () async {
        // Should not crash or trigger callbacks
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.detached);
        
        expect(callbackLog, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle rapid state changes correctly', () async {
        await sessionService.setEndState(true);
        
        // Rapid state changes
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.inactive);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Should only trigger once
        expect(callbackLog.length, 1);
      });

      test('should reset background flag after triggering callback', () async {
        await sessionService.setEndState(true);
        
        // First cycle
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Second resume without background should not trigger
        await lifecycleManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(callbackLog.length, 1);
      });
    });
  });
}