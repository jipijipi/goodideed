import 'dart:async';
import 'dart:collection';
import '../models/chat_message.dart';
import 'message_delay_policy.dart';

/// A message processing queue that handles message display with delays and prevents race conditions
class MessageQueue {
  final Queue<MessageBatch> _queue = Queue();
  bool _isProcessing = false;
  bool _disposed = false;
  final List<Timer> _activeTimers = [];
  final MessageDelayPolicy _delayPolicy;

  MessageQueue({MessageDelayPolicy? delayPolicy})
    : _delayPolicy = delayPolicy ?? MessageDelayPolicy();

  /// Enqueue a batch of messages for processing
  Future<void> enqueue(
    List<ChatMessage> messages,
    Future<void> Function(ChatMessage) onDisplay,
  ) async {
    if (_disposed || messages.isEmpty) return;

    _queue.add(MessageBatch(messages, onDisplay));

    // Start processing if not already processing
    if (!_isProcessing) {
      await _processQueue();
    }
  }

  /// Process all queued message batches
  Future<void> _processQueue() async {
    if (_disposed || _isProcessing) return;

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && !_disposed) {
        final batch = _queue.removeFirst();
        await _processBatch(batch);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single batch of messages
  Future<void> _processBatch(MessageBatch batch) async {
    for (final message in batch.messages) {
      if (_disposed) break;

      // Apply effective delay per policy
      final effective = _delayPolicy.effectiveDelay(message);
      if (effective > 0) {
        final completer = Completer<void>();
        final timer = Timer(Duration(milliseconds: effective), () {
          completer.complete();
        });
        _activeTimers.add(timer);
        await completer.future;
        _activeTimers.remove(timer);
      }

      if (_disposed) break;

      // Display the message
      await batch.onDisplay(message);
    }
  }

  /// Dispose the queue and cancel any pending processing
  void dispose() {
    _disposed = true;
    _queue.clear();

    // Cancel all active timers
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }
}

/// A batch of messages to be processed together
class MessageBatch {
  final List<ChatMessage> messages;
  final Future<void> Function(ChatMessage) onDisplay;

  MessageBatch(this.messages, this.onDisplay);
}
