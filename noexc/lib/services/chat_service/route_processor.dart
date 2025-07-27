import '../../models/chat_message.dart';
import '../../models/route_condition.dart';
import '../../config/chat_config.dart';
import '../condition_evaluator.dart';
import '../data_action_processor.dart';
import '../logger_service.dart';
import 'sequence_loader.dart';

/// Handles route processing including auto-routes and data actions
class RouteProcessor {
  final ConditionEvaluator? _conditionEvaluator;
  final DataActionProcessor? _dataActionProcessor;
  final SequenceLoader _sequenceLoader;
  
  /// Get the data action processor for callback setup
  DataActionProcessor? get dataActionProcessor => _dataActionProcessor;

  RouteProcessor({
    ConditionEvaluator? conditionEvaluator,
    DataActionProcessor? dataActionProcessor,
    required SequenceLoader sequenceLoader,
  }) : _conditionEvaluator = conditionEvaluator,
       _dataActionProcessor = dataActionProcessor,
       _sequenceLoader = sequenceLoader;

  /// Process an autoroute message and return the next message ID
  Future<int?> processAutoRoute(ChatMessage routeMessage) async {
    logger.route('Processing autoroute message ID: ${routeMessage.id}');
    if (_conditionEvaluator == null || routeMessage.routes == null) {
      logger.route('No condition evaluator or routes found, using nextMessageId: ${routeMessage.nextMessageId}', level: LogLevel.warning);
      return routeMessage.nextMessageId;
    }

    logger.route('Found ${routeMessage.routes!.length} routes to evaluate');
    
    // FIXED: First evaluate all conditional routes, then fall back to default
    // First pass: Evaluate all conditional routes
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      logger.route('Evaluating conditional route ${i + 1}/${routeMessage.routes!.length}');
      
      // Skip default routes in first pass
      if (route.isDefault) {
        logger.route('Route ${i + 1} is default route, skipping in first pass');
        continue;
      }
      
      // Evaluate condition if present
      if (route.condition != null) {
        logger.route('Route ${i + 1} has condition: "${route.condition}"');
        final matches = await _conditionEvaluator.evaluateCompound(route.condition!);
        logger.route('Route ${i + 1} condition result: $matches');
        if (matches) {
          logger.route('Route ${i + 1} matches! Executing route', level: LogLevel.info);
          return await _executeRoute(route);
        }
        logger.route('Route ${i + 1} does not match, trying next route');
      } else {
        logger.route('Route ${i + 1} has no condition and is not default, skipping');
      }
    }
    
    // Second pass: Execute default route if no conditions matched
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      if (route.isDefault) {
        logger.route('No conditions matched, executing default route ${i + 1}', level: LogLevel.info);
        return await _executeRoute(route);
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    logger.route('No routes matched, using fallback nextMessageId: ${routeMessage.nextMessageId}', level: LogLevel.warning);
    return routeMessage.nextMessageId;
  }

  /// Process dataAction messages by executing data modifications
  Future<int?> processDataAction(ChatMessage dataActionMessage) async {
    if (_dataActionProcessor == null || dataActionMessage.dataActions == null) {
      logger.route('No data action processor or actions found, continuing to next message', level: LogLevel.warning);
      return dataActionMessage.nextMessageId;
    }

    try {
      logger.route('Processing ${dataActionMessage.dataActions!.length} data actions');
      await _dataActionProcessor.processActions(dataActionMessage.dataActions!);
      logger.route('Data actions completed successfully');
    } catch (e) {
      logger.route('Data action processing failed: $e', level: LogLevel.error);
      // Silent error handling - dataActions should not fail the message flow
    }
    
    // Continue to next message
    return dataActionMessage.nextMessageId;
  }

  /// Execute a route condition by loading sequence or returning message ID
  Future<int?> _executeRoute(RouteCondition route) async {
    if (route.sequenceId != null) {
      final startMessageId = ChatConfig.initialMessageId;
      
      // Always load sequence directly for message accumulation
      await _sequenceLoader.loadSequence(route.sequenceId!);
      
      // Note: No UI notification needed - messages are accumulated seamlessly
      
      return startMessageId;
    }
    
    // Stay in current sequence, go to specified message
    return route.nextMessageId;
  }
}