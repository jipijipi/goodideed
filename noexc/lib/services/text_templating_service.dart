import 'user_data_service.dart';
import 'formatter_service.dart';

class TextTemplatingService {
  final UserDataService _userDataService;
  final FormatterService _formatterService = FormatterService();

  TextTemplatingService(this._userDataService);

  /// Process template variables in text and replace them with stored values
  /// Supports fallback syntax: {key|fallback} and formatter syntax: {key:formatter|fallback}
  Future<String> processTemplate(String text) async {
    if (text.isEmpty) {
      return text;
    }

    // Regular expression to find template variables like {user.name}, {user.name|fallback}, or {key:formatter|fallback}
    final RegExp templateRegex = RegExp(
      r'\{([^}:|]+)(?::([^}|]+))?(?:\|([^}]*))?\}',
    );

    String result = text;
    final matches = templateRegex.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0)!; // The full match including braces
      final key = match.group(1)!; // The key (e.g., "user.name")
      final formatter = match.group(2); // The formatter (e.g., "timeOfDay")
      final fallback = match.group(3); // The fallback value

      // Try to get the stored value
      final storedValue = await _userDataService.getValue<dynamic>(key);

      String? finalValue;

      if (storedValue != null) {
        // If formatter is specified, try to format the value
        if (formatter != null) {
          final formattedValue = await _formatterService.getFormattedValue(
            formatter,
            storedValue,
          );
          if (formattedValue != null) {
            finalValue = formattedValue;
          } else if (fallback != null) {
            // Formatter failed, try to apply case transformations to fallback if formatter contains case flags
            finalValue = await _applyFormatterToFallback(formatter, fallback);
          }
          // If formatter failed and no fallback, finalValue remains null
        } else {
          finalValue = storedValue.toString();
        }
      } else if (fallback != null) {
        // Use fallback value if no stored value exists
        if (formatter != null) {
          // Apply case transformations to fallback if formatter contains case flags
          finalValue = await _applyFormatterToFallback(formatter, fallback);
        } else {
          finalValue = fallback;
        }
      }

      // Replace the template variable with the final value
      if (finalValue != null) {
        result = result.replaceAll(fullMatch, finalValue);
      }
      // If no stored value exists and no fallback, leave the template variable unchanged
    }

    return result;
  }

  /// Apply case transformations from a formatter string to a fallback value
  /// Only applies case transformations (upper, lower, proper, sentence), ignores other formatter parts
  Future<String> _applyFormatterToFallback(String formatter, String fallback) async {
    // Check if the formatter contains case transformations
    final parts = formatter.split(':');
    final caseFlags = ['upper', 'lower', 'proper', 'sentence'];

    // Look for case flags in any part of the formatter
    final foundCaseFlags = parts.where((part) => caseFlags.contains(part)).toList();

    if (foundCaseFlags.isNotEmpty) {
      // Try to get formatted value using the case flags
      final caseFormatter = foundCaseFlags.first; // Use first case flag found
      final formattedFallback = await _formatterService.getFormattedValue(
        caseFormatter,
        fallback,
      );
      return formattedFallback ?? fallback;
    }

    return fallback;
  }
}
