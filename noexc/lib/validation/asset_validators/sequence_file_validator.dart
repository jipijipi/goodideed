import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/chat_sequence.dart';
import '../../constants/app_constants.dart';
import '../sequence_validator.dart';
import '../models/validation_models.dart';

/// Validates sequence files loading and basic sequence validation
class SequenceFileValidator {
  /// Validates all sequence files in the assets directory
  Future<ValidationResult> validateAllSequenceFiles() async {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    final info = <ValidationError>[];

    // Get all available sequences
    final availableSequences = AppConstants.availableSequences;

    for (final sequenceId in availableSequences) {
      try {
        // Try to load and validate each sequence
        final sequence = await loadSequence(sequenceId);
        if (sequence != null) {
          final validator = SequenceValidator();
          final result = validator.validateSequence(sequence);

          errors.addAll(result.errors);
          warnings.addAll(result.warnings);
          info.addAll(result.info);
        }
      } catch (e) {
        errors.add(
          ValidationError(
            type: 'SEQUENCE_LOAD_ERROR',
            message: 'Failed to load sequence: $e',
            sequenceId: sequenceId,
          ),
        );
      }
    }

    return ValidationResult(errors: errors, warnings: warnings, info: info);
  }

  /// Loads a sequence from assets
  Future<ChatSequence?> loadSequence(String sequenceId) async {
    try {
      final assetPath = 'assets/sequences/$sequenceId.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      return ChatSequence.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Checks if asset files exist and are accessible
  Future<ValidationResult> checkAssetFileAccess() async {
    final errors = <ValidationError>[];
    final info = <ValidationError>[];

    // Check sequence files
    for (final sequenceId in AppConstants.availableSequences) {
      final assetPath = 'assets/sequences/$sequenceId.json';
      try {
        await rootBundle.loadString(assetPath);
        info.add(
          ValidationError(
            type: 'ASSET_FILE_OK',
            message: 'Sequence file accessible: $assetPath',
            sequenceId: sequenceId,
            severity: 'info',
          ),
        );
      } catch (e) {
        errors.add(
          ValidationError(
            type: 'ASSET_FILE_ERROR',
            message: 'Cannot access sequence file: $assetPath ($e)',
            sequenceId: sequenceId,
          ),
        );
      }
    }

    return ValidationResult(errors: errors, warnings: [], info: info);
  }
}
