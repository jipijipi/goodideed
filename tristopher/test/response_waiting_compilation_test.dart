import 'package:flutter_test/flutter_test.dart';
import 'package:tristopher_app/models/conversation/conversation_engine.dart';
import 'package:tristopher_app/models/conversation/script_model.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';
import 'dart:convert';

/// Compilation test to verify the response waiting fixes work
void main() {
  group('Response Waiting Compilation Tests', () {
    test('ConversationEngine compiles and initializes', () async {
      // This test verifies the code compiles without errors
      expect(() {
        final engine = ConversationEngine(language: 'en');
        return engine;
      }, returnsNormally);
    });

    test('ScriptMessage with inputConfig compiles', () {
      // Test the updated ScriptMessage model
      final scriptMessageJson = {
        'type': 'input',
        'sender': 'tristopher',
        'content': 'What is your name?',
        'inputConfig': {
          'hint': 'Enter your name',
          'keyboardType': 'TextInputType.text',
          'maxLength': 20
        }
      };

      expect(() {
        final message = ScriptMessage.fromJson(scriptMessageJson);
        return message;
      }, returnsNormally);

      final message = ScriptMessage.fromJson(scriptMessageJson);
      expect(message.inputConfig, isNotNull);
      expect(message.inputConfig!['hint'], 'Enter your name');
    });

    test('Response waiting test script loads', () {
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
        'global_variables': {},
        'daily_events': [
          {
            'id': 'test_event',
            'trigger': {
              'type': 'time_window',
              'start': '00:00',
              'end': '23:59',
              'conditions': {},
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
                  },
                  {
                    'type': 'options',
                    'sender': 'tristopher',
                    'content': 'Choose an option:',
                    'options': [
                      {
                        'id': 'option1',
                        'text': 'Option 1',
                      }
                    ]
                  },
                  {
                    'type': 'input',
                    'sender': 'tristopher',
                    'content': 'Enter something:',
                    'inputConfig': {
                      'hint': 'Type here',
                      'keyboardType': 'TextInputType.text'
                    }
                  }
                ],
              }
            ],
            'responses': {
              'option1': {
                'set_variables': {'selected': 'option1'}
              }
            },
          }
        ],
        'plot_timeline': {},
        'message_templates': {},
      };

      expect(() {
        final script = Script.fromJson(scriptJson);
        return script;
      }, returnsNormally);

      final script = Script.fromJson(scriptJson);
      expect(script.dailyEvents.length, 1);
      
      final event = script.dailyEvents.first;
      expect(event.variants.first.messages.length, 3);
      
      // Check input message
      final inputMessage = event.variants.first.messages[2];
      expect(inputMessage.type, 'input');
      expect(inputMessage.inputConfig, isNotNull);
      expect(inputMessage.inputConfig!['hint'], 'Type here');
    });

    test('Engine methods exist and are callable', () {
      final engine = ConversationEngine(language: 'en');
      
      // Test that new methods exist
      expect(engine.isAwaitingResponse, isFalse);
      expect(engine.awaitingResponseForMessageId, isNull);
      
      // Test that methods can be called (they will handle initialization internally)
      expect(() async {
        await engine.selectOption('test-id', 'test-option');
      }, returnsNormally);
      
      expect(() async {
        await engine.submitInput('test-id', 'test-input');
      }, returnsNormally);
    });
  });
}
