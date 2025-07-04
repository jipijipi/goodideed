import 'user_data_service.dart';

class TextTemplatingService {
  final UserDataService _userDataService;

  TextTemplatingService(this._userDataService);

  /// Process template variables in text and replace them with stored values
  /// Supports fallback syntax: {key|fallback}
  Future<String> processTemplate(String text) async {
    if (text.isEmpty) {
      return text;
    }

    // Regular expression to find template variables like {user.name} or {user.name|fallback}
    final RegExp templateRegex = RegExp(r'\{([^}]+)\}');
    
    String result = text;
    final matches = templateRegex.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0)!; // The full match including braces
      final content = match.group(1)!; // The content without braces
      
      // Check if there's a fallback value (pipe character)
      String key;
      String? fallback;
      
      if (content.contains('|')) {
        final parts = content.split('|');
        key = parts[0];
        // Join remaining parts in case fallback contains pipe characters
        fallback = parts.sublist(1).join('|');
      } else {
        key = content;
        fallback = null;
      }
      
      // Try to get the stored value
      final storedValue = await _userDataService.getValue<dynamic>(key);
      
      if (storedValue != null) {
        // Replace the template variable with the stored value
        result = result.replaceAll(fullMatch, storedValue.toString());
      } else if (fallback != null) {
        // Use fallback value if no stored value exists
        result = result.replaceAll(fullMatch, fallback);
      }
      // If no stored value exists and no fallback, leave the template variable unchanged
    }

    return result;
  }
}