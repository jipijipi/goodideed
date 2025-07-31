import '../../models/chat_message.dart';
import '../../models/route_condition.dart';
import '../condition_evaluator.dart';
import '../data_action_processor.dart';
import '../logger_service.dart';
import '../flow/sequence_manager.dart';

/// Handles route processing including auto-routes and data actions
class RouteProcessor {
  final ConditionEvaluator? _conditionEvaluator;
  final DataActionProcessor? _dataActionProcessor;
  final SequenceManager _sequenceManager;
  
  /// Get the data action processor for callback setup
  DataActionProcessor? get dataActionProcessor => _dataActionProcessor;

  RouteProcessor({
    ConditionEvaluator? conditionEvaluator,
    DataActionProcessor? dataActionProcessor,
    required SequenceManager sequenceManager,
  }) : _conditionEvaluator = conditionEvaluator,
       _dataActionProcessor = dataActionProcessor,
       _sequenceManager = sequenceManager;

  /// Process an autoroute message and return the next message ID
  Future<int?> processAutoRoute(ChatMessage routeMessage) async {
    if (_conditionEvaluator == null || routeMessage.routes == null) {
      logger.route('No routes available for message ${routeMessage.id}', level: LogLevel.warning);
      return routeMessage.nextMessageId;
    }
    
    // First pass: Evaluate all conditional routes
    for (final route in routeMessage.routes!) {
      // Skip default routes in first pass
      if (route.isDefault) continue;
      
      // Evaluate condition if present
      if (route.condition != null) {
        final matches = await _conditionEvaluator.evaluateCompound(route.condition!);
        if (matches) {
          logger.route('Route matched: "${route.condition}"');
          return await _executeRoute(route);
        }
      }
    }
    
    // Second pass: Execute default route if no conditions matched
    for (final route in routeMessage.routes!) {
      if (route.isDefault) {
        logger.route('Using default route');
        return await _executeRoute(route);
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    logger.route('No routes matched, using fallback', level: LogLevel.warning);
    return routeMessage.nextMessageId;
  }

  /// Process dataAction messages by executing data modifications
  Future<int?> processDataAction(ChatMessage dataActionMessage) async {
    if (_dataActionProcessor == null || dataActionMessage.dataActions == null) {
      return dataActionMessage.nextMessageId;
    }

    try {
      await _dataActionProcessor.processActions(dataActionMessage.dataActions!);
    } catch (e) {
      logger.route('Data actions failed: $e', level: LogLevel.error);
    }
    
    // Continue to next message
    return dataActionMessage.nextMessageId;
  }

  /// Execute a route condition by loading sequence or returning message ID
  Future<int?> _executeRoute(RouteCondition route) async {
    if (route.sequenceId != null) {
      // Always load sequence directly for message accumulation
      await _sequenceManager.loadSequence(route.sequenceId!);
      
      // Start with the first message in the new sequence
      final sequence = _sequenceManager.currentSequence;
      if (sequence == null || sequence.messages.isEmpty) {
        throw Exception('Sequence ${route.sequenceId} has no messages');
      }
      final startMessageId = sequence.messages.first.id;
      
      // Note: No UI notification needed - messages are accumulated seamlessly
      
      return startMessageId;
    }
    
    // Stay in current sequence, go to specified message
    return route.nextMessageId;
  }
}