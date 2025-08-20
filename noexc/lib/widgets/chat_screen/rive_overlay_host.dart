import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../services/logger_service.dart';
import '../../services/rive_overlay_service.dart';

/// Full-screen overlay host for displaying Rive animations above the UI.
typedef RiveFileLoader = Future<File?> Function(String asset);

class RiveOverlayHost extends StatefulWidget {
  final RiveOverlayService service;
  final int zone; // Which zone this host is responsible for
  final RiveFileLoader? fileLoader; // For tests or custom loading

  const RiveOverlayHost({
    super.key,
    required this.service,
    this.zone = 2,
    this.fileLoader,
  });

  @override
  State<RiveOverlayHost> createState() => _RiveOverlayHostState();
}

class _RiveOverlayHostState extends State<RiveOverlayHost>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StreamSubscription<RiveOverlayCommand>? _sub;
  // Multiple overlay instances per zone, keyed by id
  final Map<String, _OverlayInstance> _instances = {};
  // Queues per id for queued replacement
  final Map<String, List<RiveOverlayShow>> _queues = {};

  @override
  void initState() {
    super.initState();
    _sub = widget.service.commands.listen(_handleCommand);
  }

  Future<void> _handleCommand(RiveOverlayCommand cmd) async {
    if (cmd is RiveOverlayShow && cmd.zone == widget.zone) {
      await _onShow(cmd);
      return;
    }
    if (cmd is RiveOverlayHide && cmd.zone == widget.zone) {
      await _onHide(cmd);
      return;
    }
    if (cmd is RiveOverlayUpdate && cmd.zone == widget.zone) {
      await _onUpdate(cmd);
      return;
    }
  }

  Future<void> _onShow(RiveOverlayShow show) async {
    final id = show.id ?? 'zone-${widget.zone}-default';
    final existing = _instances[id];

    if (existing != null) {
      switch (show.policy) {
        case 'ignore':
          return;
        case 'queue':
          _queues.putIfAbsent(id, () => <RiveOverlayShow>[]).add(show);
          setState(() {});
          return;
        case 'replace':
        default:
          await existing.dispose();
          _instances.remove(id);
      }
    }

    final inst = _OverlayInstance(
      id: id,
      align: show.align,
      fit: show.fit,
      margin: show.margin,
      zIndex: show.zIndex,
      fileLoader: widget.fileLoader,
      onReady: () {
        if (mounted) setState(() {});
      },
    );
    _instances[id] = inst;
    setState(() {});

    // If a min-show is requested, set guard before scheduling hide
    if (show.minShowAfter != null) {
      inst.setMinShowGuard(show.minShowAfter!);
    }
    // Schedule auto-hide immediately so it works even if loading never completes
    if (show.autoHideAfter != null) {
      inst.scheduleHide(show.autoHideAfter!, _onInstanceHiddenCallback(id));
    }

    await inst.start(show);

    // Re-schedule hide to ensure guard/timing is honored after initialization (cancels previous timer)
    if (show.autoHideAfter != null) {
      inst.scheduleHide(show.autoHideAfter!, _onInstanceHiddenCallback(id));
    }
  }

  Future<void> _onHide(RiveOverlayHide hide) async {
    final all = hide.all || hide.id == null;
    if (all) {
      final ids = _instances.keys.toList(growable: false);
      for (final id in ids) {
        await _instances[id]?.hide();
        await _instances[id]?.dispose();
        _instances.remove(id);
        _drainQueueAndShowNext(id);
      }
      setState(() {});
      return;
    }

    final id = hide.id!;
    final inst = _instances[id];
    if (inst != null) {
      await inst.hide();
      await inst.dispose();
      _instances.remove(id);
      setState(() {});
      _drainQueueAndShowNext(id);
    }
  }

  Future<void> _onUpdate(RiveOverlayUpdate update) async {
    final id = update.id ?? 'zone-${widget.zone}-default';
    final inst = _instances[id];
    if (inst != null) {
      if (update.bindings != null) inst.applyBindings(update.bindings!);
      if (update.bindingsBool != null) inst.applyBoolBindings(update.bindingsBool!);
      if (update.bindingsString != null) inst.applyStringBindings(update.bindingsString!);
      if (update.bindingsColor != null) inst.applyColorBindings(update.bindingsColor!);
      if (update.autoHideAfter != null) {
        inst.scheduleHide(update.autoHideAfter!, _onInstanceHiddenCallback(id));
      }
    }
  }

  VoidCallback _onInstanceHiddenCallback(String id) {
    return () async {
      final inst = _instances[id];
      if (inst == null) return;
      await inst.dispose();
      _instances.remove(id);
      if (mounted) setState(() {});
      _drainQueueAndShowNext(id);
    };
  }

  void _drainQueueAndShowNext(String id) {
    final queue = _queues[id];
    if (queue == null || queue.isEmpty) return;
    final next = queue.removeAt(0);
    // Fire and forget; schedule show of next
    _onShow(next);
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final inst in _instances.values) {
      inst.dispose();
    }
    _instances.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasAny = _instances.isNotEmpty;
    return IgnorePointer(
      ignoring: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: hasAny
            ? Container(
                key: ValueKey('rive_overlay_zone_${widget.zone}_active'),
                // Full-screen box hosting stacked overlays
                alignment: Alignment.center,
                child: Stack(
                  children: () {
                    final list = _instances.values.toList();
                    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
                    return list.map((inst) => inst.build()).toList();
                  }(),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _OverlayInstance {
  final String id;
  Alignment align;
  Fit fit;
  EdgeInsets? margin;
  final int zIndex;
  final RiveFileLoader? fileLoader;
  final VoidCallback? onReady; // Notify host to rebuild when controller becomes ready

  File? _file;
  RiveWidgetController? _controller;
  bool _loading = false;
  Timer? _hideTimer;
  DateTime? _earliestHideAt;
  bool _hasPainted = false;
  int _framesPainted = 0;
  ViewModelInstance? _viewModelInstance;
  final Map<String, ViewModelInstanceNumber> _numberProps = {};
  final Map<String, dynamic> _boolProps = {};
  final Map<String, dynamic> _stringProps = {};
  final Map<String, dynamic> _colorProps = {};
  Map<String, double>? _pendingBindings;
  Map<String, bool>? _pendingBindingsBool;
  Map<String, String>? _pendingBindingsString;
  Map<String, int>? _pendingBindingsColor;
  Map<String, double>? _deferredBindings;
  Map<String, bool>? _deferredBindingsBool;
  Map<String, String>? _deferredBindingsString;
  Map<String, int>? _deferredBindingsColor;
  bool _bindingUnsupported = false;
  bool _loggedMissingProps = false;

  _OverlayInstance({
    required this.id,
    required this.align,
    required this.fit,
    required this.margin,
    required this.zIndex,
    required this.fileLoader,
    this.onReady,
  });

  Future<void> start(RiveOverlayShow show) async {
    _loading = true;
    if (show.minShowAfter != null) {
      _earliestHideAt = DateTime.now().add(show.minShowAfter!);
    }
    _pendingBindings = show.bindings;
    _pendingBindingsBool = show.bindingsBool;
    _pendingBindingsString = show.bindingsString;
    _pendingBindingsColor = show.bindingsColor;
    try {
      final loader = fileLoader ?? ((String asset) => File.asset(asset, riveFactory: Factory.rive));
      final file = await loader(show.asset);
      if (file == null) {
        logger.error('Overlay Rive load returned null for ${show.asset}', component: LogComponent.ui);
        _loading = false;
        return;
      }
      // Build controller with optional selectors when provided
      RiveWidgetController controller;
      if (show.artboard != null || show.stateMachine != null) {
        controller = RiveWidgetController(
          file,
          artboardSelector: show.artboard != null
              ? ArtboardSelector.byName(show.artboard!)
              : ArtboardSelector.byDefault(),
          stateMachineSelector: show.stateMachine != null
              ? StateMachineSelector.byName(show.stateMachine!)
              : StateMachineSelector.byDefault(),
        );
      } else {
        controller = RiveWidgetController(file);
      }
      _file = file;
      _controller = controller;
      _loading = false;

      if (show.useDataBinding ||
          _pendingBindings != null ||
          _pendingBindingsBool != null ||
          _pendingBindingsString != null ||
          _pendingBindingsColor != null) {
        _initDataBinding();
        // Attempt to select a specific data model/instance when requested
        _applyRequestedViewModelSelection(show);
        if (_pendingBindings != null) {
          // Apply initial bindings before first paint (do not defer)
          applyBindings(_pendingBindings!, deferIfPrePaint: false);
        }
        if (_pendingBindingsBool != null) {
          applyBoolBindings(_pendingBindingsBool!, deferIfPrePaint: false);
        }
        if (_pendingBindingsString != null) {
          applyStringBindings(_pendingBindingsString!, deferIfPrePaint: false);
        }
        if (_pendingBindingsColor != null) {
          applyColorBindings(_pendingBindingsColor!, deferIfPrePaint: false);
        }
      }

      // Notify host that controller is ready so the overlay can rebuild immediately
      onReady?.call();

      // Observe the next two frames: only allow updates after 2 paints to ensure
      // the initial state is visible for at least one full frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _framesPainted++;
        if (_framesPainted >= 2) {
          _hasPainted = true;
          _flushDeferredUpdates();
        } else {
          // schedule observation of the second frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _framesPainted++;
            _hasPainted = true; // allow updates after second frame
            _flushDeferredUpdates();
          });
        }
      });
    } catch (e) {
      logger.error('Overlay Rive load failed: $e', component: LogComponent.ui);
      _loading = false;
    }
  }

  // Set a min-show guard prior to start() to ensure early hide timers respect it
  void setMinShowGuard(Duration duration) {
    _earliestHideAt = DateTime.now().add(duration);
  }

  void scheduleHide(Duration after, VoidCallback onHidden) {
    _hideTimer?.cancel();
    final now = DateTime.now();
    var delay = after;
    if (_earliestHideAt != null && now.add(after).isBefore(_earliestHideAt!)) {
      // Ensure we don't hide before minShow; extend delay
      delay = _earliestHideAt!.difference(now);
    }
    _hideTimer = Timer(delay, () async {
      await hide();
      onHidden();
    });
  }

  Future<void> hide() async {
    final now = DateTime.now();
    if (_earliestHideAt != null && now.isBefore(_earliestHideAt!)) {
      final wait = _earliestHideAt!.difference(now);
      final completer = Completer<void>();
      Timer(wait, () => completer.complete());
      await completer.future;
    }
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  Future<void> dispose() async {
    _hideTimer?.cancel();
    _hideTimer = null;
    for (final prop in _numberProps.values) {
      prop.dispose();
    }
    _numberProps.clear();
    for (final prop in _boolProps.values) {
      try { prop.dispose(); } catch (_) {}
    }
    _boolProps.clear();
    for (final prop in _stringProps.values) {
      try { prop.dispose(); } catch (_) {}
    }
    _stringProps.clear();
    for (final prop in _colorProps.values) {
      try { prop.dispose(); } catch (_) {}
    }
    _colorProps.clear();
    _viewModelInstance?.dispose();
    _viewModelInstance = null;
    _controller?.dispose();
    _controller = null;
    _file?.dispose();
    _file = null;
  }

  void _initDataBinding() {
    final controller = _controller;
    if (controller == null || _bindingUnsupported || _viewModelInstance != null) {
      return;
    }
    try {
      _viewModelInstance = controller.dataBind(DataBind.auto());
    } catch (e) {
      _bindingUnsupported = true;
      logger.warning(
        'Data binding not available for this Rive asset: $e',
        component: LogComponent.ui,
      );
      _logRiveDiagnostics(context: 'dataBind-failure');
    }
  }

  void _applyRequestedViewModelSelection(RiveOverlayShow show) {
    // If no selection requested, keep auto-bound instance
    if (_viewModelInstance == null) return;
    final file = _file;
    if (file == null) return;
    try {
      // Resolve the artboard currently in effect
      final artboard = file.defaultArtboard();
      // Resolve the requested view model
      ViewModel? vm;
      if (show.dataModel != null && show.dataModel!.trim().isNotEmpty) {
        vm = file.viewModelByName(show.dataModel!.trim());
      } else if (artboard != null) {
        vm = file.defaultArtboardViewModel(artboard);
      }
      if (vm == null) return; // fallback to auto-bound instance

      // Create the requested instance
      final mode = (show.dataInstanceMode ?? 'default').toLowerCase();
      ViewModelInstance? requested;
      switch (mode) {
        case 'blank':
          requested = vm.createInstance();
          break;
        case 'byname':
          if (show.dataInstance != null) {
            requested = vm.createInstanceByName(show.dataInstance!);
          }
          break;
        case 'byindex':
          if (show.dataInstanceIndex != null) {
            requested = vm.createInstanceByIndex(show.dataInstanceIndex!);
          }
          break;
        case 'default':
        default:
          requested = vm.createDefaultInstance();
          break;
      }

      if (requested == null) {
        logger.warning('Rive data model selection failed to create instance (mode=${show.dataInstanceMode ?? 'default'})', component: LogComponent.ui);
        return;
      }

      // Current runtime does not expose explicit instance binding via DataBind.
      // Keep the auto-bound instance and dispose the requested one to avoid leaks.
      requested.dispose();
    } catch (e) {
      logger.warning('Rive data model selection encountered an error: $e', component: LogComponent.ui);
    }
  }

  void applyBindings(Map<String, double> bindings, {bool deferIfPrePaint = true}) {
    if (_controller == null || (!_hasPainted && deferIfPrePaint)) {
      // Defer updates until controller is ready and first frame has painted
      _deferredBindings ??= <String, double>{};
      _deferredBindings!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null || _bindingUnsupported) {
      _deferredBindings ??= <String, double>{};
      _deferredBindings!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    final missing = <String>[];
    bindings.forEach((key, value) {
      var prop = _numberProps[key];
      prop ??= viewModel.number(key);
      prop ??= _findNumberPropertyByPath(viewModel, key);
      if (prop != null) {
        _numberProps[key] = prop;
        prop.value = value;
      } else {
        missing.add(key);
      }
    });
    if (missing.isNotEmpty && !_loggedMissingProps) {
      _loggedMissingProps = true; // avoid spamming logs for repeated updates
      logger.warning(
        'Rive data binding: missing numeric properties ${missing.join(', ')}',
        component: LogComponent.ui,
      );
      _logRiveDiagnostics(context: 'missing-props');
    }
  }

  void applyBoolBindings(Map<String, bool> bindings, {bool deferIfPrePaint = true}) {
    if (_controller == null || (!_hasPainted && deferIfPrePaint)) {
      _deferredBindingsBool ??= <String, bool>{};
      _deferredBindingsBool!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null || _bindingUnsupported) {
      _deferredBindingsBool ??= <String, bool>{};
      _deferredBindingsBool!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    final missing = <String>[];
    bindings.forEach((key, value) {
      dynamic prop = _boolProps[key];
      prop ??= viewModel.boolean(key);
      prop ??= _findBoolPropertyByPath(viewModel, key);
      if (prop != null) {
        _boolProps[key] = prop;
        prop.value = value;
      } else {
        missing.add(key);
      }
    });
    if (missing.isNotEmpty && !_loggedMissingProps) {
      _loggedMissingProps = true;
      logger.warning('Rive data binding: missing bool properties ${missing.join(', ')}', component: LogComponent.ui);
      _logRiveDiagnostics(context: 'missing-bools');
    }
  }

  void applyStringBindings(Map<String, String> bindings, {bool deferIfPrePaint = true}) {
    if (_controller == null || (!_hasPainted && deferIfPrePaint)) {
      _deferredBindingsString ??= <String, String>{};
      _deferredBindingsString!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null || _bindingUnsupported) {
      _deferredBindingsString ??= <String, String>{};
      _deferredBindingsString!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    final missing = <String>[];
    bindings.forEach((key, value) {
      dynamic prop = _stringProps[key];
      prop ??= viewModel.string(key);
      prop ??= _findStringPropertyByPath(viewModel, key);
      if (prop != null) {
        _stringProps[key] = prop;
        prop.value = value;
      } else {
        missing.add(key);
      }
    });
    if (missing.isNotEmpty && !_loggedMissingProps) {
      _loggedMissingProps = true;
      logger.warning('Rive data binding: missing string properties ${missing.join(', ')}', component: LogComponent.ui);
      _logRiveDiagnostics(context: 'missing-strings');
    }
  }

  void applyColorBindings(Map<String, int> bindings, {bool deferIfPrePaint = true}) {
    if (_controller == null || (!_hasPainted && deferIfPrePaint)) {
      _deferredBindingsColor ??= <String, int>{};
      _deferredBindingsColor!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null || _bindingUnsupported) {
      _deferredBindingsColor ??= <String, int>{};
      _deferredBindingsColor!.addAll(bindings);
      _scheduleDeferredFlush();
      return;
    }
    final missing = <String>[];
    bindings.forEach((key, value) {
      dynamic prop = _colorProps[key];
      prop ??= viewModel.color(key);
      prop ??= _findColorPropertyByPath(viewModel, key);
      if (prop != null) {
        _colorProps[key] = prop;
        prop.value = value; // value is ARGB int
      } else {
        missing.add(key);
      }
    });
    if (missing.isNotEmpty && !_loggedMissingProps) {
      _loggedMissingProps = true;
      logger.warning('Rive data binding: missing color properties ${missing.join(', ')}', component: LogComponent.ui);
      _logRiveDiagnostics(context: 'missing-colors');
    }
  }

  void _flushDeferredUpdates() {
    if (_deferredBindings != null && _deferredBindings!.isNotEmpty) {
      final map = _deferredBindings!;
      _deferredBindings = null;
      applyBindings(map);
    }
    if (_deferredBindingsBool != null && _deferredBindingsBool!.isNotEmpty) {
      final map = _deferredBindingsBool!;
      _deferredBindingsBool = null;
      applyBoolBindings(map);
    }
    if (_deferredBindingsString != null && _deferredBindingsString!.isNotEmpty) {
      final map = _deferredBindingsString!;
      _deferredBindingsString = null;
      applyStringBindings(map);
    }
    if (_deferredBindingsColor != null && _deferredBindingsColor!.isNotEmpty) {
      final map = _deferredBindingsColor!;
      _deferredBindingsColor = null;
      applyColorBindings(map);
    }
    // If anything remains (e.g., view model still not ready), try again next frame
    if ((_deferredBindings != null && _deferredBindings!.isNotEmpty) ||
        (_deferredBindingsBool != null && _deferredBindingsBool!.isNotEmpty) ||
        (_deferredBindingsString != null && _deferredBindingsString!.isNotEmpty) ||
        (_deferredBindingsColor != null && _deferredBindingsColor!.isNotEmpty)) {
      _scheduleDeferredFlush();
    }
  }

  bool _deferredFlushScheduled = false;
  void _scheduleDeferredFlush() {
    if (_deferredFlushScheduled) return;
    _deferredFlushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredFlushScheduled = false;
      if (_hasPainted) {
        _flushDeferredUpdates();
      }
    });
  }

  Widget build() {
    return Align(
      key: ValueKey('rive_overlay_instance_$id'),
      alignment: align,
      child: _loading || _controller == null
          ? const SizedBox.shrink()
          : RiveWidget(controller: _controller!, fit: fit),
    );
  }

  void _logRiveDiagnostics({required String context}) {
    try {
      final file = _file;
      if (file == null) {
        logger.debug('[RiveDiag:$context] No file loaded');
        return;
      }
      // Default artboard diagnostics
      final artboard = file.defaultArtboard();
      final hasDefaultArtboard = artboard != null;
      bool hasDefaultSM = false;
      try {
        hasDefaultSM = artboard?.defaultStateMachine() != null;
      } catch (_) {}

      int? vmCount;
      bool hasDefaultVM = false;
      try {
        vmCount = file.viewModelCount;
      } catch (_) {}
      try {
        final vm = hasDefaultArtboard ? file.defaultArtboardViewModel(artboard) : null;
        hasDefaultVM = vm != null;
        vm?.dispose();
      } catch (_) {}

      logger.info(
        '[RiveDiag:$context] defaultArtboard=$hasDefaultArtboard, defaultStateMachine=$hasDefaultSM, viewModelCount=${vmCount ?? -1}, hasDefaultViewModel=$hasDefaultVM',
        component: LogComponent.ui,
      );
    } catch (_) {
      // Keep diagnostics non-fatal
    }
  }

  // --- Nested path helpers ---

  ViewModelInstance? _traverseToParent(ViewModelInstance root, List<String> segments) {
    var current = root;
    for (var i = 0; i < segments.length - 1; i++) {
      final seg = segments[i].trim();
      if (seg.isEmpty) return null;
      final next = current.viewModel(seg);
      if (next == null) {
        return null;
      }
      current = next;
    }
    return current;
  }

  ViewModelInstanceNumber? _findNumberPropertyByPath(ViewModelInstance root, String key) {
    try {
      final parts = key.split('/');
      if (parts.length < 2) return null;
      final parent = _traverseToParent(root, parts);
      return parent?.number(parts.last);
    } catch (_) {
      return null;
    }
  }

  dynamic _findBoolPropertyByPath(ViewModelInstance root, String key) {
    try {
      final parts = key.split('/');
      if (parts.length < 2) return null;
      final parent = _traverseToParent(root, parts);
      return parent?.boolean(parts.last);
    } catch (_) {
      return null;
    }
  }

  dynamic _findStringPropertyByPath(ViewModelInstance root, String key) {
    try {
      final parts = key.split('/');
      if (parts.length < 2) return null;
      final parent = _traverseToParent(root, parts);
      return parent?.string(parts.last);
    } catch (_) {
      return null;
    }
  }

  dynamic _findColorPropertyByPath(ViewModelInstance root, String key) {
    try {
      final parts = key.split('/');
      if (parts.length < 2) return null;
      final parent = _traverseToParent(root, parts);
      return parent?.color(parts.last);
    } catch (_) {
      return null;
    }
  }
}
