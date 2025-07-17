import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/chat_sequence.dart';
import '../models/chat_message.dart';
import '../constants/app_constants.dart';
import 'sequence_validator.dart';
import 'models/validation_models.dart';
import 'asset_validators/sequence_file_validator.dart';
import 'asset_validators/variant_file_validator.dart';
import 'asset_validators/cross_reference_validator.dart';
import 'asset_validators/json_schema_validator.dart';
import 'asset_validators/template_variable_validator.dart';

/// Main asset validator that orchestrates all asset validation types
class AssetValidator {
  final SequenceFileValidator _sequenceFileValidator = SequenceFileValidator();
  final VariantFileValidator _variantFileValidator = VariantFileValidator();
  final CrossReferenceValidator _crossReferenceValidator = CrossReferenceValidator();
  final JsonSchemaValidator _jsonSchemaValidator = JsonSchemaValidator();
  final TemplateVariableValidator _templateVariableValidator = TemplateVariableValidator();

  /// Validates all sequence files in the assets directory
  Future<ValidationResult> validateAllSequenceFiles() async {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    final info = <ValidationError>[];
    
    // 1. Validate sequence files and basic sequence structure
    final sequenceResult = await _sequenceFileValidator.validateAllSequenceFiles();
    errors.addAll(sequenceResult.errors);
    warnings.addAll(sequenceResult.warnings);
    info.addAll(sequenceResult.info);
    
    // 2. Validate variant files for each sequence
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence != null) {
        final variantIssues = await _variantFileValidator.validateVariantFiles(sequence);
        warnings.addAll(variantIssues);
      }
    }
    
    // 3. Validate cross-sequence references
    final crossRefIssues = await _crossReferenceValidator.validateCrossSequenceReferences();
    errors.addAll(crossRefIssues);
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }

  /// Validates JSON schema structure
  Future<ValidationResult> validateJsonSchema(String sequenceId) async {
    return await _jsonSchemaValidator.validateJsonSchema(sequenceId);
  }

  /// Validates template variable consistency across sequences
  Future<List<ValidationError>> validateTemplateVariables() async {
    return await _templateVariableValidator.validateTemplateVariables();
  }

  /// Checks if asset files exist and are accessible
  Future<ValidationResult> checkAssetFileAccess() async {
    return await _sequenceFileValidator.checkAssetFileAccess();
  }

  /// Comprehensive validation that runs all validation types
  Future<ValidationResult> validateAllAssets() async {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    final info = <ValidationError>[];
    
    // 1. Basic sequence file validation
    final sequenceResult = await validateAllSequenceFiles();
    errors.addAll(sequenceResult.errors);
    warnings.addAll(sequenceResult.warnings);
    info.addAll(sequenceResult.info);
    
    // 2. Template variable validation
    final templateIssues = await _templateVariableValidator.validateTemplateVariables();
    warnings.addAll(templateIssues);
    
    // 3. Template syntax validation
    final syntaxIssues = await _templateVariableValidator.validateTemplateVariableSyntax();
    warnings.addAll(syntaxIssues);
    
    // 4. Cross-reference accessibility validation
    final accessibilityIssues = await _crossReferenceValidator.validateSequenceAccessibility();
    errors.addAll(accessibilityIssues.where((e) => e.severity == 'error'));
    warnings.addAll(accessibilityIssues.where((e) => e.severity == 'warning'));
    
    // 5. Variant content validation
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _sequenceFileValidator.loadSequence(sequenceId);
      if (sequence != null) {
        final variantContentIssues = await _variantFileValidator.validateVariantContent(sequence);
        warnings.addAll(variantContentIssues);
      }
    }
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }
}