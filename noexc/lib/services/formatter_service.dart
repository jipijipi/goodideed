import 'dart:convert';
import 'package:flutter/services.dart';

class FormatterService {
  static final FormatterService _instance = FormatterService._internal();
  factory FormatterService() => _instance;
  FormatterService._internal();

  final Map<String, Map<String, String>> _formatters = {};

  /// Load a formatter from JSON file and cache it
  Future<Map<String, String>?> _loadFormatter(String formatterName) async {
    if (_formatters.containsKey(formatterName)) {
      return _formatters[formatterName];
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/content/formatters/$formatterName.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Convert all values to strings for consistent formatting
      final Map<String, String> formatter = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      _formatters[formatterName] = formatter;
      return formatter;
    } catch (e) {
      // Formatter file not found or invalid JSON
      return null;
    }
  }

  /// Format a value using the specified formatter
  /// Returns the formatted string or null if formatter/value not found
  Future<String?> getFormattedValue(
    String formatterName,
    dynamic rawValue,
  ) async {
    final formatter = await _loadFormatter(formatterName);
    if (formatter == null) {
      return null;
    }

    final String key = rawValue.toString();
    return formatter[key];
  }

  /// Clear the cached formatters (primarily for testing)
  void clearCache() {
    _formatters.clear();
  }
}
