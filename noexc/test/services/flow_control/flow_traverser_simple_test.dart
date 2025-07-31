import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/flow_control/flow_traverser.dart';
import 'package:noexc/services/chat_service/sequence_loader.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/traversal_result.dart';

import '../../test_helpers.dart';

/// Simple test implementation of SequenceLoader for testing
class TestSequenceLoader extends SequenceLoader {
  final Map<int, ChatMessage> _messages = {};
  
  void addMessage(ChatMessage message) {
    _messages[message.id] = message;
  }
  
  @override
  bool hasMessage(int id) {
    return _messages.containsKey(id);
  }
  
  @override
  ChatMessage? getMessageById(int id) {
    return _messages[id];
  }
}

void main() {
  group('FlowTraverser - Core Functionality', () {
    late FlowTraverser flowTraverser;
    late TestSequenceLoader testSequenceLoader;

    setUp(() {
      setupQuietTesting();
      flowTraverser = FlowTraverser();
      testSequenceLoader = TestSequenceLoader();
    });

    test('should return empty result when starting message does not exist', () {
      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, isEmpty);
      expect(result.stopReason, equals(TraversalStopReason.endOfSequence));
      expect(result.isSuccess, isTrue);
    });

    test('should collect single bot message', () {
      // Arrange
      final message = ChatMessage(id: 1, text: 'Hello');
      testSequenceLoader.addMessage(message);

      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, hasLength(1));
      expect(result.messages.first.id, equals(1));
      expect(result.stopReason, equals(TraversalStopReason.endOfSequence));
      expect(result.isSuccess, isTrue);
    });

    test('should stop at choice message', () {
      // Arrange
      final choiceMessage = ChatMessage(
        id: 1,
        text: '',
        type: MessageType.choice,
      );
      testSequenceLoader.addMessage(choiceMessage);

      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, hasLength(1));
      expect(result.messages.first.id, equals(1));
      expect(result.stopReason, equals(TraversalStopReason.interactiveMessage));
      expect(result.hasUserInteraction, isTrue);
    });

    test('should handle sequence transition', () {
      // Arrange
      final transitionMessage = ChatMessage(
        id: 1,
        text: 'Transitioning',
        sequenceId: 'target_seq',
      );
      testSequenceLoader.addMessage(transitionMessage);

      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, hasLength(1));
      expect(result.messages.first.id, equals(1));
      expect(result.stopReason, equals(TraversalStopReason.sequenceTransition));
      expect(result.targetSequenceId, equals('target_seq'));
      expect(result.requiresSequenceTransition, isTrue);
    });

    test('should follow message chain with nextMessageId', () {
      // Arrange
      final message1 = ChatMessage(id: 1, text: 'First', nextMessageId: 3);
      final message3 = ChatMessage(id: 3, text: 'Third');
      testSequenceLoader.addMessage(message1);
      testSequenceLoader.addMessage(message3);

      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, hasLength(2));
      expect(result.messages[0].id, equals(1));
      expect(result.messages[1].id, equals(3));
      expect(result.stopReason, equals(TraversalStopReason.endOfSequence));
    });

    test('should continue after dataAction message', () {
      // Arrange
      final dataActionMessage = ChatMessage(
        id: 1,
        text: '',
        type: MessageType.dataAction,
        nextMessageId: 2,
      );
      final botMessage = ChatMessage(id: 2, text: 'After data action');
      
      testSequenceLoader.addMessage(dataActionMessage);
      testSequenceLoader.addMessage(botMessage);

      // Act
      final result = flowTraverser.traverse(1, testSequenceLoader);

      // Assert
      expect(result.messages, hasLength(2));
      expect(result.messages[0].id, equals(1));
      expect(result.messages[1].id, equals(2));
      expect(result.stopReason, equals(TraversalStopReason.endOfSequence));
    });
  });
}