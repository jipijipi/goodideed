import 'package:flutter/services.dart';
import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../models/validation_models.dart';

/// Validates variant files existence and consistency
class VariantFileValidator {
  /// Validates that variant files exist for sequences
  Future<List<ValidationError>> validateVariantFiles(
    ChatSequence sequence,
  ) async {
    final warnings = <ValidationError>[];

    for (final message in sequence.messages) {
      // Only check for variants on bot messages (not choice, textInput, or autoroute)
      if (message.type == MessageType.bot && message.text.isNotEmpty) {
        final variantPath =
            'assets/variants/${sequence.sequenceId}_message_${message.id}.txt';

        try {
          await rootBundle.loadString(variantPath);
          // File exists, no issue
        } catch (e) {
          // File doesn't exist, but this is just a warning since variants are optional
          warnings.add(
            ValidationError(
              type: 'MISSING_VARIANT_FILE',
              message: 'No variant file found at: $variantPath',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
              severity: 'info',
            ),
          );
        }
      }
    }

    return warnings;
  }

  /// Validates variant file format and content
  Future<List<ValidationError>> validateVariantContent(
    ChatSequence sequence,
  ) async {
    final warnings = <ValidationError>[];

    for (final message in sequence.messages) {
      if (message.type == MessageType.bot && message.text.isNotEmpty) {
        final variantPath =
            'assets/variants/${sequence.sequenceId}_message_${message.id}.txt';

        try {
          final variantContent = await rootBundle.loadString(variantPath);

          // Check if variant file is empty
          if (variantContent.trim().isEmpty) {
            warnings.add(
              ValidationError(
                type: 'EMPTY_VARIANT_FILE',
                message: 'Variant file is empty: $variantPath',
                messageId: message.id,
                sequenceId: sequence.sequenceId,
                severity: 'warning',
              ),
            );
          }

          // Check for consistent line endings and format
          final lines = variantContent.split('\n');
          if (lines.length == 1 && !variantContent.contains('\n')) {
            // Single line variant is valid
            continue;
          }

          // Multi-line variants should have proper formatting
          if (lines.any((line) => line.trim().isEmpty && line != lines.last)) {
            warnings.add(
              ValidationError(
                type: 'VARIANT_FORMAT_WARNING',
                message: 'Variant file contains empty lines: $variantPath',
                messageId: message.id,
                sequenceId: sequence.sequenceId,
                severity: 'info',
              ),
            );
          }
        } catch (e) {
          // File doesn't exist, but this is handled in validateVariantFiles
        }
      }
    }

    return warnings;
  }
}
