/// Validates message references and links within a sequence
import '../../models/chat_sequence.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class ReferenceValidator {
  /// Validates message references and links
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];
    final messageIds = sequence.messages.map((m) => m.id).toSet();
    
    for (final message in sequence.messages) {
      // Check nextMessageId references
      if (message.nextMessageId != null) {
        if (!messageIds.contains(message.nextMessageId)) {
          errors.add(ValidationError(
            type: ValidationConstants.invalidNextMessageId,
            message: 'References non-existent message ID: ${message.nextMessageId}',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
          ));
        }
      }
      
      // Check choice references
      if (message.choices != null) {
        for (final choice in message.choices!) {
          if (choice.nextMessageId != null && !messageIds.contains(choice.nextMessageId)) {
            errors.add(ValidationError(
              type: ValidationConstants.invalidChoiceNextMessageId,
              message: 'Choice "${choice.text}" references non-existent message ID: ${choice.nextMessageId}',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
            ));
          }
        }
      }
      
      // Check route references
      if (message.routes != null) {
        for (final route in message.routes!) {
          if (route.nextMessageId != null && !messageIds.contains(route.nextMessageId)) {
            errors.add(ValidationError(
              type: ValidationConstants.invalidRouteNextMessageId,
              message: 'Route references non-existent message ID: ${route.nextMessageId}',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
            ));
          }
        }
      }
    }
    
    return errors;
  }
}