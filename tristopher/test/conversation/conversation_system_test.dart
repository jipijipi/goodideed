import 'package:flutter_test/flutter_test.dart';
import 'package:tristopher_app/models/conversation/enhanced_message_model.dart';
import 'package:tristopher_app/models/conversation/script_model.dart';
import 'package:tristopher_app/models/conversation/conversation_engine.dart';
import 'package:tristopher_app/models/conversation/localization_manager.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';
import 'dart:convert';

/// Test suite for the Tristopher conversation system.
/// 
/// These tests demonstrate the key features of the system and provide
/// examples of how to test different conversation scenarios.
void main() {
  group('Conversation System Tests', () {
    late ConversationDatabase database;
    late ConversationEngine engine;
    late LocalizationManager localization;
    
    setUp(() async {
      // Initialize test environment
      database = ConversationDatabase();
      localization = LocalizationManager();
      engine = ConversationEngine(language: 'en');
      
      // Initialize database for testing
      await database.database;
    });
    
    tearDown(() async {
      // Clean up after tests
      await database.clearCache();
    });
    
    test('Database initialization creates all tables', () async {
      final db = await database.database;
      
      // Verify tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      
      final tableNames = tables.map((t) => t['name']).toSet();
      expect(tableNames.contains('scripts'), true);
      expect(tableNames.contains('messages'), true);
      expect(tableNames.contains('user_state'), true);
      expect(tableNames.contains('cache_metadata'), true);
    });
    
    test('Script model correctly parses JSON', () {
      final scriptJson = {
        'id': 'test_script',
        'version': '1.0.0',
        'metadata': {
          'author': 'test',
          'created_at': '2024-01-15T10:00:00Z',
          'description': 'Test script',
          'supported_languages': ['en'],
          'is_active': true,
        },
        'global_variables': {
          'robot_personality_level': 5,
        },
        'daily_events': [
          {
            'id': 'test_event',
            'trigger': {
              'type': 'time_window',
              'start': '09:00',
              'end': '17:00',
              'conditions': {'test': true},
            },
            'variants': [
              {
                'id': 'variant1',
                'weight': 1.0,
                'conditions': {},
                'messages': [
                  {
                    'type': 'text',
                    'sender': 'tristopher',
                    'content': 'Test message',
                  }
                ],
              }
            ],
            'responses': {},
          }
        ],
        'plot_timeline': {},
        'message_templates': {},
      };
      
      final script = Script.fromJson(scriptJson);
      
      expect(script.id, 'test_script');
      expect(script.version, '1.0.0');
      expect(script.dailyEvents.length, 1);
      expect(script.dailyEvents.first.id, 'test_event');
    });
    
    test('Enhanced message supports all visual effects', () {
      final message = EnhancedMessageModel(
        id: '123',
        type: MessageType.text,
        content: 'Test message',
        sender: MessageSender.tristopher,
        timestamp: DateTime.now(),
        bubbleStyle: BubbleStyle.glitch,
        animation: AnimationType.bounce,
        textEffect: TextEffect.rainbow,
        delayMs: 1500,
      );
      
      expect(message.bubbleStyle, BubbleStyle.glitch);
      expect(message.animation, AnimationType.bounce);
      expect(message.textEffect, TextEffect.rainbow);
      expect(message.delayMs, 1500);
      
      // Test JSON serialization
      final json = message.toJson();
      final decoded = EnhancedMessageModel.fromJson(json);
      
      expect(decoded.id, message.id);
      expect(decoded.bubbleStyle, message.bubbleStyle);
      expect(decoded.animation, message.animation);
    });
    
    test('Localization manager applies variables correctly', () async {
      final manager = LocalizationManager();
      
      // Test simple variable substitution
      final template = "Hello {{name}}, you have {{count}} messages";
      final result = manager._applyVariables(template, {
        'name': 'John',
        'count': 5,
      });
      
      expect(result, 'Hello John, you have 5 messages');
      
      // Test plural handling
      final pluralTemplate = "{{count}} {{count:day|days}} remaining";
      
      final singular = manager._applyVariables(pluralTemplate, {'count': 1});
      expect(singular, '1 day remaining');
      
      final plural = manager._applyVariables(pluralTemplate, {'count': 3});
      expect(plural, '3 days remaining');
      
      // Test conditional text
      const conditionalTemplate = "Status: {{active?Online:Offline}}";
      
      final online = manager._applyVariables(conditionalTemplate, {'active': true});
      expect(online, 'Status: Online');
      
      final offline = manager._applyVariables(conditionalTemplate, {'active': false});
      expect(offline, 'Status: Offline');
    });
    
    test('Conversation engine evaluates conditions correctly', () async {
      await engine.initialize();
      
      // Test range conditions
      final rangeConditions = {
        'streak_count': {'min': 5, 'max': 10},
      };
      
      // Set user state
      await database.saveUserState('conversation_state', {
        'variables': {'streak_count': 7},
      });
      await engine.initialize(); // Reload state
      
      final result = engine._evaluateConditions(rangeConditions);
      expect(result, true);
      
      // Test value outside range
      await database.saveUserState('conversation_state', {
        'variables': {'streak_count': 15},
      });
      await engine.initialize();
      
      final result2 = engine._evaluateConditions(rangeConditions);
      expect(result2, false);
    });
    
    test('Message history is saved and retrieved correctly', () async {
      // Save some test messages
      await database.saveMessage(
        id: '1',
        sender: 'tristopher',
        type: 'text',
        content: 'First message',
      );
      
      await database.saveMessage(
        id: '2',
        sender: 'user',
        type: 'text',
        content: 'User response',
      );
      
      // Retrieve messages
      final messages = await database.getMessages();
      
      expect(messages.length, 2);
      expect(messages.first['content'], 'User response'); // Newest first
      expect(messages.last['content'], 'First message');
    });
    
    test('Script caching works correctly', () async {
      // Save a script
      await database.saveScript(
        id: 'test_script',
        version: '1.0.0',
        language: 'en',
        content: {'test': 'data'},
      );
      
      // Save cache metadata
      await database.saveCacheMetadata(
        'script_1.0.0',
        DateTime.now().toIso8601String(),
        const Duration(days: 7),
      );
      
      // Check if cache is valid
      final isValid = await database.isCacheValid('script_1.0.0');
      expect(isValid, true);
      
      // Check expired cache
      await database.saveCacheMetadata(
        'old_script',
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        const Duration(days: 7),
      );
      
      final isExpired = await database.isCacheValid('old_script');
      expect(isExpired, false);
    });
  });
  
  group('Integration Tests', () {
    test('Complete daily check-in flow', () async {
      // This test demonstrates a complete conversation flow
      final engine = ConversationEngine(language: 'en');
      await engine.initialize();
      
      // Set up user state for testing
      await ConversationDatabase().saveUserState('conversation_state', {
        'script_version': '1.0.0',
        'day_in_journey': 5,
        'variables': {
          'streak_count': 4,
          'goal_action': 'exercise',
          'has_active_goal': true,
          'checked_in_today': false,
        },
      });
      
      // Process daily events
      final messages = <EnhancedMessage>[];
      await for (final message in engine.processDaily()) {
        messages.add(message);
        print('${message.sender}: ${message.content}');
        
        // Simulate user response to options
        if (message.options != null && message.options!.isNotEmpty) {
          // Simulate selecting "Yes, I did it"
          final yesOption = message.options!.first;
          print('User selects: ${yesOption.text}');
          break; // Stop after first interaction for test
        }
      }
      
      expect(messages.isNotEmpty, true);
      expect(messages.first.sender, MessageSender.tristopher);
    });
  });
}

/// Example: How to test specific conversation scenarios
/// 
/// Use these patterns to test different paths through your conversation:
void demonstrateTestScenarios() {
  test('Test first-time user experience', () async {
    // Set up as new user
    final database = ConversationDatabase();
    await database.saveUserState('conversation_state', {
      'day_in_journey': 1,
      'variables': {
        'first_time': true,
        'streak_count': 0,
      },
    });
    
    // Run conversation engine
    final engine = ConversationEngine(language: 'en');
    await engine.initialize();
    
    // Verify introduction messages appear
    // ... test implementation
  });
  
  test('Test streak milestone achievement', () async {
    // Set up user at milestone
    final database = ConversationDatabase();
    await database.saveUserState('conversation_state', {
      'day_in_journey': 7,
      'variables': {
        'streak_count': 7,
      },
    });
    
    // Verify achievement message appears
    // ... test implementation
  });
  
  test('Test failure flow with stake loss', () async {
    // Set up user who will fail
    final database = ConversationDatabase();
    await database.saveUserState('conversation_state', {
      'variables': {
        'streak_count': 10,
        'stake_amount': 10.00,
        'anti_charity': 'Political Campaign X',
      },
    });
    
    // Simulate failure response
    // Verify failure messages and animations
    // ... test implementation
  });
}

/// Example: Performance testing
void demonstratePerformanceTests() {
  test('Message loading performance', () async {
    final stopwatch = Stopwatch()..start();
    
    // Load 1000 messages
    final database = ConversationDatabase();
    for (int i = 0; i < 1000; i++) {
      await database.saveMessage(
        id: 'msg_$i',
        sender: i % 2 == 0 ? 'tristopher' : 'user',
        type: 'text',
        content: 'Test message $i',
      );
    }
    
    stopwatch.stop();
    print('Saved 1000 messages in ${stopwatch.elapsedMilliseconds}ms');
    
    // Test retrieval
    stopwatch.reset();
    stopwatch.start();
    
    final messages = await database.getMessages(limit: 100);
    
    stopwatch.stop();
    print('Retrieved 100 messages in ${stopwatch.elapsedMilliseconds}ms');
    
    // Should be fast even with large datasets
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
