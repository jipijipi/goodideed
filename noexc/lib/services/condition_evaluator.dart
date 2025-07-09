import 'user_data_service.dart';

class ConditionEvaluator {
  final UserDataService userDataService;

  ConditionEvaluator(this.userDataService);

  /// Evaluate a condition string and return true/false
  /// Supports basic operators: ==, !=
  /// Example: "user.name == 'Alice'" or "user.subscription != null"
  Future<bool> evaluate(String condition) async {
    try {
      // Handle != operator
      if (condition.contains('!=')) {
        final parts = condition.split('!=').map((s) => s.trim()).toList();
        if (parts.length != 2) return false;
        
        final value = await _getValue(parts[0]);
        final expected = _parseValue(parts[1]);
        return value != expected;
      }
      
      // Handle == operator
      if (condition.contains('==')) {
        final parts = condition.split('==').map((s) => s.trim()).toList();
        if (parts.length != 2) return false;
        
        final value = await _getValue(parts[0]);
        final expected = _parseValue(parts[1]);
        return value == expected;
      }
      
      // If no operator found, treat as boolean check
      // Example: "user.is_premium" checks if the value is truthy
      final value = await _getValue(condition);
      return _isTruthy(value);
    } catch (e) {
      // If evaluation fails, return false to be safe
      return false;
    }
  }

  /// Get a value from the user data service
  /// Supports "user.key" format
  Future<dynamic> _getValue(String key) async {
    if (key.startsWith('user.')) {
      final userKey = key.substring(5); // Remove "user." prefix
      return await userDataService.getValue(userKey);
    }
    return null;
  }

  /// Parse a string value into appropriate type
  /// Handles: null, true, false, quoted strings, numbers
  dynamic _parseValue(String value) {
    final trimmed = value.trim();
    
    // Handle null
    if (trimmed == 'null') return null;
    
    // Handle booleans
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    
    // Handle quoted strings
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    
    // Try to parse as number
    final intValue = int.tryParse(trimmed);
    if (intValue != null) return intValue;
    
    final doubleValue = double.tryParse(trimmed);
    if (doubleValue != null) return doubleValue;
    
    // Return as string if nothing else matches
    return trimmed;
  }

  /// Check if a value is "truthy"
  /// null, false, 0, empty string are falsy
  /// Everything else is truthy
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}