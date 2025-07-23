import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:noexc/services/scenario_manager.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScenarioManager', () {

    testWidgets('should load scenarios from assets', (WidgetTester tester) async {
      // Mock the asset loading
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', 
        (ByteData? message) async {
          if (message != null) {
            final String key = utf8.decode(message.buffer.asUint8List());
            if (key == 'assets/debug/scenarios.json') {
              const String mockJson = '''
              {
                "test_scenario": {
                  "name": "Test Scenario",
                  "description": "A test scenario",
                  "variables": {
                    "user.name": "Test User",
                    "session.visitCount": 1
                  }
                }
              }
              ''';
              final bytes = utf8.encode(mockJson);
              return ByteData.sublistView(Uint8List.fromList(bytes));
            }
          }
          return null;
        },
      );

      final scenarios = await ScenarioManager.loadScenarios();
      
      expect(scenarios, isNotEmpty);
      expect(scenarios.containsKey('test_scenario'), isTrue);
      expect(scenarios['test_scenario']['name'], equals('Test Scenario'));
    });

    testWidgets('should apply scenario variables to UserDataService', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final userDataService = UserDataService();

      // Mock the asset loading for scenario application
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', 
        (ByteData? message) async {
          if (message != null) {
            final String key = utf8.decode(message.buffer.asUint8List());
            if (key == 'assets/debug/scenarios.json') {
              const String mockJson = '''
              {
                "test_scenario": {
                  "name": "Test Scenario",
                  "variables": {
                    "user.name": "Applied User",
                    "session.visitCount": 5,
                    "user.isOnboarded": true
                  }
                }
              }
              ''';
              final bytes = utf8.encode(mockJson);
              return ByteData.sublistView(Uint8List.fromList(bytes));
            }
          }
          return null;
        },
      );

      await ScenarioManager.applyScenario('test_scenario', userDataService);

      // Verify variables were applied
      expect(await userDataService.getValue<String>('user.name'), equals('Applied User'));
      expect(await userDataService.getValue<int>('session.visitCount'), equals(5));
      expect(await userDataService.getValue<bool>('user.isOnboarded'), equals(true));
    });

    testWidgets('should handle non-existent scenarios gracefully', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final userDataService = UserDataService();

      // Mock empty scenarios
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', 
        (ByteData? message) async {
          if (message != null) {
            final String key = utf8.decode(message.buffer.asUint8List());
            if (key == 'assets/debug/scenarios.json') {
              const String mockJson = '{}';
              final bytes = utf8.encode(mockJson);
              return ByteData.sublistView(Uint8List.fromList(bytes));
            }
          }
          return null;
        },
      );

      // Should not throw an exception
      await ScenarioManager.applyScenario('non_existent', userDataService);
      
      // No variables should be set
      expect(await userDataService.getValue<String>('user.name'), isNull);
    });
  });
}