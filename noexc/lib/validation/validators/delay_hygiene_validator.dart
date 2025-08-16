/// Warns on unnecessary delays for non-display/interactive types
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class DelayHygieneValidator {
  List<ValidationError> validate(ChatSequence sequence) {
    final warnings = <ValidationError>[];

    for (final m in sequence.messages) {
      final shouldWarn = m.type == MessageType.choice ||
          m.type == MessageType.textInput ||
          m.type == MessageType.autoroute ||
          m.type == MessageType.dataAction ||
          m.type == MessageType.image;
      if (shouldWarn && m.hasExplicitDelay && m.delay != 0) {
        warnings.add(
          ValidationError(
            type: 'UNNECESSARY_DELAY',
            message:
                'Delay on ${m.type.name} is ignored by UI; consider removing for clarity',
            messageId: m.id,
            sequenceId: sequence.sequenceId,
            severity: ValidationConstants.severityWarning,
          ),
        );
      }
    }

    return warnings;
  }
}

