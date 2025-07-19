/// Shared validation models for sequence validation
library;
import '../../constants/validation_constants.dart';

/// Represents a validation error found in a sequence
class ValidationError {
  final String type;
  final String message;
  final int? messageId;
  final String? sequenceId;
  final String severity; // 'error', 'warning', 'info'
  
  ValidationError({
    required this.type,
    required this.message,
    this.messageId,
    this.sequenceId,
    this.severity = ValidationConstants.severityError,
  });
  
  @override
  String toString() {
    final location = messageId != null ? ' (Message ID: $messageId)' : '';
    final seq = sequenceId != null ? ' in sequence "$sequenceId"' : '';
    return '[$severity] $type: $message$location$seq';
  }
}

/// Represents the result of sequence validation
class ValidationResult {
  final List<ValidationError> errors;
  final List<ValidationError> warnings;
  final List<ValidationError> info;
  final bool isValid;
  
  ValidationResult({
    required this.errors,
    required this.warnings,
    required this.info,
  }) : isValid = errors.isEmpty;
  
  List<ValidationError> get allIssues => [...errors, ...warnings, ...info];
  
  @override
  String toString() {
    if (isValid && warnings.isEmpty && info.isEmpty) {
      return 'Validation passed: No issues found';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Validation Results:');
    
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors: ${errors.length}');
      for (final error in errors) {
        buffer.writeln('    $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings: ${warnings.length}');
      for (final warning in warnings) {
        buffer.writeln('    $warning');
      }
    }
    
    if (info.isNotEmpty) {
      buffer.writeln('  Info (${info.length}):');
      for (final infoItem in info) {
        buffer.writeln('    $infoItem');
      }
    }
    
    return buffer.toString().trim();
  }
}