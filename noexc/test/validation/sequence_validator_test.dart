import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/validation/sequence_validator.dart';
import 'package:noexc/validation/models/validation_models.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';
import 'package:noexc/models/route_condition.dart';

void main() {
  group('SequenceValidator', () {
    late SequenceValidator validator;
    
    setUp(() {
      validator = SequenceValidator();
    });
    
    group('Basic Structure Validation', () {
      test('should pass validation for valid sequence', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: '',
              type: MessageType.choice,
              choices: [
                Choice(
                  text: 'Continue',
                  sequenceId: 'other_sequence',
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, true);
        expect(result.errors.length, 0);
      });
      
      test('should detect missing sequence ID', () {
        final sequence = ChatSequence(
          sequenceId: '',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(id: 1, text: 'Hello', type: MessageType.bot),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'MISSING_SEQUENCE_ID'), true);
      });
      
      test('should detect missing sequence name', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: '',
          description: 'A test sequence',
          messages: [
            ChatMessage(id: 1, text: 'Hello', type: MessageType.bot),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'MISSING_SEQUENCE_NAME'), true);
      });
      
      test('should detect empty sequence', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'EMPTY_SEQUENCE'), true);
      });
      
      test('should detect duplicate message IDs', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(id: 1, text: 'Hello', type: MessageType.bot),
            ChatMessage(id: 1, text: 'Duplicate', type: MessageType.bot),
            ChatMessage(id: 2, text: 'Valid', type: MessageType.bot),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'DUPLICATE_MESSAGE_IDS'), true);
      });
    });
    
    group('Message Reference Validation', () {
      test('should detect invalid next message ID', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 999, // Non-existent
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'INVALID_NEXT_MESSAGE_ID'), true);
      });
      
      test('should detect invalid choice next message ID', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.choice,
              choices: [
                Choice(
                  text: 'Option 1',
                  nextMessageId: 999, // Non-existent
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'INVALID_CHOICE_NEXT_MESSAGE_ID'), true);
      });
      
      test('should detect invalid route next message ID', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.autoroute,
              routes: [
                RouteCondition(
                  condition: 'user.test == true',
                  nextMessageId: 999, // Non-existent
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'INVALID_ROUTE_NEXT_MESSAGE_ID'), true);
      });
    });
    
    group('Flow Analysis', () {
      test('should detect dead end messages', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: 'Dead end',
              type: MessageType.bot,
              // No nextMessageId, no choices, no routes
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.errors.any((e) => e.type == 'DEAD_END'), true);
      });
      
      test('should detect unreachable messages', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: 'Reachable',
              type: MessageType.bot,
            ),
            ChatMessage(
              id: 3,
              text: 'Unreachable',
              type: MessageType.bot,
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.warnings.any((w) => w.type == 'UNREACHABLE_MESSAGE'), true);
      });
      
      test('should detect circular references', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: 'World',
              type: MessageType.bot,
              nextMessageId: 1, // Creates circular reference
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.warnings.any((w) => w.type == 'CIRCULAR_REFERENCE'), true);
      });
    });
    
    group('Choice Validation', () {
      test('should detect missing choices in choice message', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.choice,
              choices: [], // Empty choices
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'MISSING_CHOICES'), true);
      });
      
      test('should detect choices without destination', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.choice,
              choices: [
                Choice(
                  text: 'Option 1',
                  // No nextMessageId or sequenceId
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'CHOICE_NO_DESTINATION'), true);
      });
    });
    
    group('Route Validation', () {
      test('should detect missing routes in autoroute message', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.autoroute,
              routes: [], // Empty routes
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'MISSING_ROUTES'), true);
      });
      
      test('should detect missing default route', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.autoroute,
              routes: [
                RouteCondition(
                  condition: 'user.test == true',
                  nextMessageId: 2,
                ),
                // No default route
              ],
            ),
            ChatMessage(
              id: 2,
              text: 'Result',
              type: MessageType.bot,
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'MISSING_DEFAULT_ROUTE'), true);
      });
      
      test('should detect routes without destination', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: '',
              type: MessageType.autoroute,
              routes: [
                RouteCondition(
                  condition: 'user.test == true',
                  // No nextMessageId or sequenceId
                ),
                RouteCondition(
                  isDefault: true,
                  nextMessageId: 2,
                ),
              ],
            ),
            ChatMessage(
              id: 2,
              text: 'Result',
              type: MessageType.bot,
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.type == 'ROUTE_NO_DESTINATION'), true);
      });
    });
    
    group('Template Validation', () {
      test('should detect mismatched template brackets', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello {user.name',
              type: MessageType.bot,
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.warnings.any((w) => w.type == 'TEMPLATE_SYNTAX_WARNING'), true);
      });
    });
    
    group('Valid Endpoint Detection', () {
      test('should not flag cross-sequence navigation as dead end', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: '',
              type: MessageType.choice,
              choices: [
                Choice(
                  text: 'Go to other sequence',
                  sequenceId: 'other_sequence',
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.errors.any((e) => e.type == 'DEAD_END'), false);
      });
      
      test('should not flag autoroute with sequence switch as dead end', () {
        final sequence = ChatSequence(
          sequenceId: 'test',
          name: 'Test Sequence',
          description: 'A test sequence',
          messages: [
            ChatMessage(
              id: 1,
              text: 'Hello',
              type: MessageType.bot,
              nextMessageId: 2,
            ),
            ChatMessage(
              id: 2,
              text: '',
              type: MessageType.autoroute,
              routes: [
                RouteCondition(
                  condition: 'user.test == true',
                  sequenceId: 'other_sequence',
                ),
                RouteCondition(
                  isDefault: true,
                  sequenceId: 'default_sequence',
                ),
              ],
            ),
          ],
        );
        
        final result = validator.validateSequence(sequence);
        
        expect(result.errors.any((e) => e.type == 'DEAD_END'), false);
      });
    });
    
    group('ValidationResult', () {
      test('should format validation result correctly', () {
        final errors = [
          ValidationError(
            type: 'TEST_ERROR',
            message: 'Test error message',
            messageId: 1,
            sequenceId: 'test',
          ),
        ];
        
        final warnings = [
          ValidationError(
            type: 'TEST_WARNING',
            message: 'Test warning message',
            severity: 'warning',
          ),
        ];
        
        final result = ValidationResult(
          errors: errors,
          warnings: warnings,
          info: [],
        );
        
        expect(result.isValid, false);
        expect(result.errors.length, 1);
        expect(result.warnings.length, 1);
        expect(result.allIssues.length, 2);
        
        final resultString = result.toString();
        expect(resultString.contains('Errors: 1'), true);
        expect(resultString.contains('Warnings: 1'), true);
        expect(resultString.contains('TEST_ERROR'), true);
        expect(resultString.contains('TEST_WARNING'), true);
      });
    });
  });
}