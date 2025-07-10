import 'user_data_service.dart';

class ConditionEvaluator {
  final UserDataService userDataService;

  ConditionEvaluator(this.userDataService);

  /// Evaluate a condition string and return true/false
  /// Supports operators: ==, !=, >, <, >=, <=
  /// Example: "user.name == 'Alice'" or "user.age >= 18"
  Future<bool> evaluate(String condition) async {
    print('🔍 CONDITION_EVAL: Starting evaluation of: "$condition"');
    try {
      // Parse the condition using a smarter approach that handles quoted strings
      final parsedCondition = _parseCondition(condition);
      if (parsedCondition == null) {
        // No operator found, treat as boolean check
        print('🔍 CONDITION_EVAL: No operator found, treating as boolean check');
        final value = await _getValue(condition);
        print('🔍 CONDITION_EVAL: Boolean check - value: $value (type: ${value.runtimeType})');
        final result = _isTruthy(value);
        print('✅ CONDITION_EVAL: Boolean result: $result');
        return result;
      }
      
      final operator = parsedCondition['operator'] as String;
      final leftOperand = parsedCondition['left'] as String;
      final rightOperand = parsedCondition['right'] as String;
      
      print('🔍 CONDITION_EVAL: Parsed - left: "$leftOperand", operator: "$operator", right: "$rightOperand"');
      
      final value = await _getValue(leftOperand);
      final expected = _parseValue(rightOperand);
      print('🔍 CONDITION_EVAL: Comparing $value $operator $expected (types: ${value.runtimeType} $operator ${expected.runtimeType})');
      
      bool result;
      switch (operator) {
        case '>=':
          result = _compareNumbers(value, expected, '>=');
          break;
        case '<=':
          result = _compareNumbers(value, expected, '<=');
          break;
        case '!=':
          result = value != expected;
          break;
        case '==':
          result = value == expected;
          break;
        case '>':
          result = _compareNumbers(value, expected, '>');
          break;
        case '<':
          result = _compareNumbers(value, expected, '<');
          break;
        default:
          print('❌ CONDITION_EVAL: Unknown operator: $operator');
          return false;
      }
      
      print('✅ CONDITION_EVAL: Result: $result');
      return result;
    } catch (e) {
      // If evaluation fails, return false to be safe
      print('❌ CONDITION_EVAL: ERROR evaluating "$condition": $e');
      return false;
    }
  }

  /// Parse a condition string into operator and operands
  /// Returns null if no operator is found (for boolean checks)
  Map<String, String>? _parseCondition(String condition) {
    // List of operators in order of precedence (longer ones first to avoid conflicts)
    final operators = ['>=', '<=', '!=', '==', '>', '<'];
    
    for (final operator in operators) {
      final operatorIndex = _findOperatorOutsideQuotes(condition, operator);
      if (operatorIndex != -1) {
        final left = condition.substring(0, operatorIndex).trim();
        final right = condition.substring(operatorIndex + operator.length).trim();
        return {
          'operator': operator,
          'left': left,
          'right': right,
        };
      }
    }
    
    return null; // No operator found - treat as boolean check
  }

  /// Find the position of an operator outside of quoted strings
  /// Returns -1 if not found
  int _findOperatorOutsideQuotes(String text, String operator) {
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    
    for (int i = 0; i <= text.length - operator.length; i++) {
      final char = text[i];
      
      // Track quote state
      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      }
      
      // If we're not inside quotes, check for operator
      if (!inSingleQuote && !inDoubleQuote) {
        if (text.substring(i, i + operator.length) == operator) {
          return i;
        }
      }
    }
    
    return -1;
  }

  /// Get a value from the user data service
  /// Supports "namespace.key" format (e.g., "user.name", "debug.age")
  Future<dynamic> _getValue(String key) async {
    print('🔍 CONDITION_EVAL: Getting value for key: "$key"');
    if (key.contains('.')) {
      // Extract namespace and key parts
      final parts = key.split('.');
      if (parts.length >= 2) {
        final namespace = parts[0];
        final actualKey = parts.sublist(1).join('.'); // Handle nested keys like "user.profile.name"
        print('🔍 CONDITION_EVAL: Resolved namespace: "$namespace", key: "$actualKey"');
        
        // For now, all namespaces use the same storage (UserDataService)
        // In the future, different namespaces could use different storage backends
        final storageKey = '$namespace.$actualKey';
        final value = await userDataService.getValue(storageKey);
        print('🔍 CONDITION_EVAL: Retrieved value: $value (type: ${value.runtimeType})');
        return value;
      }
    }
    print('🔍 CONDITION_EVAL: Key does not contain namespace, returning null');
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

  /// Compare two values numerically
  /// Returns false if either value is not a number
  bool _compareNumbers(dynamic left, dynamic right, String operator) {
    print('🔍 CONDITION_EVAL: Numeric comparison - left: $left, right: $right, operator: $operator');
    // Convert to numbers if possible
    final leftNum = _toNumber(left);
    final rightNum = _toNumber(right);
    print('🔍 CONDITION_EVAL: Converted to numbers - left: $leftNum, right: $rightNum');
    
    // Return false if either value is not a number
    if (leftNum == null || rightNum == null) {
      print('❌ CONDITION_EVAL: Cannot convert to numbers for comparison');
      return false;
    }
    
    switch (operator) {
      case '>':
        return leftNum > rightNum;
      case '<':
        return leftNum < rightNum;
      case '>=':
        return leftNum >= rightNum;
      case '<=':
        return leftNum <= rightNum;
      default:
        return false;
    }
  }

  /// Convert a value to a number (int or double)
  /// Returns null if the value cannot be converted
  num? _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue;
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) return doubleValue;
    }
    return null;
  }
}