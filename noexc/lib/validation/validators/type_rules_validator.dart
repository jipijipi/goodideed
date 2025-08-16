/// Validates message type-specific rules (e.g., text emptiness for interactive/system types)
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class TypeRulesValidator {
  /// Ensures message text is empty for types that should not carry display text
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];

    for (final message in sequence.messages) {
      final mustBeEmpty = message.type == MessageType.choice ||
          message.type == MessageType.textInput ||
          message.type == MessageType.autoroute ||
          message.type == MessageType.dataAction ||
          message.type == MessageType.image;

      if (mustBeEmpty && message.text.isNotEmpty) {
        errors.add(
          ValidationError(
            type: ValidationConstants.invalidTextForType,
            message:
                'Message type "${message.type.name}" must not have text content',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
          ),
        );
      }
    }

    return errors;
  }
}

