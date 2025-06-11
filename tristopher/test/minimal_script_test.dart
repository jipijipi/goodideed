import 'package:flutter_test/flutter_test.dart';
import 'package:tristopher_app/models/conversation/conversation_engine.dart';
import 'package:tristopher_app/models/conversation/script_model.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';
import 'dart:convert';
import 'dart:io';

/// Minimal test script verification
/// 
/// This test verifies that the minimal script loads and functions correctly
/// for troubleshooting the conversation engine.
void main() {
  group('Minimal Script Tests', () {
    late ConversationDatabase database;
    late ConversationEngine engine;
    
    setUp(() async {
      database = ConversationDatabase();
      await database.database; // Initialize database
    });
    
    tearDown(() async {
      await database.clearCache();
    });

    test('Minimal script loads without errors', () async {
      // Load the minimal test script
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      
      if (!await scriptFile.exists()) {
        fail('Minimal test script file not found');
      }
      
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      
      // Verify it parses correctly
      expect(() => Script.fromJson(scriptJson), isA<Script>());
      
      final script = Script.fromJson(scriptJson);
      expect(script.id, 'minimal_test_script_en');
      expect(script.version, '1.0.0');
      expect(script.dailyEvents.length, 3);
      expect(script.plotTimeline.length, 2);
    });

    test('Simple daily event structure is correct', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      // Check simple_checkin event
      final checkinEvent = script.dailyEvents.firstWhere(
        (e) => e.id == 'simple_checkin'
      );
      
      expect(checkinEvent.trigger.type, 'time_window');
      expect(checkinEvent.trigger.startTime, '00:00');
      expect(checkinEvent.trigger.endTime, '23:59');
      expect(checkinEvent.variants.length, 1);
      expect(checkinEvent.variants.first.messages.length, 2);
      expect(checkinEvent.responses.length, 2);
    });

    test('Plot timeline day 1 is structured correctly', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      final day1 = script.plotTimeline['day_1'];
      expect(day1, isNotNull);
      expect(day1!.events.length, 1);
      
      final introEvent = day1.events.first;
      expect(introEvent.id, 'simple_intro');
      expect(introEvent.messages.length, 3);
      expect(introEvent.setVariables?['intro_completed'], true);
    });

    test('Message types are valid', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      // Collect all message types from the script
      final messageTypes = <String>{};
      
      for (final event in script.dailyEvents) {
        for (final variant in event.variants) {
          for (final message in variant.messages) {
            messageTypes.add(message.type);
          }
        }
      }
      
      for (final plotDay in script.plotTimeline.values) {
        for (final event in plotDay.events) {
          for (final message in event.messages) {
            messageTypes.add(message.type);
          }
        }
      }
      
      // Verify all message types are valid
      final validTypes = {'text', 'options', 'input', 'achievement', 'streak', 'sequence', 'conditional', 'animation', 'delay', 'branch'};
      for (final type in messageTypes) {
        expect(validTypes.contains(type), true, reason: 'Invalid message type: $type');
      }
    });

    test('Conversation engine initializes with minimal script', () async {
      // Set up test environment to use minimal script
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      
      // Save script to database
      await database.saveScript(
        id: 'minimal_test_script_en',
        version: '1.0.0',
        language: 'en',
        content: scriptJson,
      );
      
      // Initialize engine
      engine = ConversationEngine(language: 'en');
      
      // Should initialize without errors
      expect(() async => await engine.initialize(), returnsNormally);
    });

    test('Basic message conversion works', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      // Get first message from script
      final firstEvent = script.dailyEvents.first;
      final firstVariant = firstEvent.variants.first;
      final firstMessage = firstVariant.messages.first;
      
      // Verify message properties
      expect(firstMessage.type, 'text');
      expect(firstMessage.sender, 'tristopher');
      expect(firstMessage.content, 'Hello. This is a basic test message.');
      expect(firstMessage.delayMs, 1000);
    });

    test('Options structure is correct', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      // Find options message
      final checkinEvent = script.dailyEvents.firstWhere(
        (e) => e.id == 'simple_checkin'
      );
      final optionsMessage = checkinEvent.variants.first.messages.firstWhere(
        (m) => m.type == 'options'
      );
      
      expect(optionsMessage.options, isNotNull);
      expect(optionsMessage.options!.length, 2);
      
      final goodOption = optionsMessage.options!.firstWhere(
        (o) => o['id'] == 'good'
      );
      expect(goodOption['text'], 'I\'m good');
      expect(goodOption['setVariables']['mood'], 'good');
    });

    test('Input configuration is valid', () async {
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      final script = Script.fromJson(scriptJson);
      
      // Find input message in day_1
      final day1 = script.plotTimeline['day_1']!;
      final inputMessage = day1.events.first.messages.firstWhere(
        (m) => m.type == 'input'
      );
      
      expect(inputMessage.content, 'What\'s your name?');
      // Note: inputConfig would be checked when converting to EnhancedMessageModel
    });
  });

  group('Integration Tests - Minimal', () {
    test('Complete minimal flow simulation', () async {
      print('=== Minimal Script Flow Test ===');
      
      // This test simulates the complete flow
      final database = ConversationDatabase();
      await database.database;
      
      // Load and save minimal script
      final scriptFile = File('assets/scripts/minimal_test_script_en.json');
      final scriptContent = await scriptFile.readAsString();
      final scriptJson = jsonDecode(scriptContent);
      
      await database.saveScript(
        id: 'minimal_test_script_en',
        version: '1.0.0',
        language: 'en',
        content: scriptJson,
      );
      
      // Set up minimal user state
      await database.saveUserState('conversation_state', {
        'script_version': '1.0.0',
        'day_in_journey': 1,
        'variables': {
          'first_time': true,
        },
      });
      
      print('✓ Database setup complete');
      print('✓ Script saved successfully');
      print('✓ User state initialized');
      
      // Initialize engine
      final engine = ConversationEngine(language: 'en');
      await engine.initialize();
      
      print('✓ Engine initialized');
      print('=== Test completed successfully ===');
      
      expect(true, true); // If we get here, initialization worked
    });
  });
}

/// Helper function to run manual tests
void runManualTest() async {
  print('=== Manual Minimal Script Test ===');
  
  try {
    final database = ConversationDatabase();
    await database.database;
    print('✓ Database connected');
    
    final scriptFile = File('assets/scripts/minimal_test_script_en.json');
    
    if (await scriptFile.exists()) {
      print('✓ Script file found');
      
      final content = await scriptFile.readAsString();
      final json = jsonDecode(content);
      print('✓ Script JSON parsed');
      
      final script = Script.fromJson(json);
      print('✓ Script model created');
      print('  - ID: ${script.id}');
      print('  - Daily Events: ${script.dailyEvents.length}');
      print('  - Plot Days: ${script.plotTimeline.length}');
      
    } else {
      print('✗ Script file not found');
    }
    
  } catch (e) {
    print('✗ Error: $e');
  }
}
