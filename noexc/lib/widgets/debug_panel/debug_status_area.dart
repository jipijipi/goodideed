import 'package:flutter/material.dart';

/// Status message model for tracking recent debug panel actions
class StatusMessage {
  final String message;
  final StatusType type;
  final DateTime timestamp;
  final String? key;

  StatusMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    this.key,
  });
}

/// Types of status messages with associated styling
enum StatusType {
  success,
  error,
  info,
}

/// Compact status area widget for showing recent debug panel actions
class DebugStatusArea extends StatefulWidget {
  final DebugStatusController? controller;
  final List<StatusMessage>? messages; // For backward compatibility
  final int maxMessages;
  final Duration messageDuration;

  const DebugStatusArea({
    super.key,
    this.controller,
    this.messages,
    this.maxMessages = 3,
    this.messageDuration = const Duration(seconds: 4),
  });

  @override
  State<DebugStatusArea> createState() => _DebugStatusAreaState();
}

class _DebugStatusAreaState extends State<DebugStatusArea> {
  
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    _startMessageCleanup();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with updated messages
      });
    }
  }

  List<StatusMessage> get _currentMessages {
    if (widget.controller != null) {
      return widget.controller!.messages;
    } else if (widget.messages != null) {
      return widget.messages!;
    }
    return [];
  }

  void _startMessageCleanup() {
    // Clean up old messages periodically
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _cleanupOldMessages();
        _startMessageCleanup();
      }
    });
  }

  void _cleanupOldMessages() {
    final now = DateTime.now();
    final messages = _currentMessages;
    final oldMessages = <StatusMessage>[];
    
    for (final message in messages) {
      if (now.difference(message.timestamp) > widget.messageDuration) {
        oldMessages.add(message);
      }
    }
    
    // Remove old messages through the controller if available
    if (widget.controller != null) {
      for (final message in oldMessages) {
        widget.controller!.removeMessage(message);
      }
    } else if (widget.messages != null) {
      // Fallback for backward compatibility
      widget.messages!.removeWhere((message) {
        return now.difference(message.timestamp) > widget.messageDuration;
      });
      
      // Keep only the most recent messages
      if (widget.messages!.length > widget.maxMessages) {
        widget.messages!.removeRange(0, widget.messages!.length - widget.maxMessages);
      }
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  Color _getStatusColor(StatusType type, BuildContext context) {
    switch (type) {
      case StatusType.success:
        return Theme.of(context).colorScheme.primary;
      case StatusType.error:
        return Theme.of(context).colorScheme.error;
      case StatusType.info:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Icons.check_circle_outline;
      case StatusType.error:
        return Icons.error_outline;
      case StatusType.info:
        return Icons.info_outline;
    }
  }

  Widget _buildStatusMessage(StatusMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(message.type, context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getStatusColor(message.type, context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(message.type),
            size: 14,
            color: _getStatusColor(message.type, context),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(message.type, context),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _currentMessages;
    
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Recent Actions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...messages
              .reversed
              .take(widget.maxMessages)
              .map((message) => _buildStatusMessage(message)),
        ],
      ),
    );
  }
}

/// Controller for managing debug panel status messages across multiple widgets
class DebugStatusController extends ChangeNotifier {
  final List<StatusMessage> _messages = [];

  List<StatusMessage> get messages => List.unmodifiable(_messages);

  void addMessage(String message, StatusType type, {String? key}) {
    _messages.add(StatusMessage(
      message: message,
      type: type,
      timestamp: DateTime.now(),
      key: key,
    ));
    notifyListeners();
  }

  void addSuccess(String message, {String? key}) {
    addMessage(message, StatusType.success, key: key);
  }

  void addError(String message, {String? key}) {
    addMessage(message, StatusType.error, key: key);
  }

  void addInfo(String message, {String? key}) {
    addMessage(message, StatusType.info, key: key);
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void removeMessage(StatusMessage message) {
    _messages.remove(message);
    notifyListeners();
  }
}

/// Mixin to provide status message functionality to widgets
mixin DebugStatusMixin<T extends StatefulWidget> on State<T> {
  final List<StatusMessage> _statusMessages = [];

  List<StatusMessage> get statusMessages => _statusMessages;

  void addStatusMessage(String message, StatusType type, {String? key}) {
    setState(() {
      _statusMessages.add(StatusMessage(
        message: message,
        type: type,
        timestamp: DateTime.now(),
        key: key,
      ));
    });
  }

  void addSuccessMessage(String message, {String? key}) {
    addStatusMessage(message, StatusType.success, key: key);
  }

  void addErrorMessage(String message, {String? key}) {
    addStatusMessage(message, StatusType.error, key: key);
  }

  void addInfoMessage(String message, {String? key}) {
    addStatusMessage(message, StatusType.info, key: key);
  }
}