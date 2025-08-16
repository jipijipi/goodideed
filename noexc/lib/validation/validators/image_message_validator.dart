/// Validates image message rules
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class ImageMessageValidator {
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];

    for (final m in sequence.messages) {
      if (m.type == MessageType.image) {
        // Must have imagePath
        if (m.imagePath == null || m.imagePath!.isEmpty) {
          errors.add(
            ValidationError(
              type: ValidationConstants.invalidTextForType,
              message: 'Image message must define imagePath',
              messageId: m.id,
              sequenceId: sequence.sequenceId,
            ),
          );
        }
        // Must not have unrelated fields
        final hasInvalid = m.text.isNotEmpty ||
            (m.choices != null && m.choices!.isNotEmpty) ||
            (m.routes != null && m.routes!.isNotEmpty) ||
            (m.dataActions != null && m.dataActions!.isNotEmpty);
        if (hasInvalid) {
          errors.add(
            ValidationError(
              type: ValidationConstants.invalidTextForType,
              message: 'Image message must not have text/choices/routes/dataActions',
              messageId: m.id,
              sequenceId: sequence.sequenceId,
            ),
          );
        }
      }
    }

    return errors;
  }
}

