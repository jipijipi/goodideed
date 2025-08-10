/// Validates basic sequence structure (required fields, duplicates)
library;

import '../../models/chat_sequence.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class StructureValidator {
  /// Validates basic sequence structure
  List<ValidationError> validate(ChatSequence sequence) {
    final errors = <ValidationError>[];

    // Check sequence has required fields
    if (sequence.sequenceId.isEmpty) {
      errors.add(
        ValidationError(
          type: ValidationConstants.missingSequenceId,
          message: 'Sequence ID is required',
          sequenceId: sequence.sequenceId,
        ),
      );
    }

    if (sequence.name.isEmpty) {
      errors.add(
        ValidationError(
          type: ValidationConstants.missingSequenceName,
          message: 'Sequence name is required',
          sequenceId: sequence.sequenceId,
        ),
      );
    }

    if (sequence.messages.isEmpty) {
      errors.add(
        ValidationError(
          type: ValidationConstants.emptySequence,
          message: 'Sequence must contain at least one message',
          sequenceId: sequence.sequenceId,
        ),
      );
    }

    // Check for duplicate message IDs
    final messageIds = sequence.messages.map((m) => m.id).toList();
    final uniqueIds = messageIds.toSet();
    if (messageIds.length != uniqueIds.length) {
      final duplicates = <int>[];
      for (final id in uniqueIds) {
        if (messageIds.where((mid) => mid == id).length > 1) {
          duplicates.add(id);
        }
      }
      errors.add(
        ValidationError(
          type: ValidationConstants.duplicateMessageIds,
          message: 'Duplicate message IDs found: ${duplicates.join(', ')}',
          sequenceId: sequence.sequenceId,
        ),
      );
    }

    return errors;
  }
}
