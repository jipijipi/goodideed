import '../models/chat_sequence.dart';
import '../models/chat_message.dart';
import '../models/choice.dart';
import '../models/route_condition.dart';

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
    this.severity = 'error',
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
    buffer.writeln('Validation Result:');
    buffer.writeln('  Errors: ${errors.length}');
    buffer.writeln('  Warnings: ${warnings.length}');
    buffer.writeln('  Info: ${info.length}');
    
    if (allIssues.isNotEmpty) {
      buffer.writeln('\nIssues:');
      for (final issue in allIssues) {
        buffer.writeln('  $issue');
      }
    }
    
    return buffer.toString();
  }
}

/// Validates chat sequence structure and integrity
class SequenceValidator {
  /// Validates a complete chat sequence
  ValidationResult validateSequence(ChatSequence sequence) {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    final info = <ValidationError>[];
    
    // Basic structure validation
    errors.addAll(_validateBasicStructure(sequence));
    
    // Message reference validation
    errors.addAll(_validateMessageReferences(sequence));
    
    // Flow analysis
    final flowIssues = _validateFlow(sequence);
    errors.addAll(flowIssues.where((e) => e.severity == 'error'));
    warnings.addAll(flowIssues.where((e) => e.severity == 'warning'));
    info.addAll(flowIssues.where((e) => e.severity == 'info'));
    
    // Choice validation
    errors.addAll(_validateChoices(sequence));
    
    // Route condition validation
    errors.addAll(_validateRouteConditions(sequence));
    
    // Template validation
    warnings.addAll(_validateTemplates(sequence));
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }
  
  /// Validates basic sequence structure
  List<ValidationError> _validateBasicStructure(ChatSequence sequence) {
    final errors = <ValidationError>[];
    
    // Check sequence has required fields
    if (sequence.sequenceId.isEmpty) {
      errors.add(ValidationError(
        type: 'MISSING_SEQUENCE_ID',
        message: 'Sequence ID is required',
        sequenceId: sequence.sequenceId,
      ));
    }
    
    if (sequence.name.isEmpty) {
      errors.add(ValidationError(
        type: 'MISSING_SEQUENCE_NAME',
        message: 'Sequence name is required',
        sequenceId: sequence.sequenceId,
      ));
    }
    
    if (sequence.messages.isEmpty) {
      errors.add(ValidationError(
        type: 'EMPTY_SEQUENCE',
        message: 'Sequence must contain at least one message',
        sequenceId: sequence.sequenceId,
      ));
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
      errors.add(ValidationError(
        type: 'DUPLICATE_MESSAGE_IDS',
        message: 'Duplicate message IDs found: ${duplicates.join(', ')}',
        sequenceId: sequence.sequenceId,
      ));
    }
    
    return errors;
  }
  
  /// Validates message references and links
  List<ValidationError> _validateMessageReferences(ChatSequence sequence) {
    final errors = <ValidationError>[];
    final messageIds = sequence.messages.map((m) => m.id).toSet();
    
    for (final message in sequence.messages) {
      // Check nextMessageId references
      if (message.nextMessageId != null) {
        if (!messageIds.contains(message.nextMessageId)) {
          errors.add(ValidationError(
            type: 'INVALID_NEXT_MESSAGE_ID',
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
              type: 'INVALID_CHOICE_NEXT_MESSAGE_ID',
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
              type: 'INVALID_ROUTE_NEXT_MESSAGE_ID',
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
  
  /// Validates conversation flow and detects dead ends/unreachable messages
  List<ValidationError> _validateFlow(ChatSequence sequence) {
    final issues = <ValidationError>[];
    
    // Find starting message (usually ID 1 or lowest ID)
    if (sequence.messages.isEmpty) return issues;
    
    final startingMessage = sequence.messages.reduce((a, b) => a.id < b.id ? a : b);
    
    // Perform flow analysis
    final reachableMessages = _findReachableMessages(sequence, startingMessage.id);
    final deadEnds = _findDeadEnds(sequence);
    final unreachableMessages = _findUnreachableMessages(sequence, reachableMessages);
    
    // Report unreachable messages
    for (final messageId in unreachableMessages) {
      issues.add(ValidationError(
        type: 'UNREACHABLE_MESSAGE',
        message: 'Message cannot be reached from sequence start',
        messageId: messageId,
        sequenceId: sequence.sequenceId,
        severity: 'warning',
      ));
    }
    
    // Report dead ends
    for (final messageId in deadEnds) {
      final message = sequence.getMessageById(messageId);
      if (message != null && !_isValidEndpoint(message)) {
        issues.add(ValidationError(
          type: 'DEAD_END',
          message: 'Message has no continuation (dead end)',
          messageId: messageId,
          sequenceId: sequence.sequenceId,
          severity: 'error',
        ));
      }
    }
    
    // Check for circular references
    final circularPaths = _findCircularReferences(sequence);
    for (final path in circularPaths) {
      issues.add(ValidationError(
        type: 'CIRCULAR_REFERENCE',
        message: 'Circular reference detected: ${path.join(' -> ')}',
        sequenceId: sequence.sequenceId,
        severity: 'warning',
      ));
    }
    
    return issues;
  }
  
  /// Finds all messages reachable from a starting message
  Set<int> _findReachableMessages(ChatSequence sequence, int startId) {
    final reachable = <int>{};
    final toVisit = <int>[startId];
    
    while (toVisit.isNotEmpty) {
      final currentId = toVisit.removeAt(0);
      if (reachable.contains(currentId)) continue;
      
      reachable.add(currentId);
      final message = sequence.getMessageById(currentId);
      if (message == null) continue;
      
      // Add next message
      if (message.nextMessageId != null) {
        toVisit.add(message.nextMessageId!);
      }
      
      // Add choice destinations
      if (message.choices != null) {
        for (final choice in message.choices!) {
          if (choice.nextMessageId != null) {
            toVisit.add(choice.nextMessageId!);
          }
        }
      }
      
      // Add route destinations
      if (message.routes != null) {
        for (final route in message.routes!) {
          if (route.nextMessageId != null) {
            toVisit.add(route.nextMessageId!);
          }
        }
      }
    }
    
    return reachable;
  }
  
  /// Finds messages that have no continuation
  List<int> _findDeadEnds(ChatSequence sequence) {
    final deadEnds = <int>[];
    
    for (final message in sequence.messages) {
      if (_isDeadEnd(message)) {
        deadEnds.add(message.id);
      }
    }
    
    return deadEnds;
  }
  
  /// Checks if a message is a dead end
  bool _isDeadEnd(ChatMessage message) {
    // Has explicit next message
    if (message.nextMessageId != null) return false;
    
    // Has choices with destinations
    if (message.choices != null && message.choices!.isNotEmpty) {
      for (final choice in message.choices!) {
        if (choice.nextMessageId != null || choice.sequenceId != null) {
          return false;
        }
      }
    }
    
    // Has routes with destinations
    if (message.routes != null && message.routes!.isNotEmpty) {
      for (final route in message.routes!) {
        if (route.nextMessageId != null || route.sequenceId != null) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Checks if a message is a valid endpoint (intentional end)
  bool _isValidEndpoint(ChatMessage message) {
    // Check if message has cross-sequence navigation
    if (message.choices != null) {
      for (final choice in message.choices!) {
        if (choice.sequenceId != null) return true;
      }
    }
    
    if (message.routes != null) {
      for (final route in message.routes!) {
        if (route.sequenceId != null) return true;
      }
    }
    
    // Could add more sophisticated endpoint detection
    return false;
  }
  
  /// Finds messages that cannot be reached from sequence start
  List<int> _findUnreachableMessages(ChatSequence sequence, Set<int> reachableMessages) {
    final allMessageIds = sequence.messages.map((m) => m.id).toSet();
    return allMessageIds.difference(reachableMessages).toList();
  }
  
  /// Finds circular reference paths
  List<List<int>> _findCircularReferences(ChatSequence sequence) {
    final circularPaths = <List<int>>[];
    final visited = <int>{};
    final recursionStack = <int>{};
    
    for (final message in sequence.messages) {
      if (!visited.contains(message.id)) {
        final path = <int>[];
        _dfsCircularCheck(sequence, message.id, visited, recursionStack, path, circularPaths);
      }
    }
    
    return circularPaths;
  }
  
  /// Depth-first search for circular references
  void _dfsCircularCheck(
    ChatSequence sequence,
    int messageId,
    Set<int> visited,
    Set<int> recursionStack,
    List<int> path,
    List<List<int>> circularPaths,
  ) {
    visited.add(messageId);
    recursionStack.add(messageId);
    path.add(messageId);
    
    final message = sequence.getMessageById(messageId);
    if (message == null) return;
    
    final nextIds = <int>[];
    
    // Collect all possible next message IDs
    if (message.nextMessageId != null) {
      nextIds.add(message.nextMessageId!);
    }
    
    if (message.choices != null) {
      for (final choice in message.choices!) {
        if (choice.nextMessageId != null) {
          nextIds.add(choice.nextMessageId!);
        }
      }
    }
    
    if (message.routes != null) {
      for (final route in message.routes!) {
        if (route.nextMessageId != null) {
          nextIds.add(route.nextMessageId!);
        }
      }
    }
    
    // Check each next message
    for (final nextId in nextIds) {
      if (recursionStack.contains(nextId)) {
        // Found circular reference
        final cycleStart = path.indexOf(nextId);
        if (cycleStart != -1) {
          circularPaths.add([...path.sublist(cycleStart), nextId]);
        }
      } else if (!visited.contains(nextId)) {
        _dfsCircularCheck(sequence, nextId, visited, recursionStack, path, circularPaths);
      }
    }
    
    recursionStack.remove(messageId);
    path.removeLast();
  }
  
  /// Validates choice configurations
  List<ValidationError> _validateChoices(ChatSequence sequence) {
    final errors = <ValidationError>[];
    
    for (final message in sequence.messages) {
      if (message.type == MessageType.choice) {
        if (message.choices == null || message.choices!.isEmpty) {
          errors.add(ValidationError(
            type: 'MISSING_CHOICES',
            message: 'Choice message must have at least one choice option',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
          ));
        } else {
          // Check each choice has either nextMessageId or sequenceId
          for (int i = 0; i < message.choices!.length; i++) {
            final choice = message.choices![i];
            if (choice.nextMessageId == null && choice.sequenceId == null) {
              errors.add(ValidationError(
                type: 'CHOICE_NO_DESTINATION',
                message: 'Choice "${choice.text}" has no destination (nextMessageId or sequenceId)',
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
  
  /// Validates route conditions
  List<ValidationError> _validateRouteConditions(ChatSequence sequence) {
    final errors = <ValidationError>[];
    
    for (final message in sequence.messages) {
      if (message.type == MessageType.autoroute) {
        if (message.routes == null || message.routes!.isEmpty) {
          errors.add(ValidationError(
            type: 'MISSING_ROUTES',
            message: 'Autoroute message must have at least one route',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
          ));
        } else {
          // Check for default route
          final hasDefault = message.routes!.any((route) => route.isDefault);
          if (!hasDefault) {
            errors.add(ValidationError(
              type: 'MISSING_DEFAULT_ROUTE',
              message: 'Autoroute message must have a default route',
              messageId: message.id,
              sequenceId: sequence.sequenceId,
            ));
          }
          
          // Check each route has destination
          for (final route in message.routes!) {
            if (route.nextMessageId == null && route.sequenceId == null) {
              errors.add(ValidationError(
                type: 'ROUTE_NO_DESTINATION',
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
  
  /// Validates template syntax (basic validation)
  List<ValidationError> _validateTemplates(ChatSequence sequence) {
    final warnings = <ValidationError>[];
    
    for (final message in sequence.messages) {
      if (message.text.isNotEmpty) {
        // Check for unclosed template brackets
        final openBrackets = message.text.split('{').length - 1;
        final closeBrackets = message.text.split('}').length - 1;
        
        if (openBrackets != closeBrackets) {
          warnings.add(ValidationError(
            type: 'TEMPLATE_SYNTAX_WARNING',
            message: 'Mismatched template brackets in message text',
            messageId: message.id,
            sequenceId: sequence.sequenceId,
            severity: 'warning',
          ));
        }
      }
    }
    
    return warnings;
  }
}