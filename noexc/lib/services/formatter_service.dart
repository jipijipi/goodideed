import 'dart:convert';
import 'package:flutter/services.dart';

class FormatterService {
  static final FormatterService _instance = FormatterService._internal();
  factory FormatterService() => _instance;
  FormatterService._internal();

  final Map<String, Map<String, String>> _formatters = {};

  /// Unescape common escape sequences for markdown rendering
  /// Converts escaped characters from JSON strings to actual characters
  /// Centralized here to avoid duplication and ensure consistent behavior
  String unescapeTextForMarkdown(String text) {
    return text
        .replaceAll('\\\\', '\\x00TEMP_BACKSLASH\\x00') // Temporarily store backslashes
        .replaceAll('\\n', '\n') // Newlines for line breaks
        .replaceAll('\\t', '\t') // Tabs for indentation
        .replaceAll('\\r', '\r') // Carriage returns
        .replaceAll('\\"', '"') // Escaped quotes
        .replaceAll('\\x00TEMP_BACKSLASH\\x00', '\\\\'); // Restore backslashes (must be last)
  }

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
  /// Supports flags like 'join' for array processing: 'activeDays:join'
  Future<String?> getFormattedValue(
    String formatterName,
    dynamic rawValue,
  ) async {
    // Parse formatter name and flags
    final parts = formatterName.split(':');
    final baseFormatter = parts[0];
    final flags = parts.length > 1 ? parts.sublist(1) : <String>[];

    // Handle join flag for arrays
    if (flags.contains('join')) {
      return await _processArrayWithJoin(baseFormatter, rawValue);
    }

    // Fall back to existing logic for standard formatting
    final formatter = await _loadFormatter(baseFormatter);
    if (formatter == null) {
      return null;
    }

    final String key = rawValue.toString();
    return formatter[key];
  }

  /// Process an array value with join flag to create a grammatically correct sentence
  /// Handles multiple array formats: `[1,2,3]`, `"[1,2,3]"`, `"1,2,3"`
  Future<String?> _processArrayWithJoin(
    String formatterName,
    dynamic rawValue,
  ) async {
    // Load the base formatter first
    final formatter = await _loadFormatter(formatterName);
    if (formatter == null) return null;

    // For strings, check if there's a direct mapping first (like "1,2,3,4,5" -> "weekdays")
    if (rawValue is String) {
      final directMatch = formatter[rawValue];
      if (directMatch != null) {
        return directMatch;
      }
    }

    // Parse array from multiple formats
    final List<dynamic>? arrayValues = _parseAsArray(rawValue);
    if (arrayValues == null) {
      // Not an array, return null to maintain standard behavior
      return null;
    }

    // Convert each element using the formatter
    final List<String> formattedElements = [];
    for (final element in arrayValues) {
      final formatted = formatter[element.toString()];
      if (formatted != null) {
        formattedElements.add(formatted);
      }
    }

    // Join with smart grammar
    return _joinWithGrammar(formattedElements);
  }

  /// Parse various array formats into a List of dynamic values
  /// Supports: `[1,2,3]`, `"[1,2,3]"`, `"1,2,3"`
  /// But first checks if the string has a direct mapping in the formatter
  List<dynamic>? _parseAsArray(dynamic rawValue) {
    if (rawValue is List) return rawValue;

    if (rawValue is String) {
      final trimmed = rawValue.trim();

      // Handle "[1,2,3]" format (JSON array string)
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          return decoded is List ? decoded : null;
        } catch (_) {
          // Fall through to comma-separated parsing
        }
      }

      // Handle "1,2,3" format (comma-separated)
      // But only if it doesn't have a direct mapping in the formatter
      if (trimmed.contains(',')) {
        return trimmed.split(',').map((s) => s.trim()).toList();
      }
    }

    return null; // Not an array format
  }

  /// Join a list of strings with proper grammar
  /// Examples:
  /// - [] → ""
  /// - ["Monday"] → "Monday"
  /// - ["Monday", "Tuesday"] → "Monday and Tuesday"
  /// - ["Monday", "Tuesday", "Wednesday"] → "Monday, Tuesday and Wednesday"
  String _joinWithGrammar(List<String> elements) {
    if (elements.isEmpty) return '';
    if (elements.length == 1) return elements[0];
    if (elements.length == 2) return '${elements[0]} and ${elements[1]}';

    // For 3+ elements: "Monday, Tuesday and Wednesday"
    final allButLast = elements.sublist(0, elements.length - 1);
    final last = elements.last;
    return '${allButLast.join(', ')} and $last';
  }

  /// Clear the cached formatters (primarily for testing)
  void clearCache() {
    _formatters.clear();
  }
}
