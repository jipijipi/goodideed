import '../../constants/app_constants.dart';
import '../models/validation_models.dart';
import 'sequence_file_validator.dart';

/// Validates template variables consistency across sequences
class TemplateVariableValidator {
  final SequenceFileValidator _sequenceFileValidator = SequenceFileValidator();
  
  /// Validates template variable consistency across sequences
  Future<List<ValidationError>> validateTemplateVariables() async {
    final warnings = <ValidationError>[];
    final allVariables = <String, Set<String>>{}; // variable -> sequences using it
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence == null) continue;
      
      for (final message in sequence.messages) {
        // Extract template variables from message text
        final variables = _extractTemplateVariables(message.text);
        for (final variable in variables) {
          allVariables.putIfAbsent(variable, () => <String>{}).add(sequenceId);
        }
        
        // Check placeholder text for variables
        if (message.placeholderText.isNotEmpty) {
          final placeholderVars = _extractTemplateVariables(message.placeholderText);
          for (final variable in placeholderVars) {
            allVariables.putIfAbsent(variable, () => <String>{}).add(sequenceId);
          }
        }
      }
    }
    
    // Report variables used in multiple sequences (for consistency awareness)
    for (final entry in allVariables.entries) {
      if (entry.value.length > 1) {
        warnings.add(ValidationError(
          type: 'SHARED_TEMPLATE_VARIABLE',
          message: 'Template variable "${entry.key}" is used in multiple sequences: ${entry.value.join(', ')}',
          severity: 'info',
        ));
      }
    }
    
    return warnings;
  }
  
  /// Validates template variable syntax in individual sequences
  Future<List<ValidationError>> validateTemplateVariableSyntax() async {
    final warnings = <ValidationError>[];
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence == null) continue;
      
      for (final message in sequence.messages) {
        final templateErrors = _validateTemplateSyntax(message.text, message.id, sequenceId);
        warnings.addAll(templateErrors);
        
        if (message.placeholderText.isNotEmpty) {
          final placeholderErrors = _validateTemplateSyntax(message.placeholderText, message.id, sequenceId);
          warnings.addAll(placeholderErrors);
        }
      }
    }
    
    return warnings;
  }
  
  /// Extracts template variables from text
  Set<String> _extractTemplateVariables(String text) {
    final variables = <String>{};
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final fullMatch = match.group(1)!;
      // Extract variable name (before | if fallback syntax is used)
      final variable = fullMatch.split('|').first.trim();
      variables.add(variable);
    }
    
    return variables;
  }
  
  /// Validates template syntax for a specific text
  List<ValidationError> _validateTemplateSyntax(String text, int messageId, String sequenceId) {
    final errors = <ValidationError>[];
    
    // Check for unmatched braces
    final openBraces = text.split('{').length - 1;
    final closeBraces = text.split('}').length - 1;
    
    if (openBraces != closeBraces) {
      errors.add(ValidationError(
        type: 'TEMPLATE_SYNTAX_ERROR',
        message: 'Unmatched template braces in text: "$text"',
        messageId: messageId,
        sequenceId: sequenceId,
        severity: 'warning',
      ));
    }
    
    // Check for empty template variables
    final emptyVariables = RegExp(r'\{\s*\}');
    if (emptyVariables.hasMatch(text)) {
      errors.add(ValidationError(
        type: 'EMPTY_TEMPLATE_VARIABLE',
        message: 'Empty template variable found in text: "$text"',
        messageId: messageId,
        sequenceId: sequenceId,
        severity: 'warning',
      ));
    }
    
    // Check for nested braces
    final nestedBraces = RegExp(r'\{[^}]*\{[^}]*\}[^}]*\}');
    if (nestedBraces.hasMatch(text)) {
      errors.add(ValidationError(
        type: 'NESTED_TEMPLATE_BRACES',
        message: 'Nested template braces found in text: "$text"',
        messageId: messageId,
        sequenceId: sequenceId,
        severity: 'warning',
      ));
    }
    
    return errors;
  }
}