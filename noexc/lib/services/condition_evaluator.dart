import 'user_data_service.dart';
import 'logger_service.dart';

class ConditionEvaluator {
  final UserDataService userDataService;

  ConditionEvaluator(this.userDataService);

  /// Evaluate a condition string and return true/false
  /// Supports operators: ==, !=, >, <, >=, <=
  /// Example: "user.name == 'Alice'" or "user.age >= 18"
  Future<bool> evaluate(String condition) async {
    logger.condition('Starting evaluation of: "$condition"');
    try {
      // Parse the condition using a smarter approach that handles quoted strings
      final parsedCondition = _parseCondition(condition);
      if (parsedCondition == null) {
        // No operator found, treat as boolean check
        logger.condition('No operator found, treating as boolean check');
        final value = await _getValue(condition);
        logger.condition('Boolean check - value: $value (type: ${value.runtimeType})');
        final result = _isTruthy(value);
        logger.condition('Boolean result: $result', level: LogLevel.info);
        return result;
      }
      
      final operator = parsedCondition['operator'] as String;
      final leftOperand = parsedCondition['left'] as String;
      final rightOperand = parsedCondition['right'] as String;
      
      logger.condition('Parsed - left: "$leftOperand", operator: "$operator", right: "$rightOperand"');
      
      final value = await _getValue(leftOperand);
      final expected = _parseValue(rightOperand);
      logger.condition('Comparing $value $operator $expected (types: ${value.runtimeType} $operator ${expected.runtimeType})');
      
      bool result;
      switch (operator) {
        case '>=':
          result = _compareNumbers(value, expected, '>=');
          break;
        case '<=':
          result = _compareNumbers(value, expected, '<=');
          break;
        case '!=':
          result = !_compareEquals(value, expected);
          break;
        case '==':
          result = _compareEquals(value, expected);
          break;
        case '>':
          result = _compareNumbers(value, expected, '>');
          break;
        case '<':
          result = _compareNumbers(value, expected, '<');
          break;
        default:
          logger.condition('Unknown operator: $operator', level: LogLevel.error);
          return false;
      }
      
      logger.condition('Result: $result', level: LogLevel.info);
      return result;
    } catch (e) {
      // If evaluation fails, return false to be safe
      logger.condition('ERROR evaluating "$condition": $e', level: LogLevel.error);
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
    logger.condition('Getting value for key: "$key"');
    if (key.contains('.')) {
      // Extract namespace and key parts
      final parts = key.split('.');
      if (parts.length >= 2) {
        final namespace = parts[0];
        final actualKey = parts.sublist(1).join('.'); // Handle nested keys like "user.profile.name"
        logger.condition('Resolved namespace: "$namespace", key: "$actualKey"');
        
        // For now, all namespaces use the same storage (UserDataService)
        // In the future, different namespaces could use different storage backends
        final storageKey = '$namespace.$actualKey';
        final value = await userDataService.getValue(storageKey);
        logger.condition('Retrieved value: $value (type: ${value.runtimeType})');
        return value;
      }
    }
    logger.condition('Key does not contain namespace, returning null', level: LogLevel.warning);
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
    logger.condition('Numeric comparison - left: $left, right: $right, operator: $operator');
    // Convert to numbers if possible
    final leftNum = _toNumber(left);
    final rightNum = _toNumber(right);
    logger.condition('Converted to numbers - left: $leftNum, right: $rightNum');
    
    // Return false if either value is not a number
    if (leftNum == null || rightNum == null) {
      logger.condition('Cannot convert to numbers for comparison', level: LogLevel.warning);
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

  /// Evaluate compound conditions with && and || operators
  Future<bool> evaluateCompound(String condition) async {
    logger.condition('Evaluating compound condition: "$condition"');
    
    // Handle OR conditions first (lower precedence)
    if (condition.contains('||')) {
      final parts = _splitOnOperatorOutsideQuotes(condition, '||');
      for (final part in parts) {
        if (await _evaluateCompoundPart(part.trim())) {
          return true;
        }
      }
      return false;
    }
    
    // Handle AND conditions
    if (condition.contains('&&')) {
      final parts = _splitOnOperatorOutsideQuotes(condition, '&&');
      for (final part in parts) {
        if (!await _evaluateCompoundPart(part.trim())) {
          return false;
        }
      }
      return true;
    }
    
    // Single condition
    return await _evaluateSingleCondition(condition);
  }

  /// Split string on operator while respecting quotes
  List<String> _splitOnOperatorOutsideQuotes(String text, String operator) {
    final parts = <String>[];
    int lastSplit = 0;
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
          parts.add(text.substring(lastSplit, i));
          lastSplit = i + operator.length;
          i += operator.length - 1; // Skip ahead
        }
      }
    }
    
    // Add the last part
    parts.add(text.substring(lastSplit));
    
    return parts;
  }

  /// Evaluate a part of a compound condition (could be simple or have other operators)
  Future<bool> _evaluateCompoundPart(String part) async {
    // If this part contains && or ||, evaluate it as a compound condition
    if (part.contains('&&') || part.contains('||')) {
      return await evaluateCompound(part);
    }
    // Otherwise, evaluate as a single condition
    return await _evaluateSingleCondition(part);
  }

  /// Evaluate a single condition (no && or ||)
  Future<bool> _evaluateSingleCondition(String condition) async {
    return await evaluate(condition);
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

  /// Compare two values for equality with type conversion
  bool _compareEquals(dynamic left, dynamic right) {
    // Direct equality check first
    if (left == right) return true;
    
    // Try numeric comparison if both can be converted to numbers
    final leftNum = _toNumber(left);
    final rightNum = _toNumber(right);
    if (leftNum != null && rightNum != null) {
      return leftNum == rightNum;
    }
    
    // Try string comparison
    if (left != null && right != null) {
      return left.toString() == right.toString();
    }
    
    return false;
  }
}