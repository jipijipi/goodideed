/// Validates route conditions and autoroute configurations
library;
import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class RouteValidator {
  /// Validates route conditions
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];
    
    for (final message in sequence.messages) {
      if (message.type == MessageType.autoroute) {
        if (message.routes == null || message.routes!.isEmpty) {
          errors.add(ValidationError(
            type: ValidationConstants.missingRoutes,
            message: 'Autoroute message must have at least one route',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
          ));
        } else {
          // Check for default route
          final hasDefault = message.routes!.any((route) => route.isDefault);
          if (!hasDefault) {
            errors.add(ValidationError(
              type: ValidationConstants.missingDefaultRoute,
              message: 'Autoroute message must have a default route',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
            ));
          }
          
          // Check each route has destination
          for (final route in message.routes!) {
            if (route.nextMessageId == null && route.sequenceId == null) {
              errors.add(ValidationError(
                type: ValidationConstants.routeNoDestination,
                message: 'Route has no destination (nextMessageId or sequenceId)',
                messageId: message.id,
                sequenceId: sequence.sequenceId,
              ));
            }
          }
        }
      }
    }
    
    return errors;
  }
}