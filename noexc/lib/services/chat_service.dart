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

  /// Subscribe to sequence change notifications
  void setOnSequenceChanged(void Function(String sequenceId) callback) {
    _sequenceManager.setOnSequenceChanged(callback);
  }

  /// Set callback for event notifications from dataAction triggers
  void setEventCallback(
    Future<void> Function(String eventType, Map<String, dynamic> data) callback,
  ) {
    _onEvent = callback;
  }

  /// Handle events from dataActionProcessor
  Future<void> _handleEvent(String eventType, Map<String, dynamic> data) async {
    logger.debug('ChatService received event: $eventType with data: $data');

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
      case 'overlay_rive_hide':
        await _handleOverlayRiveHide(data);
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
      final artboard = data['artboard'] as String?;
      final stateMachine = data['stateMachine'] as String?;
      // Optional layout scale for Fit.layout
      final layoutScaleFactor = () {
        final raw = data['layoutScaleFactor'];
        if (raw is num) return raw.toDouble();
        if (raw is String) return double.tryParse(raw);
        return null;
      }();
      final dataModel = data['dataModel'] as String?;
      final dataInstance = data['dataInstance'] as String?;
      final dataInstanceMode = data['dataInstanceMode'] as String?;
      final dataInstanceIndex = data['dataInstanceIndex'] as int?;
      final autoHideMs = data['autoHideMs'] as int?;
      final minShowMs = data['minShowMs'] as int?;
      final autoHide = autoHideMs != null ? Duration(milliseconds: autoHideMs) : null;
      final minShow = minShowMs != null ? Duration(milliseconds: minShowMs) : null;
      final bindings = await _resolveNumericBindings(data['bindings']);
      final bindingsBool = await _resolveBoolBindings(data['bindingsBool']);
      final bindingsString = await _resolveStringBindings(data['bindingsString']);
      final bindingsColor = await _resolveColorBindings(data['bindingsColor']);
      final useDataBinding = (data['useDataBinding'] as bool?) ?? false;
      final id = data['id'] as String?;
      final policy = (data['policy'] as String?)?.toLowerCase() ?? 'replace';
      final zIndex = (data['zIndex'] as int?) ?? 0;

      ServiceLocator.instance.riveOverlayService.show(
        asset: asset,
        align: align,
        fit: fit,
        layoutScaleFactor: layoutScaleFactor,
        autoHideAfter: autoHide,
        minShowAfter: minShow,
        zone: zone,
        bindings: bindings,
        bindingsBool: bindingsBool,
        bindingsString: bindingsString,
        bindingsColor: bindingsColor,
        artboard: artboard,
        stateMachine: stateMachine,
        dataModel: dataModel,
        dataInstance: dataInstance,
        dataInstanceMode: dataInstanceMode,
        dataInstanceIndex: dataInstanceIndex,
        useDataBinding: useDataBinding,
        id: id,
        policy: policy,
        zIndex: zIndex,
      );
    } catch (e) {
      logger.error('Failed to handle overlay_rive: $e');
    }
  }

  Future<void> _handleOverlayRiveUpdate(Map<String, dynamic> data) async {
    try {
      final zone = (data['zone'] as int?) ?? 2;
      final id = data['id'] as String?;
      final bindings = await _resolveNumericBindings(data['bindings']);
      final bindingsBool = await _resolveBoolBindings(data['bindingsBool']);
      final bindingsString = await _resolveStringBindings(data['bindingsString']);
      final bindingsColor = await _resolveColorBindings(data['bindingsColor']);
      final autoHideMs = data['autoHideMs'] as int?;
      final autoHide = autoHideMs != null ? Duration(milliseconds: autoHideMs) : null;
      // Allow auto-hide-only updates: proceed if autoHide is set even when all bindings are empty
      final hasAnyBindings = (bindings != null && bindings.isNotEmpty) ||
          (bindingsBool != null && bindingsBool.isNotEmpty) ||
          (bindingsString != null && bindingsString.isNotEmpty) ||
          (bindingsColor != null && bindingsColor.isNotEmpty);
      if (!hasAnyBindings && autoHide == null) return;
      ServiceLocator.instance.riveOverlayService.update(
        zone: zone,
        bindings: bindings,
        bindingsBool: bindingsBool,
        bindingsString: bindingsString,
        bindingsColor: bindingsColor,
        id: id,
        autoHideAfter: autoHide,
      );
    } catch (e) {
      logger.error('Failed to handle overlay_rive_update: $e');
    }
  }

  Future<void> _handleOverlayRiveHide(Map<String, dynamic> data) async {
    try {
      final zone = (data['zone'] as int?) ?? 2;
      final id = data['id'] as String?;
      final all = (data['all'] as bool?) ?? (id == null);
      ServiceLocator.instance.riveOverlayService.hide(zone: zone, id: id, all: all);
    } catch (e) {
      logger.error('Failed to handle overlay_rive_hide: $e');
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

  Future<Map<String, bool>?> _resolveBoolBindings(dynamic raw) async {
    if (raw is! Map) return null;
    final Map<String, bool> result = {};
    final templating = ServiceLocator.instance.templatingService;
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      bool? resolved;
      if (value is bool) {
        resolved = value;
      } else if (value is num) {
        resolved = value != 0;
      } else if (value is String) {
        final s = value.trim().toLowerCase();
        if (s == 'true' || s == 'false') {
          resolved = s == 'true';
        } else if (s == '1' || s == '0') {
          resolved = s == '1';
        } else {
          final template = value.contains('{') ? value : '{${value.trim()}}';
          final processed = await templating.processTemplate(template);
          final p = processed.trim().toLowerCase();
          if (p == 'true' || p == 'false') {
            resolved = p == 'true';
          } else if (p == '1' || p == '0') {
            resolved = p == '1';
          }
        }
      }
      if (resolved != null) result[key] = resolved;
    }
    return result;
  }

  Future<Map<String, String>?> _resolveStringBindings(dynamic raw) async {
    if (raw is! Map) return null;
    final Map<String, String> result = {};
    final templating = ServiceLocator.instance.templatingService;
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      String? resolved;
      if (value is String) {
        // If it looks like a template path, process; else use directly.
        if (value.contains('{')) {
          resolved = await templating.processTemplate(value);
        } else if (value.contains('.')) {
          final processed = await templating.processTemplate('{${value.trim()}}');
          resolved = processed;
        } else {
          resolved = value;
        }
      } else {
        resolved = value?.toString();
      }
      if (resolved != null) result[key] = resolved;
    }
    return result;
  }

  Future<Map<String, int>?> _resolveColorBindings(dynamic raw) async {
    if (raw is! Map) return null;
    final Map<String, int> result = {};
    final templating = ServiceLocator.instance.templatingService;
    int? parseColor(String s) {
      var v = s.trim();
      if (v.startsWith('#')) v = v.substring(1);
      if (v.startsWith('0x')) v = v.substring(2);
      // If RRGGBB, add opaque alpha.
      if (v.length == 6) v = 'FF$v';
      if (v.length != 8) return null;
      final n = int.tryParse(v, radix: 16);
      return n;
    }
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      int? resolved;
      if (value is int) {
        resolved = value;
      } else if (value is String) {
        resolved = parseColor(value);
        if (resolved == null) {
          final processed = await templating.processTemplate(
            value.contains('{') ? value : '{${value.trim()}}',
          );
          resolved = parseColor(processed);
        }
      }
      if (resolved != null) result[key] = resolved;
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
      case 'layout':
        return Fit.layout;
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
      // Show typing indicator for testing
      if (_onEvent != null) {
        await _onEvent!('show_typing_indicator', {'reason': 'recalculating_task_data'});
      }

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

    // Recalculate task.isPastDeadline (CRITICAL: was missing!)
    try {
      await sessionService.recalculatePastDeadline();
      logger.info('Successfully recalculated task.isPastDeadline');
    } catch (e) {
      logger.error('Failed to recalculate task.isPastDeadline: $e');
    }

    // Recalculate task.isActiveDay
    try {
      await sessionService.recalculateActiveDay();
      logger.info('Successfully recalculated task.isActiveDay');
    } catch (e) {
      logger.error('Failed to recalculate task.isActiveDay: $e');
    }

    // Recalculate time range variables (isBeforeStart, isInTimeRange)
    try {
      await sessionService.recalculateTimeRange();
      logger.info('Successfully recalculated task.isBeforeStart and task.isInTimeRange');
    } catch (e) {
      logger.error('Failed to recalculate time range variables: $e');
    }

    // Recalculate session.timeOfDay
    try {
      await sessionService.recalculateTimeOfDay();
      logger.info('Successfully recalculated session.timeOfDay');
    } catch (e) {
      logger.error('Failed to recalculate session.timeOfDay: $e');
    }

    // Reschedule notifications after task calculations
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.scheduleDeadlineReminder();
      logger.info('Successfully rescheduled notifications after task refresh');
    } catch (e) {
      logger.error('Failed to reschedule notifications after task refresh: $e');
    } finally {
      // Hide typing indicator when all calculations are complete
      if (_onEvent != null) {
        await _onEvent!('hide_typing_indicator', {'reason': 'recalculating_task_data'});
      }
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
      // Show typing indicator while scheduling notifications
      if (_onEvent != null) {
        await _onEvent!('show_typing_indicator', {'reason': 'scheduling_notifications'});
      }

      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.scheduleDeadlineReminder();
      logger.info('Successfully rescheduled notifications');
    } catch (e) {
      logger.error('Failed to reschedule notifications: $e');
    } finally {
      // Hide typing indicator when done
      if (_onEvent != null) {
        await _onEvent!('hide_typing_indicator', {'reason': 'scheduling_notifications'});
      }
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
    // TODO(noexc): Migrate callers to ChatService.applyChoiceAndContinue
    // and rely on FlowResponse to manage continuation. This wrapper will be
    // removed after UI migrates off direct message lists.
    return await _getMessagesFromId(startId);
  }

  Future<List<ChatMessage>> getMessagesAfterTextInput(
    int nextMessageId,
    String userInput,
  ) async {
    // TODO(noexc): Migrate callers to ChatService.applyTextAndContinue and
    // rely on FlowResponse; this wrapper exists for compatibility.
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
    // TODO(noexc): Keep for compatibility; prefer running flows via start/
    // continue/apply* methods to minimize piecemeal processing.
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplate(message);
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(
    List<ChatMessage> messages,
  ) async {
    // TODO(noexc): Keep for compatibility; prefer running flows via start/
    // continue/apply* methods to minimize piecemeal processing.
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplates(messages);
  }

  Future<List<ChatMessage>> _getMessagesFromId(int startId) async {
    logger.info('Processing messages from ID: $startId');

    final flowResponse = await _flowOrchestrator.processFrom(startId);
    return flowResponse.messages;
  }

  // Facade seed: start a sequence and return flow response
  Future<FlowResponse> start(String sequenceId) async {
    await _sequenceManager.loadSequence(sequenceId);
    final firstMessageId = _sequenceManager.getFirstMessageId();
    if (firstMessageId == null) {
      throw Exception('Sequence $sequenceId has no messages');
    }
    return await _flowOrchestrator.processFrom(firstMessageId);
  }

  // Facade seed: continue flow from a message id
  Future<FlowResponse> continueFrom(int messageId) async {
    return await _flowOrchestrator.processFrom(messageId);
  }

  /// Store choice value (if any) and continue the flow from the appropriate point.
  /// - If the choice targets a new sequence, loads it and starts from its first message.
  /// - Otherwise, continues from the choice's nextMessageId.
  Future<FlowResponse> applyChoiceAndContinue(
    ChatMessage choiceMessage,
    Choice selectedChoice,
  ) async {
    // Persist choice via renderer/processor for consistency
    await _flowOrchestrator.handleUserChoice(choiceMessage, selectedChoice);

    if (selectedChoice.sequenceId != null && selectedChoice.sequenceId!.isNotEmpty) {
      return await start(selectedChoice.sequenceId!);
    }

    if (selectedChoice.nextMessageId != null) {
      return await continueFrom(selectedChoice.nextMessageId!);
    }

    logger.warning('Choice has no next action; returning no-op response');
    return const FlowResponse(messages: [], isComplete: true);
  }

  /// Store text input (if any) and continue the flow from the message's nextMessageId.
  Future<FlowResponse> applyTextAndContinue(
    ChatMessage textInputMessage,
    String userInput,
  ) async {
    await _flowOrchestrator.handleUserTextInput(textInputMessage, userInput);

    if (textInputMessage.nextMessageId != null) {
      return await continueFrom(textInputMessage.nextMessageId!);
    }

    logger.warning('Text input has no continuation; returning no-op response');
    return const FlowResponse(messages: [], isComplete: true);
  }
}
