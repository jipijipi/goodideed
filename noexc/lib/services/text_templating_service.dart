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
    final RegExp templateRegex = RegExp(r'\{([^}:|]+)(?::([^}|]+))?(?:\|([^}]*))?\}');
    
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
          final formattedValue = await _formatterService.getFormattedValue(formatter, storedValue);
          finalValue = formattedValue ?? storedValue.toString();
        } else {
          finalValue = storedValue.toString();
        }
      } else if (fallback != null) {
        // Use fallback value if no stored value exists
        finalValue = fallback;
      }
      
      // Replace the template variable with the final value
      if (finalValue != null) {
        result = result.replaceAll(fullMatch, finalValue);
      }
      // If no stored value exists and no fallback, leave the template variable unchanged
    }

    return result;
  }
}