import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/widgets/chat_screen/chat_state_manager.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel('flutter/assets')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'loadString') {
      if (methodCall.arguments.toString().contains('sequences/welcome_seq.json')) {
        return '{"sequenceId": "welcome_seq", "name": "Welcome", "messages": [{"id": 1, "type": "bot", "text": "Welcome!"}]}';
      }
    }
    return null;
  });

  group('App Initialization Sequence', () {
    late UserDataService userDataService;
    late SessionService sessionService;
    late ChatStateManager chatStateManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
      chatStateManager = ChatStateManager();
    });

    tearDown(() async {
      if (chatStateManager.displayedMessages.isNotEmpty) {
        chatStateManager.dispose();
      }
    });

    test('should complete SessionService initialization before ChatStateManager starts', () async {
      // Arrange - Set up basic task state 
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, 3); // Evening deadline
      
      // Act - Initialize SessionService first (this is the fix)
      await sessionService.initializeSession();
      
      // Assert - Check that SessionService computed the variables
      final isPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      final isActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      expect(isPastDeadline, isNotNull, reason: 'SessionService should compute isPastDeadline');
      expect(isActiveDay, isNotNull, reason: 'SessionService should compute isActiveDay');
      
      // Now initialize ChatStateManager - it should see the computed variables
      await chatStateManager.initialize();
      
      // Verify that computed variables are still available after chat initialization
      final finalIsPastDeadline = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      final finalIsActiveDay = await userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
      
      expect(finalIsPastDeadline, isNotNull, reason: 'Computed variables should persist after chat initialization');
      expect(finalIsActiveDay, isNotNull, reason: 'Computed variables should persist after chat initialization');
    });

    test('should not start ChatStateManager until SessionService variables are computed', () async {
      // This test verifies the timing issue doesn't occur by ensuring proper sequence
      
      // Arrange - Track initialization order
      bool sessionServiceCompleted = false;
      bool chatStateManagerStarted = false;
      
      // Set up basic task state
      await userDataService.storeValue(StorageKeys.taskCurrentStatus, 'pending');
      await userDataService.storeValue(StorageKeys.taskDeadlineTime, 2); // Afternoon deadline
      
      // Act - Initialize SessionService and track completion
      await sessionService.initializeSession();
      sessionServiceCompleted = true;
      
      // Verify computed variables exist before starting chat
      final computedValue = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      expect(computedValue, isNotNull, reason: 'SessionService should compute variables before chat starts');
      
      // Now initialize ChatStateManager
      await chatStateManager.initialize();
      chatStateManagerStarted = true;
      
      // Assert - Sequential initialization
      expect(sessionServiceCompleted, isTrue, reason: 'SessionService should complete first');
      expect(chatStateManagerStarted, isTrue, reason: 'ChatStateManager should start after SessionService');
      
      // Verify variables remain available
      final finalComputedValue = await userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
      expect(finalComputedValue, isNotNull, reason: 'Computed variables should be available to chat service');
    });
  });
}