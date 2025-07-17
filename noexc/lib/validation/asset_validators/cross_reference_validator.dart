import '../../constants/app_constants.dart';
import '../models/validation_models.dart';
import 'sequence_file_validator.dart';

/// Validates cross-sequence references between different sequences
class CrossReferenceValidator {
  final SequenceFileValidator _sequenceFileValidator = SequenceFileValidator();
  
  /// Validates cross-sequence references
  Future<List<ValidationError>> validateCrossSequenceReferences() async {
    final errors = <ValidationError>[];
    final availableSequences = AppConstants.availableSequences.toSet();
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence == null) continue;
      
      for (final message in sequence.messages) {
        // Check choice sequence references
        if (message.choices != null) {
          for (final choice in message.choices!) {
            if (choice.sequenceId != null && !availableSequences.contains(choice.sequenceId)) {
              errors.add(ValidationError(
                type: 'INVALID_SEQUENCE_REFERENCE',
                message: 'Choice references non-existent sequence: ${choice.sequenceId}',
                messageId: message.id,
                sequenceId: sequence.sequenceId,
              ));
            }
          }
        }
        
        // Check route sequence references
        if (message.routes != null) {
          for (final route in message.routes!) {
            if (route.sequenceId != null && !availableSequences.contains(route.sequenceId)) {
              errors.add(ValidationError(
                type: 'INVALID_SEQUENCE_REFERENCE',
                message: 'Route references non-existent sequence: ${route.sequenceId}',
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
  
  /// Validates that referenced sequences actually exist and are accessible
  Future<List<ValidationError>> validateSequenceAccessibility() async {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence == null) {
        errors.add(ValidationError(
          type: 'SEQUENCE_NOT_ACCESSIBLE',
          message: 'Referenced sequence cannot be loaded: $sequenceId',
          sequenceId: sequenceId,
        ));
        continue;
      }
      
      // Check if sequence ID in file matches expected ID
      if (sequence.sequenceId != sequenceId) {
        warnings.add(ValidationError(
          type: 'SEQUENCE_ID_MISMATCH',
          message: 'Sequence file $sequenceId contains sequenceId "${sequence.sequenceId}"',
          sequenceId: sequenceId,
          severity: 'warning',
        ));
      }
    }
    
    return [...errors, ...warnings];
  }
}