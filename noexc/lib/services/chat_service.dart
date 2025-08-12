import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../models/choice.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';
import 'text_variants_service.dart';
import 'condition_evaluator.dart';
import 'data_action_processor.dart';
import 'session_service.dart';
import 'chat_service/sequence_loader.dart';
import 'chat_service/message_processor.dart';
import 'chat_service/route_processor.dart';
import 'flow/message_walker.dart';
import 'flow/message_renderer.dart';
import 'flow/flow_orchestrator.dart';
import 'flow/sequence_manager.dart';
import 'logger_service.dart';
import 'service_locator.dart';

/// Main chat service that orchestrates sequence loading, message processing, and routing
class ChatService {
  late final MessageProcessor _messageProcessor;
  late final RouteProcessor _routeProcessor;
  late final SequenceManager _sequenceManager;
  late final MessageWalker _messageWalker;
  late final MessageRenderer _messageRenderer;
  late final FlowOrchestrator _flowOrchestrator;
  final logger = LoggerService.instance;

  // Callback for notifying UI about events from dataAction triggers
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
    SessionService? sessionService,
  }) {
    // Initialize sequence management first (single source of truth)
    final sequenceLoader = SequenceLoader();
    _sequenceManager = SequenceManager(sequenceLoader: sequenceLoader);

    _messageProcessor = MessageProcessor(
      userDataService: userDataService,
      templatingService: templatingService,
      variantsService: variantsService,
    );

    _routeProcessor = RouteProcessor(
      conditionEvaluator:
          userDataService != null ? ConditionEvaluator(userDataService) : null,
      dataActionProcessor:
          userDataService != null
              ? DataActionProcessor(
                userDataService,
                sessionService: sessionService,
              )
              : null,
      sequenceManager: _sequenceManager,
    );

    // Initialize clean architecture components
    _messageWalker = MessageWalker();
    _messageRenderer = MessageRenderer(messageProcessor: _messageProcessor);
    _flowOrchestrator = FlowOrchestrator(
      walker: _messageWalker,
      renderer: _messageRenderer,
      sequenceManager: _sequenceManager,
      routeProcessor: _routeProcessor,
    );

    // Set up event callback for dataActionProcessor
    if (_routeProcessor.dataActionProcessor != null) {
      _routeProcessor.dataActionProcessor!.setEventCallback(_handleEvent);
    }
  }

  /// Set callback for event notifications from dataAction triggers
  void setEventCallback(
    Future<void> Function(String eventType, Map<String, dynamic> data) callback,
  ) {
    _onEvent = callback;
  }

  /// Handle events from dataActionProcessor
  Future<void> _handleEvent(String eventType, Map<String, dynamic> data) async {
    // Handle specific event types
    switch (eventType) {
      case 'recalculate_active_day':
        await _handleRecalculateActiveDay();
        break;
      case 'recalculate_past_deadline':
        await _handleRecalculatePastDeadline();
        break;
      case 'recalculate_end_date':
        await _handleRecalculateEndDate();
        break;
      case 'refresh_task_calculations':
        await _handleRefreshTaskCalculations();
        break;
      case 'notification_request_permissions':
        await _handleNotificationRequestPermissions();
        break;
      case 'notification_reschedule':
        await _handleNotificationReschedule();
        break;
      case 'notification_disable':
        await _handleNotificationDisable();
        break;
      case 'overlay_rive':
        await _handleOverlayRive(data);
        break;
      case 'overlay_rive_update':
        await _handleOverlayRiveUpdate(data);
        break;
      default:
        // Forward unknown events to UI callback
        if (_onEvent != null) {
          try {
            await _onEvent!(eventType, data);
          } catch (e) {
            // Silent error handling
          }
        }
    }
  }

  /// Handle overlay_rive event to display a global overlay animation
  Future<void> _handleOverlayRive(Map<String, dynamic> data) async {
    try {
      final asset = data['asset'] as String?;
      if (asset == null || asset.isEmpty) {
        logger.warning('overlay_rive missing asset path');
        return;
      }
      final alignStr = data['align'] as String?;
      final align = _parseAlignment(alignStr) ?? Alignment.center;
      final fitStr = data['fit'] as String?;
      final fit = _parseRiveFit(fitStr) ?? Fit.contain;
      final zone = (data['zone'] as int?) ?? 2;
      final autoHideMs = data['autoHideMs'] as int?;
      final autoHide = autoHideMs != null ? Duration(milliseconds: autoHideMs) : null;
      final bindings = await _resolveNumericBindings(data['bindings']);
      final useDataBinding = (data['useDataBinding'] as bool?) ?? false;

      ServiceLocator.instance.riveOverlayService.show(
        asset: asset,
        align: align,
        fit: fit,
        autoHideAfter: autoHide,
        zone: zone,
        bindings: bindings,
        useDataBinding: useDataBinding,
      );
    } catch (e) {
      logger.error('Failed to handle overlay_rive: $e');
    }
  }

  Future<void> _handleOverlayRiveUpdate(Map<String, dynamic> data) async {
    try {
      final zone = (data['zone'] as int?) ?? 3;
      final bindings = await _resolveNumericBindings(data['bindings']);
      if (bindings == null || bindings.isEmpty) return;
      ServiceLocator.instance.riveOverlayService.update(zone: zone, bindings: bindings);
    } catch (e) {
      logger.error('Failed to handle overlay_rive_update: $e');
    }
  }

  /// Resolve a `bindings` map into numeric values, supporting:
  /// - numeric literals (int/double)
  /// - templated strings like "{{ user.streak }}"
  /// - direct path strings like "user.streak"
  Future<Map<String, double>?> _resolveNumericBindings(dynamic raw) async {
    if (raw is! Map) return null;
    final Map<String, double> result = {};
    final templating = ServiceLocator.instance.templatingService;

    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      double? resolved;
      if (value is num) {
        resolved = value.toDouble();
      } else if (value is String) {
        // If it's already numeric string, parse directly.
        resolved = double.tryParse(value);
        if (resolved == null) {
          // Use TextTemplatingService to resolve variables from user/session/task data.
          // Accept both explicit templates (e.g., "{user.streak}") and shorthand paths (e.g., "user.streak").
          final template = value.contains('{') ? value : '{${value.trim()}}';
          final processed = await templating.processTemplate(template);
          // If unresolved, processed may still contain braces; attempt numeric parse only.
          resolved = double.tryParse(processed);
          if (resolved == null) {
            logger.warning('Binding "$key" is not numeric after templating: "$value" -> "$processed"');
          }
        }
      }

      if (resolved != null) {
        result[key] = resolved;
      }
    }

    return result;
  }

  // Removed unused helper _toDouble after templating refactor

  Alignment? _parseAlignment(String? value) {
    switch (value) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return null;
    }
  }

  Fit? _parseRiveFit(String? value) {
    switch (value) {
      case 'contain':
        return Fit.contain;
      case 'cover':
        return Fit.cover;
      case 'fill':
        return Fit.fill;
      case 'fitWidth':
        return Fit.fitWidth;
      case 'fitHeight':
        return Fit.fitHeight;
      case 'none':
        return Fit.none;
      case 'scaleDown':
        return Fit.scaleDown;
      default:
        return null;
    }
  }

  /// Handle recalculate_active_day event from dataAction trigger
  Future<void> _handleRecalculateActiveDay() async {
    try {
      final userDataService = ServiceLocator.instance.userDataService;
      final sessionService = SessionService(userDataService);
      await sessionService.recalculateActiveDay();
      logger.info('Successfully recalculated task.isActiveDay');
    } catch (e) {
      logger.error('Failed to recalculate active day: $e');
    }
  }

  /// Handle recalculate_past_deadline event from dataAction trigger
  Future<void> _handleRecalculatePastDeadline() async {
    try {
      final userDataService = ServiceLocator.instance.userDataService;
      final sessionService = SessionService(userDataService);
      await sessionService.recalculatePastDeadline();
      logger.info('Successfully recalculated task.isPastDeadline');
    } catch (e) {
      logger.error('Failed to recalculate past deadline: $e');
    }
  }

  /// Handle recalculate_end_date event from dataAction trigger
  Future<void> _handleRecalculateEndDate() async {
    try {
      final userDataService = ServiceLocator.instance.userDataService;
      final sessionService = SessionService(userDataService);
      await sessionService.recalculateTaskEndDate();
      logger.info(
        'Successfully recalculated task.endDate and task.isPastEndDate',
      );
    } catch (e) {
      logger.error(
        'Failed to recalculate task.endDate and task.isPastEndDate: $e',
      );
    }
  }

  /// Handle refresh_task_calculations event from dataAction trigger
  Future<void> _handleRefreshTaskCalculations() async {
    final userDataService = ServiceLocator.instance.userDataService;
    final sessionService = SessionService(userDataService);

    // Recalculate task.endDate and task.isPastEndDate
    try {
      await sessionService.recalculateTaskEndDate();
      logger.info(
        'Successfully recalculated task.endDate and task.isPastEndDate',
      );
    } catch (e) {
      logger.error(
        'Failed to recalculate task.endDate and task.isPastEndDate: $e',
      );
    }

    // Recalculate task.dueDay
    try {
      await sessionService.recalculateTaskDueDay();
      logger.info('Successfully recalculated task.dueDay');
    } catch (e) {
      logger.error('Failed to recalculate task.dueDay: $e');
    }

    // Recalculate task.status
    try {
      await sessionService.recalculateTaskStatus();
      logger.info('Successfully recalculated task.status');
    } catch (e) {
      logger.error('Failed to recalculate task.status: $e');
    }

    // Reschedule notifications after task calculations
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.scheduleDeadlineReminder();
      logger.info('Successfully rescheduled notifications after task refresh');
    } catch (e) {
      logger.error('Failed to reschedule notifications after task refresh: $e');
    }
  }

  /// Handle notification_request_permissions event from dataAction trigger
  Future<void> _handleNotificationRequestPermissions() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;

      logger.info('Script triggered notification permission request');
      final granted = await notificationService.requestPermissions();

      if (granted) {
        logger.info('Notification permissions granted by user');
      } else {
        logger.warning(
          'Notification permissions denied or already decided by user',
        );
        logger.info(
          'Note: If previously denied, user must enable manually in device Settings',
        );
      }
    } catch (e) {
      logger.error('Failed to request notification permissions: $e');
    }
  }

  /// Handle notification_reschedule event from dataAction trigger
  Future<void> _handleNotificationReschedule() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.scheduleDeadlineReminder();
      logger.info('Successfully rescheduled notifications');
    } catch (e) {
      logger.error('Failed to reschedule notifications: $e');
    }
  }

  /// Handle notification_disable event from dataAction trigger
  Future<void> _handleNotificationDisable() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.cancelAllNotifications();
      logger.info('Successfully disabled all notifications');
    } catch (e) {
      logger.error('Failed to disable notifications: $e');
    }
  }

  /// Load a specific chat sequence by ID
  Future<ChatSequence> loadSequence(String sequenceId) async {
    await _sequenceManager.loadSequence(sequenceId);
    return _sequenceManager.currentSequence!;
  }

  /// Load the default chat script (for backward compatibility)
  Future<List<ChatMessage>> loadChatScript() async {
    // Use SequenceManager instead of SequenceLoader directly
    await _sequenceManager.loadSequence('onboarding_seq');
    return _sequenceManager.currentSequence!.messages;
  }

  bool hasMessage(int id) {
    return _sequenceManager.hasMessage(id);
  }

  ChatMessage? getMessageById(int id) {
    return _sequenceManager.getMessage(id);
  }

  /// Get initial messages for a specific sequence
  Future<List<ChatMessage>> getInitialMessages({
    String sequenceId = 'onboarding_seq',
  }) async {
    if (_sequenceManager.currentSequenceId != sequenceId) {
      await loadSequence(sequenceId);
    }

    // Start with the first message in the sequence
    final firstMessageId = _sequenceManager.getFirstMessageId();
    if (firstMessageId == null) {
      throw Exception('Sequence $sequenceId has no messages');
    }

    return await _getMessagesFromId(firstMessageId);
  }

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _sequenceManager.currentSequence;

  Future<List<ChatMessage>> getMessagesAfterChoice(int startId) async {
    return await _getMessagesFromId(startId);
  }

  Future<List<ChatMessage>> getMessagesAfterTextInput(
    int nextMessageId,
    String userInput,
  ) async {
    return await _getMessagesFromId(nextMessageId);
  }

  ChatMessage createUserResponseMessage(int id, String userInput) {
    // Move user message creation logic here instead of delegating to SequenceLoader
    return ChatMessage(
      id: id,
      text: userInput,
      delay: 0,
      sender: 'user',
      type: MessageType.user,
    );
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(
    ChatMessage textInputMessage,
    String userInput,
  ) async {
    // Use FlowOrchestrator for consistent processing
    await _flowOrchestrator.handleUserTextInput(textInputMessage, userInput);
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(
    ChatMessage choiceMessage,
    Choice selectedChoice,
  ) async {
    // Use FlowOrchestrator for consistent processing
    await _flowOrchestrator.handleUserChoice(choiceMessage, selectedChoice);
  }

  /// Process a single message template and replace variables with stored values
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplate(message);
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(
    List<ChatMessage> messages,
  ) async {
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplates(messages);
  }

  Future<List<ChatMessage>> _getMessagesFromId(int startId) async {
    logger.info('Processing messages from ID: $startId');

    final flowResponse = await _flowOrchestrator.processFrom(startId);
    return flowResponse.messages;
  }
}
