import 'dart:convert';
import 'package:flutter/services.dart';
import 'user_data_service.dart';
import 'logger_service.dart';

class ScenarioManager {
  static Map<String, dynamic>? _scenarios;

  /// Load scenarios from assets/debug/scenarios.json
  static Future<Map<String, dynamic>> loadScenarios() async {
    if (_scenarios != null) return _scenarios!;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/debug/scenarios.json',
      );
      _scenarios = json.decode(jsonString);
      return _scenarios!;
    } catch (e) {
      logger.scenario('Failed to load scenarios: $e', level: LogLevel.error);
      return {};
    }
  }

  /// Apply a scenario by setting all its variables in UserDataService
  static Future<void> applyScenario(
    String scenarioId,
    UserDataService userDataService,
  ) async {
    final scenarios = await loadScenarios();
    final scenario = scenarios[scenarioId];

    if (scenario == null) {
      logger.scenario(
        'Scenario not found: $scenarioId',
        level: LogLevel.warning,
      );
      return;
    }

    final variables = scenario['variables'] as Map<String, dynamic>?;
    if (variables == null) {
      logger.scenario(
        'No variables found in scenario: $scenarioId',
        level: LogLevel.warning,
      );
      return;
    }

    // Apply all variables in the scenario
    logger.scenario(
      'Applying scenario "$scenarioId" with ${variables.length} variables',
    );
    for (final entry in variables.entries) {
      try {
        await userDataService.storeValue(entry.key, entry.value);
      } catch (e) {
        logger.scenario(
          'Failed to set ${entry.key} = ${entry.value}: $e',
          level: LogLevel.error,
        );
      }
    }
    logger.scenario(
      'Successfully applied scenario "$scenarioId"',
      level: LogLevel.info,
    );
  }

  /// Get the display name for a scenario
  static Future<String?> getScenarioName(String scenarioId) async {
    final scenarios = await loadScenarios();
    final scenario = scenarios[scenarioId];
    return scenario?['name'];
  }

  /// Get the description for a scenario
  static Future<String?> getScenarioDescription(String scenarioId) async {
    final scenarios = await loadScenarios();
    final scenario = scenarios[scenarioId];
    return scenario?['description'];
  }

  /// Get all available scenario IDs
  static Future<List<String>> getAvailableScenarios() async {
    final scenarios = await loadScenarios();
    return scenarios.keys.toList();
  }
}
