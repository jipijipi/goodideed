/// Warns when a choice has both sequenceId and nextMessageId
library;

import '../../models/chat_sequence.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class ChoiceAmbiguityValidator {
  List<ValidationError> validate(ChatSequence sequence) {
    final warnings = <ValidationError>[];

    for (final m in sequence.messages) {
      if (m.choices == null || m.choices!.isEmpty) continue;
      for (final choice in m.choices!) {
        if (choice.sequenceId != null && choice.nextMessageId != null) {
          warnings.add(
            ValidationError(
              type: ValidationConstants.choiceAmbiguousDestination,
              message:
                  'Choice defines both sequenceId and nextMessageId; prefer one',
              messageId: m.id,
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
