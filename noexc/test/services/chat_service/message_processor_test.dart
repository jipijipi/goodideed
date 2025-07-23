import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/chat_service/message_processor.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/services/text_variants_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/chat_sequence.dart';
import 'package:noexc/models/choice.dart';

void main() {
  group('MessageProcessor', () {
    late MessageProcessor messageProcessor;
    late UserDataService mockUserDataService;
    late TextTemplatingService mockTemplatingService;
    late TextVariantsService mockVariantsService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      mockUserDataService = UserDataService();
      mockTemplatingService = TextTemplatingService(mockUserDataService);
      mockVariantsService = TextVariantsService();
      
      messageProcessor = MessageProcessor(
        userDataService: mockUserDataService,
        templatingService: mockTemplatingService,
        variantsService: mockVariantsService,
      );
    });

    group('processMessageTemplate', () {
      test('should process regular bot message with template variables', () async {
        // Arrange
        await mockUserDataService.storeValue(StorageKeys.userName, 'John');
        final message = ChatMessage(
          id: 1,
          text: 'Hello {user.name|Guest}!',
          delay: 1000,
          sender: 'bot',
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.text, equals('Hello John!'));
        expect(result.id, equals(1));
        expect(result.delay, equals(1000));
        expect(result.sender, equals('bot'));
      });

      test('should use fallback value when template variable not found', () async {
        // Arrange - Clear any existing data first
        await mockUserDataService.clearAllData();
        
        final message = ChatMessage(
          id: 1,
          text: 'Hello {user.name|Guest}!',
          delay: 1000,
          sender: 'bot',
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.text, equals('Hello Guest!'));
      });

      test('should not apply variants to choice messages', () async {
        // Arrange
        final message = ChatMessage(
          id: 1,
          text: '', // Choice messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.choice,
          choices: [
            Choice(text: 'Option 1', nextMessageId: 2),
            Choice(text: 'Option 2', nextMessageId: 3),
          ],
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.text, equals(''));
        expect(result.choices, isNotNull);
        expect(result.choices!.length, equals(2));
      });

      test('should not apply variants to text input messages', () async {
        // Arrange
        final message = ChatMessage(
          id: 1,
          text: '', // Text input messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.textInput,
          storeKey: StorageKeys.userName,
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.text, equals(''));
        expect(result.storeKey, equals(StorageKeys.userName));
      });

      test('should not apply variants to autoroute messages', () async {
        // Arrange
        final message = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.text, equals(''));
        expect(result.type, equals(MessageType.autoroute));
      });

      test('should handle multi-text messages correctly', () async {
        // Arrange
        final message = ChatMessage(
          id: 1,
          text: 'First part|||Second part|||Third part',
          delay: 1000,
          sender: 'bot',
        );
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: [message],
        );

        // Act
        final result = await messageProcessor.processMessageTemplate(message, sequence);

        // Assert
        expect(result.hasMultipleTexts, isTrue);
        expect(result.text, equals('First part|||Second part|||Third part'));
      });

      test('should work without services when they are null', () async {
        // Arrange
        final processorWithoutServices = MessageProcessor();
        final message = ChatMessage(
          id: 1,
          text: 'Hello {user.name|Guest}!',
          delay: 1000,
          sender: 'bot',
        );

        // Act
        final result = await processorWithoutServices.processMessageTemplate(message, null);

        // Assert
        expect(result.text, equals('Hello {user.name|Guest}!'));
        expect(result.id, equals(1));
      });
    });

    group('processMessageTemplates', () {
      test('should process multiple messages correctly', () async {
        // Arrange
        await mockUserDataService.storeValue(StorageKeys.userName, 'Alice');
        final messages = [
          ChatMessage(
            id: 1,
            text: 'Hello {user.name|Guest}!',
            delay: 1000,
            sender: 'bot',
          ),
          ChatMessage(
            id: 2,
            text: 'How are you today, {user.name|there}?',
            delay: 1500,
            sender: 'bot',
          ),
        ];
        final sequence = ChatSequence(
          sequenceId: 'test_seq',
          name: 'Test Sequence',
          description: 'Test',
          messages: messages,
        );

        // Act
        final results = await messageProcessor.processMessageTemplates(messages, sequence);

        // Assert
        expect(results.length, equals(2));
        expect(results[0].text, equals('Hello Alice!'));
        expect(results[1].text, equals('How are you today, Alice?'));
      });

      test('should handle empty message list', () async {
        // Arrange
        final messages = <ChatMessage>[];

        // Act
        final results = await messageProcessor.processMessageTemplates(messages, null);

        // Assert
        expect(results, isEmpty);
      });
    });

    group('handleUserTextInput', () {
      test('should store user input when storeKey is provided', () async {
        // Arrange
        final textInputMessage = ChatMessage(
          id: 1,
          text: '', // Text input messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.textInput,
          storeKey: StorageKeys.userName,
        );
        const userInput = 'John Doe';

        // Act
        await messageProcessor.handleUserTextInput(textInputMessage, userInput);

        // Assert
        final storedValue = await mockUserDataService.getValue(StorageKeys.userName);
        expect(storedValue, equals('John Doe'));
      });

      test('should not store when storeKey is null', () async {
        // Arrange
        final textInputMessage = ChatMessage(
          id: 1,
          text: '', // Text input messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.textInput,
        );
        const userInput = 'Some input';

        // Act
        await messageProcessor.handleUserTextInput(textInputMessage, userInput);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });

      test('should work without userDataService', () async {
        // Arrange
        final processorWithoutServices = MessageProcessor();
        final textInputMessage = ChatMessage(
          id: 1,
          text: '', // Text input messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.textInput,
          storeKey: StorageKeys.userName,
        );
        const userInput = 'Some input';

        // Act & Assert - Should not throw
        await processorWithoutServices.handleUserTextInput(textInputMessage, userInput);
        expect(true, isTrue);
      });
    });

    group('handleUserChoice', () {
      test('should store choice text when storeKey is provided and no custom value', () async {
        // Arrange
        final choiceMessage = ChatMessage(
          id: 1,
          text: '', // Choice messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.choice,
          storeKey: 'user.preference',
        );
        final selectedChoice = Choice(text: 'Option A', nextMessageId: 2);

        // Act
        await messageProcessor.handleUserChoice(choiceMessage, selectedChoice);

        // Assert
        final storedValue = await mockUserDataService.getValue('user.preference');
        expect(storedValue, equals('Option A'));
      });

      test('should store custom value when provided', () async {
        // Arrange
        final choiceMessage = ChatMessage(
          id: 1,
          text: '', // Choice messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.choice,
          storeKey: 'user.preference',
        );
        final selectedChoice = Choice(
          text: 'Yes, I agree',
          value: 'true',
          nextMessageId: 2,
        );

        // Act
        await messageProcessor.handleUserChoice(choiceMessage, selectedChoice);

        // Assert
        final storedValue = await mockUserDataService.getValue('user.preference');
        expect(storedValue, equals('true'));
      });

      test('should not store when storeKey is null', () async {
        // Arrange
        final choiceMessage = ChatMessage(
          id: 1,
          text: '', // Choice messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.choice,
        );
        final selectedChoice = Choice(text: 'Option A', nextMessageId: 2);

        // Act
        await messageProcessor.handleUserChoice(choiceMessage, selectedChoice);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });

      test('should work without userDataService', () async {
        // Arrange
        final processorWithoutServices = MessageProcessor();
        final choiceMessage = ChatMessage(
          id: 1,
          text: '', // Choice messages should have empty text
          delay: 1000,
          sender: 'bot',
          type: MessageType.choice,
          storeKey: 'user.preference',
        );
        final selectedChoice = Choice(text: 'Option A', nextMessageId: 2);

        // Act & Assert - Should not throw
        await processorWithoutServices.handleUserChoice(choiceMessage, selectedChoice);
        expect(true, isTrue);
      });
    });
  });
}