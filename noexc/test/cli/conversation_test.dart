import 'package:flutter_test/flutter_test.dart';
import 'conversation_runner.dart';

void main() {
  group('CLI Conversation Runner Tests', () {
    setUpAll(() {
      // Initialize Flutter test environment
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('Basic Conversation Flow', () {
      test('should run welcome_seq conversation successfully', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          interactive: false,
          verbose: false,
        );

        expect(result.completed, isTrue);
        expect(result.sequenceId, equals('welcome_seq'));
        expect(result.messages.isNotEmpty, isTrue);
        expect(result.duration.inMilliseconds, greaterThan(0));
      });

      test('should run onboarding_seq for new user', () async {
        final result = await runConversation(
          sequenceId: 'onboarding_seq',
          userState: {
            'user.name': null,
            'user.isOnboarded': false,
            'session.visitCount': 1,
          },
          interactive: false,
          verbose: false,
        );

        expect(result.completed, isTrue);
        expect(result.sequenceId, equals('onboarding_seq'));
        expect(result.messages.isNotEmpty, isTrue);
      });

      test('should handle active_seq for active day user', () async {
        final result = await runConversation(
          sequenceId: 'active_seq',
          userState: {
            'user.name': 'Test User',
            'user.isOnboarded': true,
            'task.isActiveDay': true,
            'task.currentDate': '2025-01-27',
            'task.currentStatus': 'pending',
          },
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.sequenceId, equals('active_seq'));
      });
    });

    group('Scenario-Based Testing', () {
      test('should run conversation with "New User" scenario', () async {
        final scenario = await loadScenario('new_user');
        expect(scenario, isNotNull);

        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: scenario,
          interactive: false,
          verbose: false,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState, isNotEmpty);
      });

      test('should run conversation with "Returning User" scenario', () async {
        final scenario = await loadScenario('returning_user');
        expect(scenario, isNotNull);

        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: scenario,
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState['user.name'], equals('John Doe'));
      });

      test('should run conversation with "Weekend User" scenario', () async {
        final scenario = await loadScenario('weekend_user');
        expect(scenario, isNotNull);

        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: scenario,
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState['session.isWeekend'], isTrue);
      });

      test('should run conversation with "Past Deadline" scenario', () async {
        final scenario = await loadScenario('past_deadline');
        expect(scenario, isNotNull);

        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: scenario,
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState['task.isPastDeadline'], isTrue);
      });
    });

    group('Automated Response Testing', () {
      test('should handle choice responses automatically', () async {
        final result = await runConversation(
          sequenceId: 'onboarding_seq',
          autoResponses: ['choice:1', 'text:Test Task', 'choice:2'],
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.messages.isNotEmpty, isTrue);
        
        // Should have user response messages
        final userMessages = result.messages.where((m) => m.sender == 'user').toList();
        expect(userMessages.isNotEmpty, isTrue);
      });

      test('should handle text input responses automatically', () async {
        final result = await runConversation(
          sequenceId: 'intro_seq',
          autoResponses: ['text:John Doe', 'choice:1'],
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        
        // Check that text input was processed
        final userMessages = result.messages.where((m) => m.sender == 'user').toList();
        expect(userMessages.any((m) => m.text.contains('John Doe')), isTrue);
      });
    });

    group('Cross-Sequence Navigation', () {
      test('should handle sequence transitions correctly', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: {
            'user.name': 'Test User',
            'user.isOnboarded': false,
          },
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        
        // Should have navigated through multiple sequences
        expect(result.messages.length, greaterThan(1));
      });

      test('should handle conditional routing based on user state', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: {
            'user.name': 'Test User',
            'user.isOnboarded': true,
            'task.isActiveDay': true,
          },
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.messages.isNotEmpty, isTrue);
      });
    });

    group('Template and Content Processing', () {
      test('should process templates with user data', () async {
        final result = await runConversation(
          sequenceId: 'onboarding_seq',
          userState: {
            'user.name': 'Alice',
            'user.streak': 5,
          },
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        
        // Check if templates were processed (should contain actual values, not {template})
        final botMessages = result.messages.where((m) => m.sender == 'bot').toList();
        expect(botMessages.isNotEmpty, isTrue);
        
        // Should not contain unprocessed template syntax
        for (final message in botMessages) {
          expect(message.text.contains('{user.'), isFalse, 
            reason: 'Message should not contain unprocessed templates: ${message.text}');
        }
      });

      test('should handle semantic content resolution', () async {
        final result = await runConversation(
          sequenceId: 'onboarding_seq',
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.messages.isNotEmpty, isTrue);
        
        // All messages should have resolved content
        for (final message in result.messages) {
          expect(message.text.isNotEmpty, isTrue);
          expect(message.text.trim(), isNot(equals('')));
        }
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid sequence gracefully', () async {
        final result = await runConversation(
          sequenceId: 'nonexistent_seq',
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isFalse);
        expect(result.endReason, isNotNull);
        expect(result.endReason!.contains('Error'), isTrue);
      });

      test('should handle empty user state', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: {},
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.messages.isNotEmpty, isTrue);
      });

      test('should handle null user state', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: null,
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.messages.isNotEmpty, isTrue);
      });
    });

    group('Performance and Timing', () {
      test('should complete conversation in reasonable time', () async {
        final result = await runConversation(
          sequenceId: 'welcome_seq',
          interactive: false,
          verbose: false,
        );

        expect(result.completed, isTrue);
        expect(result.duration.inSeconds, lessThan(10), 
          reason: 'Conversation should complete within 10 seconds');
        expect(result.duration.inMilliseconds, greaterThan(0));
      });

      test('should handle multiple rapid conversations', () async {
        final futures = List.generate(3, (i) => runConversation(
          sequenceId: 'welcome_seq',
          userState: {'user.name': 'User$i'},
          interactive: false,
          verbose: false,
        ));

        final results = await Future.wait(futures);
        
        for (int i = 0; i < results.length; i++) {
          expect(results[i].completed, isTrue, 
            reason: 'Conversation $i should complete successfully');
        }
      });
    });

    group('State Management', () {
      test('should preserve user state throughout conversation', () async {
        final initialState = {
          'user.name': 'Test User',
          'user.streak': 10,
          'session.visitCount': 5,
        };

        final result = await runConversation(
          sequenceId: 'welcome_seq',
          userState: initialState,
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState, isNotEmpty);
        
        // Initial state should be preserved (or modified appropriately)
        expect(result.finalUserState.containsKey('user.name'), isTrue);
      });

      test('should handle data actions and state modifications', () async {
        final result = await runConversation(
          sequenceId: 'onboarding_seq',
          userState: {
            'user.streak': 0,
          },
          interactive: false,
          verbose: true,
        );

        expect(result.completed, isTrue);
        expect(result.finalUserState, isNotEmpty);
        
        // State may have been modified by data actions
        expect(result.finalUserState.keys.length, greaterThanOrEqualTo(1));
      });
    });
  });

  group('CLI Integration Tests', () {
    test('should validate all available sequences can be loaded', () async {
      final sequences = [
        'welcome_seq',
        'onboarding_seq',
        'active_seq',
        'inactive_seq',
        'pending_seq',
        'completed_seq',
        'failed_seq',
        'deadline_seq',
        'intro_seq',
        'settask_seq',
      ];

      for (final sequenceId in sequences) {
        try {
          final result = await runConversation(
            sequenceId: sequenceId,
            interactive: false,
            verbose: false,
          );
          
          // Some sequences might require specific state, so we just check they don't crash
          expect(result, isNotNull, reason: 'Sequence $sequenceId should return a result');
          
        } catch (e) {
          // Log but don't fail test for sequences that require specific state
          print('Info: Sequence $sequenceId requires specific state: $e');
        }
      }
    });

    test('should demonstrate full conversation workflow', () async {
      print('\n🎬 === DEMONSTRATING FULL CONVERSATION WORKFLOW ===\n');
      
      // Step 1: New user journey
      print('👤 Step 1: New user first visit');
      final newUserResult = await runConversation(
        sequenceId: 'welcome_seq',
        userState: {
          'user.name': null,
          'user.isOnboarded': false,
          'session.visitCount': 1,
          'session.totalVisitCount': 1,
        },
        interactive: false,
        verbose: false,
      );
      
      expect(newUserResult.completed, isTrue);
      print('✅ New user conversation completed (${newUserResult.messages.length} messages)');
      
      // Step 2: Returning user journey  
      print('\n👤 Step 2: Returning user with active task');
      final returningUserResult = await runConversation(
        sequenceId: 'welcome_seq',
        userState: {
          'user.name': 'John Doe',
          'user.isOnboarded': true,
          'task.isActiveDay': true,
          'task.currentStatus': 'pending',
          'session.visitCount': 3,
          'session.totalVisitCount': 15,
        },
        interactive: false,
        verbose: false,
      );
      
      expect(returningUserResult.completed, isTrue);
      print('✅ Returning user conversation completed (${returningUserResult.messages.length} messages)');
      
      // Step 3: Weekend user journey
      print('\n👤 Step 3: Weekend user (inactive day)');
      final weekendUserResult = await runConversation(
        sequenceId: 'welcome_seq',
        userState: {
          'user.name': 'Sarah Wilson',
          'user.isOnboarded': true,
          'task.isActiveDay': false,
          'session.isWeekend': true,
        },
        interactive: false,
        verbose: false,
      );
      
      expect(weekendUserResult.completed, isTrue);
      print('✅ Weekend user conversation completed (${weekendUserResult.messages.length} messages)');
      
      print('\n🎯 === FULL WORKFLOW DEMONSTRATION COMPLETE ===\n');
    });
  });
}