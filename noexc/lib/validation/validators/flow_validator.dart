/// Validates conversation flow, detects dead ends, unreachable messages, and circular references
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class FlowValidator {
  /// Validates conversation flow and detects dead ends/unreachable messages
  List<ValidationError> validate(ChatSequence sequence) {
    final issues = <ValidationError>[];

    // Find starting message (usually ID 1 or lowest ID)
    if (sequence.messages.isEmpty) return issues;

    final startingMessage = sequence.messages.reduce(
      (a, b) => a.id < b.id ? a : b,
    );

    // Perform flow analysis
    final reachableMessages = _findReachableMessages(
      sequence,
      startingMessage.id,
    );
    final deadEnds = _findDeadEnds(sequence);
    final unreachableMessages = _findUnreachableMessages(
      sequence,
      reachableMessages,
    );

    // Report unreachable messages
    for (final messageId in unreachableMessages) {
      issues.add(
        ValidationError(
          type: ValidationConstants.unreachableMessage,
          message: 'Message cannot be reached from sequence start',
          messageId: messageId,
          sequenceId: sequence.sequenceId,
          severity: ValidationConstants.severityWarning,
        ),
      );
    }

    // Report dead ends
    for (final messageId in deadEnds) {
      final message = sequence.getMessageById(messageId);
      if (message != null && !_isValidEndpoint(message)) {
        issues.add(
          ValidationError(
            type: ValidationConstants.deadEnd,
            message: 'Message has no continuation (dead end)',
            messageId: messageId,
            sequenceId: sequence.sequenceId,
            severity: ValidationConstants.severityError,
          ),
        );
      }
    }

    // Check for circular references
    final circularPaths = _findCircularReferences(sequence);
    for (final path in circularPaths) {
      issues.add(
        ValidationError(
          type: ValidationConstants.circularReference,
          message: 'Circular reference detected: ${path.join(' -> ')}',
          sequenceId: sequence.sequenceId,
          severity: ValidationConstants.severityWarning,
        ),
      );
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
  List<int> _findUnreachableMessages(
    ChatSequence sequence,
    Set<int> reachableMessages,
  ) {
    final allMessageIds = sequence.messages.map((m) => m.id).toSet();
    return allMessageIds.difference(reachableMessages).toList();
  }

  /// Finds circular references in the sequence
  List<List<int>> _findCircularReferences(ChatSequence sequence) {
    final circularPaths = <List<int>>[];
    final visited = <int>{};
    final path = <int>[];

    for (final message in sequence.messages) {
      if (!visited.contains(message.id)) {
        _dfsCircularCheck(sequence, message.id, visited, path, circularPaths);
      }
    }

    return circularPaths;
  }

  /// Depth-first search for circular references
  void _dfsCircularCheck(
    ChatSequence sequence,
    int messageId,
    Set<int> visited,
    List<int> path,
    List<List<int>> circularPaths,
  ) {
    if (path.contains(messageId)) {
      // Found a cycle
      final cycleStart = path.indexOf(messageId);
      final cycle = path.sublist(cycleStart)..add(messageId);
      circularPaths.add(List.from(cycle));
      return;
    }

    if (visited.contains(messageId)) return;

    visited.add(messageId);
    path.add(messageId);

    final message = sequence.getMessageById(messageId);
    if (message != null) {
      // Check next message
      if (message.nextMessageId != null) {
        _dfsCircularCheck(
          sequence,
          message.nextMessageId!,
          visited,
          path,
          circularPaths,
        );
      }

      // Check choice destinations
      if (message.choices != null) {
        for (final choice in message.choices!) {
          if (choice.nextMessageId != null) {
            _dfsCircularCheck(
              sequence,
              choice.nextMessageId!,
              visited,
              path,
              circularPaths,
            );
          }
        }
      }

      // Check route destinations
      if (message.routes != null) {
        for (final route in message.routes!) {
          if (route.nextMessageId != null) {
            _dfsCircularCheck(
              sequence,
              route.nextMessageId!,
              visited,
              path,
              circularPaths,
            );
          }
        }
      }
    }

    path.removeLast();
  }
}
