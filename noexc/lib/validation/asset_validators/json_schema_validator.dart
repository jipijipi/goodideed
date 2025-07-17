import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/validation_models.dart';

/// Validates JSON schema structure and format
class JsonSchemaValidator {
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
            if (!['bot', 'user', 'choice', 'textInput', 'autoroute', 'dataAction'].contains(messageType)) {
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
          
          if (messageType == 'dataAction') {
            if (!messageMap.containsKey('action')) {
              errors.add(ValidationError(
                type: 'MISSING_DATA_ACTION',
                message: 'DataAction message must have "action" field',
                messageId: messageMap['id'] as int?,
                sequenceId: sequenceId,
              ));
            }
          }
        }
      }
      
      // Validate optional fields
      _validateOptionalFields(jsonData, sequenceId, warnings);
      
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
  
  /// Validates optional fields for best practices
  void _validateOptionalFields(Map<String, dynamic> jsonData, String sequenceId, List<ValidationError> warnings) {
    // Check for name field
    if (!jsonData.containsKey('name') || jsonData['name'] == null || jsonData['name'].toString().isEmpty) {
      warnings.add(ValidationError(
        type: 'MISSING_SEQUENCE_NAME',
        message: 'Sequence should have a descriptive "name" field',
        sequenceId: sequenceId,
        severity: 'warning',
      ));
    }
    
    // Check for description field
    if (!jsonData.containsKey('description') || jsonData['description'] == null || jsonData['description'].toString().isEmpty) {
      warnings.add(ValidationError(
        type: 'MISSING_SEQUENCE_DESCRIPTION',
        message: 'Sequence should have a "description" field',
        sequenceId: sequenceId,
        severity: 'warning',
      ));
    }
  }
}