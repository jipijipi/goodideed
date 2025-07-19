import '../../models/chat_message.dart';
import '../../models/route_condition.dart';
import '../../config/chat_config.dart';
import '../condition_evaluator.dart';
import '../data_action_processor.dart';
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
    print('🚏 AUTOROUTE: Processing autoroute message ID: ${routeMessage.id}');
    if (_conditionEvaluator == null || routeMessage.routes == null) {
      print('❌ AUTOROUTE: No condition evaluator or routes found, using nextMessageId: ${routeMessage.nextMessageId}');
      return routeMessage.nextMessageId;
    }

    print('🚏 AUTOROUTE: Found ${routeMessage.routes!.length} routes to evaluate');
    
    // FIXED: First evaluate all conditional routes, then fall back to default
    // First pass: Evaluate all conditional routes
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      print('🚏 AUTOROUTE: Evaluating conditional route ${i + 1}/${routeMessage.routes!.length}');
      
      // Skip default routes in first pass
      if (route.isDefault) {
        print('🚏 AUTOROUTE: Route ${i + 1} is default route, skipping in first pass');
        continue;
      }
      
      // Evaluate condition if present
      if (route.condition != null) {
        print('🚏 AUTOROUTE: Route ${i + 1} has condition: "${route.condition}"');
        final matches = await _conditionEvaluator.evaluateCompound(route.condition!);
        print('🚏 AUTOROUTE: Route ${i + 1} condition result: $matches');
        if (matches) {
          print('🚏 AUTOROUTE: Route ${i + 1} matches! Executing route');
          return await _executeRoute(route);
        }
        print('🚏 AUTOROUTE: Route ${i + 1} does not match, trying next route');
      } else {
        print('🚏 AUTOROUTE: Route ${i + 1} has no condition and is not default, skipping');
      }
    }
    
    // Second pass: Execute default route if no conditions matched
    for (int i = 0; i < routeMessage.routes!.length; i++) {
      final route = routeMessage.routes![i];
      if (route.isDefault) {
        print('🚏 AUTOROUTE: No conditions matched, executing default route ${i + 1}');
        return await _executeRoute(route);
      }
    }
    
    // If no routes matched, use the message's nextMessageId
    print('🚏 AUTOROUTE: No routes matched, using fallback nextMessageId: ${routeMessage.nextMessageId}');
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