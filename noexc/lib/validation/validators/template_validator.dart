/// Validates template syntax in message text
library;

import '../../models/chat_sequence.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class TemplateValidator {
  /// Validates template syntax (basic validation)
  List<ValidationError> validate(ChatSequence sequence) {
    final warnings = <ValidationError>[];

    for (final message in sequence.messages) {
      if (message.text.isNotEmpty) {
        // Check for unclosed template brackets
        final openBrackets = message.text.split('{').length - 1;
        final closeBrackets = message.text.split('}').length - 1;

        if (openBrackets != closeBrackets) {
          warnings.add(
            ValidationError(
              type: ValidationConstants.templateSyntaxWarning,
              message: 'Mismatched template brackets in message text',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
              severity: ValidationConstants.severityWarning,
            ),
          );
        }
      }
    }

    return warnings;
  }
}
