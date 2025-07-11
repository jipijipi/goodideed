import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/chat_sequence.dart';
import '../models/chat_message.dart';
import '../constants/app_constants.dart';
import 'sequence_validator.dart';

/// Validates assets and file integrity
class AssetValidator {
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
        final sequence = await _loadSequence(sequenceId);
        if (sequence != null) {
          final validator = SequenceValidator();
          final result = validator.validateSequence(sequence);
          
          errors.addAll(result.errors);
          warnings.addAll(result.warnings);
          info.addAll(result.info);
          
          // Validate associated variant files
          final variantIssues = await _validateVariantFiles(sequence);
          warnings.addAll(variantIssues);
        }
      } catch (e) {
        errors.add(ValidationError(
          type: 'SEQUENCE_LOAD_ERROR',
          message: 'Failed to load sequence: $e',
          sequenceId: sequenceId,
        ));
      }
    }
    
    // Validate cross-sequence references
    final crossRefIssues = await _validateCrossSequenceReferences();
    errors.addAll(crossRefIssues);
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }
  
  /// Loads a sequence from assets
  Future<ChatSequence?> _loadSequence(String sequenceId) async {
    try {
      final assetPath = 'assets/sequences/$sequenceId.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      return ChatSequence.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }
  
  /// Validates that variant files exist for sequences
  Future<List<ValidationError>> _validateVariantFiles(ChatSequence sequence) async {
    final warnings = <ValidationError>[];
    
    for (final message in sequence.messages) {
      // Only check for variants on bot messages (not choice, textInput, or autoroute)
      if (message.type == MessageType.bot && message.text.isNotEmpty) {
        final variantPath = 'assets/variants/${sequence.sequenceId}_message_${message.id}.txt';
        
        try {
          await rootBundle.loadString(variantPath);
          // File exists, no issue
        } catch (e) {
          // File doesn't exist, but this is just a warning since variants are optional
          warnings.add(ValidationError(
            type: 'MISSING_VARIANT_FILE',
            message: 'No variant file found at: $variantPath',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
            severity: 'info',
          ));
        }
      }
    }
    
    return warnings;
  }
  
  /// Validates cross-sequence references
  Future<List<ValidationError>> _validateCrossSequenceReferences() async {
    final errors = <ValidationError>[];
    final availableSequences = AppConstants.availableSequences.toSet();
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _loadSequence(sequenceId);
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
  
  /// Validates JSON schema structure
  Future<ValidationResult> validateJsonSchema(String sequenceId) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    
    try {
      final assetPath = 'assets/sequences/$sequenceId.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      
      // Basic JSON structure validation
      if (!jsonData.containsKey('sequenceId')) {
        errors.add(ValidationError(
          type: 'MISSING_FIELD',
          message: 'Required field "sequenceId" is missing',
          sequenceId: sequenceId,
        ));
      }
      
      if (!jsonData.containsKey('messages')) {
        errors.add(ValidationError(
          type: 'MISSING_FIELD',
          message: 'Required field "messages" is missing',
          sequenceId: sequenceId,
        ));
      } else if (jsonData['messages'] is! List) {
        errors.add(ValidationError(
          type: 'INVALID_FIELD_TYPE',
          message: 'Field "messages" must be an array',
          sequenceId: sequenceId,
        ));
      }
      
      // Validate each message structure
      if (jsonData['messages'] is List) {
        final messages = jsonData['messages'] as List;
        for (int i = 0; i < messages.length; i++) {
          final messageData = messages[i];
          if (messageData is! Map) {
            errors.add(ValidationError(
              type: 'INVALID_MESSAGE_STRUCTURE',
              message: 'Message at index $i is not a valid object',
              sequenceId: sequenceId,
            ));
            continue;
          }
          
          final messageMap = messageData as Map<String, dynamic>;
          
          // Check required fields
          if (!messageMap.containsKey('id')) {
            errors.add(ValidationError(
              type: 'MISSING_MESSAGE_ID',
              message: 'Message at index $i is missing required "id" field',
              sequenceId: sequenceId,
            ));
          }
          
          // Validate message type consistency
          final messageType = messageMap['type'] as String?;
          if (messageType != null) {
            if (!['bot', 'user', 'choice', 'textInput', 'autoroute'].contains(messageType)) {
              errors.add(ValidationError(
                type: 'INVALID_MESSAGE_TYPE',
                message: 'Invalid message type: $messageType',
                messageId: messageMap['id'] as int?,
                sequenceId: sequenceId,
              ));
            }
          }
          
          // Validate type-specific requirements
          if (messageType == 'choice') {
            if (!messageMap.containsKey('choices') || messageMap['choices'] is! List) {
              errors.add(ValidationError(
                type: 'MISSING_CHOICES',
                message: 'Choice message must have "choices" array',
                messageId: messageMap['id'] as int?,
                sequenceId: sequenceId,
              ));
            }
          }
          
          if (messageType == 'autoroute') {
            if (!messageMap.containsKey('routes') || messageMap['routes'] is! List) {
              errors.add(ValidationError(
                type: 'MISSING_ROUTES',
                message: 'Autoroute message must have "routes" array',
                messageId: messageMap['id'] as int?,
                sequenceId: sequenceId,
              ));
            }
          }
          
          if (messageType == 'textInput') {
            if (!messageMap.containsKey('storeKey')) {
              warnings.add(ValidationError(
                type: 'MISSING_STORE_KEY',
                message: 'TextInput message should have "storeKey" for data storage',
                messageId: messageMap['id'] as int?,
                sequenceId: sequenceId,
                severity: 'warning',
              ));
            }
          }
        }
      }
      
    } catch (e) {
      errors.add(ValidationError(
        type: 'JSON_PARSE_ERROR',
        message: 'Failed to parse JSON: $e',
        sequenceId: sequenceId,
      ));
    }
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: [],
    );
  }
  
  /// Validates template variable consistency across sequences
  Future<List<ValidationError>> validateTemplateVariables() async {
    final warnings = <ValidationError>[];
    final allVariables = <String, Set<String>>{}; // variable -> sequences using it
    
    for (final sequenceId in AppConstants.availableSequences) {
      final sequence = await _loadSequence(sequenceId);
      if (sequence == null) continue;
      
      for (final message in sequence.messages) {
        // Extract template variables from message text
        final variables = _extractTemplateVariables(message.text);
        for (final variable in variables) {
          allVariables.putIfAbsent(variable, () => <String>{}).add(sequenceId);
        }
        
        // Check placeholder text for variables
        if (message.placeholderText.isNotEmpty) {
          final placeholderVars = _extractTemplateVariables(message.placeholderText);
          for (final variable in placeholderVars) {
            allVariables.putIfAbsent(variable, () => <String>{}).add(sequenceId);
          }
        }
      }
    }
    
    // Report variables used in multiple sequences (for consistency awareness)
    for (final entry in allVariables.entries) {
      if (entry.value.length > 1) {
        warnings.add(ValidationError(
          type: 'SHARED_TEMPLATE_VARIABLE',
          message: 'Template variable "${entry.key}" is used in multiple sequences: ${entry.value.join(', ')}',
          severity: 'info',
        ));
      }
    }
    
    return warnings;
  }
  
  /// Extracts template variables from text
  Set<String> _extractTemplateVariables(String text) {
    final variables = <String>{};
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final fullMatch = match.group(1)!;
      // Extract variable name (before | if fallback syntax is used)
      final variable = fullMatch.split('|').first.trim();
      variables.add(variable);
    }
    
    return variables;
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
        info.add(ValidationError(
          type: 'ASSET_FILE_OK',
          message: 'Sequence file accessible: $assetPath',
          sequenceId: sequenceId,
          severity: 'info',
        ));
      } catch (e) {
        errors.add(ValidationError(
          type: 'ASSET_FILE_ERROR',
          message: 'Cannot access sequence file: $assetPath ($e)',
          sequenceId: sequenceId,
        ));
      }
    }
    
    return ValidationResult(
      errors: errors,
      warnings: [],
      info: info,
    );
  }
}