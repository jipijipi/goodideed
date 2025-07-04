import 'user_data_service.dart';

class TextTemplatingService {
  final UserDataService _userDataService;

  TextTemplatingService(this._userDataService);

  /// Process template variables in text and replace them with stored values
  Future<String> processTemplate(String text) async {
    if (text.isEmpty) {
      return text;
    }

    // Regular expression to find template variables like {user.name}
    final RegExp templateRegex = RegExp(r'\{([^}]+)\}');
    
    String result = text;
    final matches = templateRegex.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0)!; // The full match including braces
      final key = match.group(1)!; // The key without braces
      
      // Try to get the stored value
      final storedValue = await _userDataService.getValue<dynamic>(key);
      
      if (storedValue != null) {
        // Replace the template variable with the stored value
        result = result.replaceAll(fullMatch, storedValue.toString());
      }
      // If no stored value exists, leave the template variable unchanged
    }

    return result;
  }
}