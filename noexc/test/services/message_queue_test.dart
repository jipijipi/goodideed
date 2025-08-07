import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/message_queue.dart';
import 'package:noexc/models/chat_message.dart';

void main() {
  group('MessageQueue', () {
    late MessageQueue messageQueue;
    
    setUp(() {
      messageQueue = MessageQueue();
    });

    test('should process messages in order', () async {
      // Arrange
      final List<String> processedMessages = [];
      final messages = [
        ChatMessage(id: 1, text: 'First message', delay: 0),
        ChatMessage(id: 2, text: 'Second message', delay: 0),
        ChatMessage(id: 3, text: 'Third message', delay: 0),
      ];

      // Act
      await messageQueue.enqueue(messages, (message) async {
        processedMessages.add(message.text);
      });

      // Assert
      expect(processedMessages, ['First message', 'Second message', 'Third message']);
    });

    test('should handle concurrent enqueue calls without race conditions', () async {
      // Arrange
      final List<String> processedMessages = [];
      final firstBatch = [
        ChatMessage(id: 1, text: 'Batch 1 - Message 1', delay: 0),
        ChatMessage(id: 2, text: 'Batch 1 - Message 2', delay: 0),
      ];
      final secondBatch = [
        ChatMessage(id: 3, text: 'Batch 2 - Message 1', delay: 0),
        ChatMessage(id: 4, text: 'Batch 2 - Message 2', delay: 0),
      ];

      // Act - Enqueue both batches concurrently
      final futures = <Future<void>>[
        messageQueue.enqueue(firstBatch, (message) async {
          processedMessages.add(message.text);
        }),
        messageQueue.enqueue(secondBatch, (message) async {
          processedMessages.add(message.text);
        }),
      ];
      
      await Future.wait(futures);

      // Assert - All messages should be processed without duplication
      expect(processedMessages.length, 4);
      expect(processedMessages, containsAll([
        'Batch 1 - Message 1',
        'Batch 1 - Message 2', 
        'Batch 2 - Message 1',
        'Batch 2 - Message 2'
      ]));
    });

    test('should respect message delays', () async {
      // Arrange
      final List<String> processedMessages = [];
      final stopwatch = Stopwatch()..start();
      final messages = [
        ChatMessage(id: 1, text: 'Immediate message', delay: 0),
        ChatMessage(id: 2, text: 'Delayed message', delay: 100),
      ];

      // Act
      await messageQueue.enqueue(messages, (message) async {
        processedMessages.add('${message.text} at ${stopwatch.elapsedMilliseconds}ms');
      });

      // Assert - Second message should be delayed
      expect(processedMessages.length, 2);
      expect(processedMessages[0], contains('Immediate message at'));
      expect(processedMessages[1], contains('Delayed message at'));
      
      // Extract timing values to verify delay
      final firstTime = int.parse(processedMessages[0].split(' at ')[1].split('ms')[0]);
      final secondTime = int.parse(processedMessages[1].split(' at ')[1].split('ms')[0]);
      expect(secondTime - firstTime, greaterThanOrEqualTo(90)); // Allow some tolerance
    });

    test('should handle empty message batches', () async {
      // Arrange
      final List<String> processedMessages = [];
      final emptyBatch = <ChatMessage>[];

      // Act
      await messageQueue.enqueue(emptyBatch, (message) async {
        processedMessages.add(message.text);
      });

      // Assert
      expect(processedMessages, isEmpty);
    });

    test('should handle disposal during processing', () async {
      // Arrange
      final List<String> processedMessages = [];
      final messages = [
        ChatMessage(id: 1, text: 'Message 1', delay: 0),
        ChatMessage(id: 2, text: 'Message 2', delay: 100),
        ChatMessage(id: 3, text: 'Message 3', delay: 0),
      ];

      // Act - Start processing and dispose during delay
      final processingFuture = messageQueue.enqueue(messages, (message) async {
        processedMessages.add(message.text);
      });
      
      // Dispose after first message but before delay completes
      await Future.delayed(const Duration(milliseconds: 50));
      messageQueue.dispose();
      
      // Wait for processing to complete or timeout
      try {
        await processingFuture.timeout(const Duration(seconds: 1));
      } catch (e) {
        // Timeout is expected if disposal interrupts processing
      }

      // Assert - Should handle disposal gracefully
      expect(processedMessages.length, lessThanOrEqualTo(2));
    });
  });
}
