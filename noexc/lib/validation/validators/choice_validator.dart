/// Validates choice message configurations
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class ChoiceValidator {
  /// Validates choice configurations
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];

    for (final message in sequence.messages) {
      if (message.type == MessageType.choice) {
        if (message.choices == null || message.choices!.isEmpty) {
          errors.add(
            ValidationError(
              type: ValidationConstants.missingChoices,
              message: 'Choice message must have at least one choice option',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
            ),
          );
        } else {
          // Check each choice has either nextMessageId or sequenceId
          for (int i = 0; i < message.choices!.length; i++) {
            final choice = message.choices![i];
            if (choice.nextMessageId == null && choice.sequenceId == null) {
              errors.add(
                ValidationError(
                  type: ValidationConstants.choiceNoDestination,
                  message:
                      'Choice "${choice.text}" has no destination (nextMessageId or sequenceId)',
                  messageId: message.id,
                  sequenceId: sequence.sequenceId,
                ),
              );
            }
          }
        }
      }
    }

    return errors;
  }
}
