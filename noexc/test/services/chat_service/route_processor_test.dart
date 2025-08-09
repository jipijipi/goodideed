import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/chat_service/route_processor.dart';
import 'package:noexc/services/chat_service/sequence_loader.dart';
import 'package:noexc/services/flow/sequence_manager.dart';
import 'package:noexc/services/condition_evaluator.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/route_condition.dart';
import 'package:noexc/models/data_action.dart';

void main() {
  group('RouteProcessor', () {
    late RouteProcessor routeProcessor;
    late ConditionEvaluator mockConditionEvaluator;
    late DataActionProcessor mockDataActionProcessor;
    late SequenceManager mockSequenceManager;
    late UserDataService mockUserDataService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      mockUserDataService = UserDataService();
      mockConditionEvaluator = ConditionEvaluator(mockUserDataService);
      mockDataActionProcessor = DataActionProcessor(mockUserDataService);
      final sequenceLoader = SequenceLoader();
      mockSequenceManager = SequenceManager(sequenceLoader: sequenceLoader);
      
      routeProcessor = RouteProcessor(
        conditionEvaluator: mockConditionEvaluator,
        dataActionProcessor: mockDataActionProcessor,
        sequenceManager: mockSequenceManager,
      );
    });

    group('processAutoRoute', () {
      test('should return nextMessageId when no condition evaluator', () async {
        // Arrange
        final routeProcessorWithoutEvaluator = RouteProcessor(
          sequenceManager: mockSequenceManager,
        );
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessorWithoutEvaluator.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(5));
      });

      test('should return nextMessageId when no routes', () async {
        // Arrange
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(5));
      });

      test('should execute first matching conditional route', () async {
        // Arrange
        await mockUserDataService.storeValue('user.hasTask', true);
        final routes = [
          RouteCondition(
            condition: 'user.hasTask == true',
            nextMessageId: 10,
          ),
          RouteCondition(
            condition: 'user.hasTask == false',
            nextMessageId: 20,
          ),
          RouteCondition(
            isDefault: true,
            nextMessageId: 30,
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(10));
      });

      test('should execute default route when no conditions match', () async {
        // Arrange
        await mockUserDataService.storeValue('user.hasTask', 'maybe');
        final routes = [
          RouteCondition(
            condition: 'user.hasTask == true',
            nextMessageId: 10,
          ),
          RouteCondition(
            condition: 'user.hasTask == false',
            nextMessageId: 20,
          ),
          RouteCondition(
            isDefault: true,
            nextMessageId: 30,
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(30));
      });

      test('should return fallback nextMessageId when no routes match', () async {
        // Arrange
        final routes = [
          RouteCondition(
            condition: 'user.nonexistent == true',
            nextMessageId: 10,
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(5));
      });

      test('should handle route with sequenceId', () async {
        // Arrange
        await mockUserDataService.storeValue('user.needsOnboarding', true);
        final routes = [
          RouteCondition(
            condition: 'user.needsOnboarding == true',
            sequenceId: 'onboarding_seq',
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        // Should return the first message ID from the onboarding_seq sequence
        expect(result, isNotNull);
        expect(result, isA<int>());
        // The actual ID will be the first message ID from onboarding_seq (not hard-coded 1)
      });

      test('should skip default routes in first pass', () async {
        // Arrange
        await mockUserDataService.storeValue('user.status', 'active');
        final routes = [
          RouteCondition(
            isDefault: true,
            nextMessageId: 100, // This should not be executed in first pass
          ),
          RouteCondition(
            condition: 'user.status == "active"',
            nextMessageId: 50,
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(50)); // Should match the conditional route, not default
      });

      test('should handle routes without conditions that are not default', () async {
        // Arrange
        final routes = [
          RouteCondition(
            nextMessageId: 10, // No condition, not default
          ),
          RouteCondition(
            isDefault: true,
            nextMessageId: 20,
          ),
        ];
        final routeMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.autoroute,
          routes: routes,
          nextMessageId: 5,
        );

        // Act
        final result = await routeProcessor.processAutoRoute(routeMessage);

        // Assert
        expect(result, equals(20)); // Should execute default route
      });
    });

    group('processDataAction', () {
      test('should process data actions and return nextMessageId', () async {
        // Arrange
        final dataActions = [
          DataAction(
            type: DataActionType.set,
            key: 'user.score',
            value: 100,
          ),
          DataAction(
            type: DataActionType.increment,
            key: 'user.visits',
          ),
        ];
        final dataActionMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.dataAction,
          dataActions: dataActions,
          nextMessageId: 10,
        );

        // Act
        final result = await routeProcessor.processDataAction(dataActionMessage);

        // Assert
        expect(result, equals(10));
        final score = await mockUserDataService.getValue('user.score');
        expect(score, equals(100));
      });

      test('should return nextMessageId when no data action processor', () async {
        // Arrange
        final routeProcessorWithoutProcessor = RouteProcessor(
          sequenceManager: mockSequenceManager,
        );
        final dataActionMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.dataAction,
          nextMessageId: 10,
        );

        // Act
        final result = await routeProcessorWithoutProcessor.processDataAction(dataActionMessage);

        // Assert
        expect(result, equals(10));
      });

      test('should return nextMessageId when no data actions', () async {
        // Arrange
        final dataActionMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.dataAction,
          nextMessageId: 10,
        );

        // Act
        final result = await routeProcessor.processDataAction(dataActionMessage);

        // Assert
        expect(result, equals(10));
      });

      test('should handle data action processing errors gracefully', () async {
        // Arrange
        final dataActions = [
          DataAction(
            type: DataActionType.set,
            key: '', // Invalid empty key to test error handling
            value: 'test',
          ),
        ];
        final dataActionMessage = ChatMessage(
          id: 1,
          text: '',
          delay: 0,
          sender: 'bot',
          type: MessageType.dataAction,
          dataActions: dataActions,
          nextMessageId: 10,
        );

        // Act & Assert - Should not throw
        final result = await routeProcessor.processDataAction(dataActionMessage);
        expect(result, equals(10));
      });
    });

    group('dataActionProcessor getter', () {
      test('should return the data action processor', () {
        // Act
        final processor = routeProcessor.dataActionProcessor;

        // Assert
        expect(processor, equals(mockDataActionProcessor));
      });

      test('should return null when no processor provided', () {
        // Arrange
        final routeProcessorWithoutProcessor = RouteProcessor(
          sequenceManager: mockSequenceManager,
        );

        // Act
        final processor = routeProcessorWithoutProcessor.dataActionProcessor;

        // Assert
        expect(processor, isNull);
      });
    });
  });
}
