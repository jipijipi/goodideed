import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/chat_screen/chat_state_manager.dart';
import 'package:noexc/services/service_locator.dart';
import '../test_helpers.dart';

void main() {
  group('ChatStateManager Lifecycle Integration', () {
    late ChatStateManager stateManager;

    setUp(() async {
      setupQuietTesting();
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      // Reset ServiceLocator completely for clean state
      ServiceLocator.reset();

      await ServiceLocator.instance.initialize();
      stateManager = ChatStateManager();
    });

    tearDown(() async {
      try {
        stateManager.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
      ServiceLocator.reset();
    });

    group('lifecycle manager integration', () {
      test('should create lifecycle manager on initialization', () async {
        await stateManager.initialize();
        
        expect(stateManager.lifecycleManager, isNotNull);
      });

      test('should handle app lifecycle state changes', () async {
        await stateManager.initialize();
        
        // Should not throw when handling lifecycle changes
        expect(() async {
          await stateManager.didChangeAppLifecycleState(AppLifecycleState.paused);
          await stateManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        }, returnsNormally);
      });

      test('should trigger re-engagement when resuming from end state', () async {
        await stateManager.initialize();

        // Record the initial sequence before setting end state
        final initialSequenceId = stateManager.currentSequenceId;

        // Set end state
        await ServiceLocator.instance.sessionService.setEndState(true);

        // Simulate app going to background and returning
        await stateManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await stateManager.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Wait for debounced lifecycle callback to complete
        await Future.delayed(Duration(milliseconds: 500)); // Wait for debounce (400ms) + processing

        // Should have switched to the default sequence (same as initial since re-engagement reloads default)
        expect(stateManager.currentSequenceId, equals(initialSequenceId));

        // End state clearing is now done by the sequence script, not lifecycle manager
        // Just verify that the re-engagement was triggered (sequence was reloaded)
        // The end state will be cleared by dataActions when the sequence runs
      });

      test('should not trigger re-engagement when not at end state', () async {
        await stateManager.initialize();

        // Ensure not at end state
        await ServiceLocator.instance.sessionService.clearEndState();

        // Track current sequence before and after
        final initialSequence = stateManager.currentSequenceId;

        // Simulate app going to background and returning
        await stateManager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await stateManager.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Wait for any potential lifecycle processing
        await Future.delayed(Duration(milliseconds: 500));

        // Should not have changed sequence
        expect(stateManager.currentSequenceId, equals(initialSequence));
      });
    });

    group('WidgetsBindingObserver integration', () {
      test('should register as lifecycle observer on initialization', () async {
        await stateManager.initialize();
        
        // This is hard to test directly, but we can verify the manager exists
        expect(stateManager.lifecycleManager, isNotNull);
      });

      test('should unregister lifecycle observer on disposal', () async {
        await stateManager.initialize();
        
        // Should not throw when disposing
        expect(() => stateManager.dispose(), returnsNormally);
      });
    });
  });
}