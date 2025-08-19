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
      inst.applyBindings(update.bindings);
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
  ViewModelInstance? _viewModelInstance;
  final Map<String, ViewModelInstanceNumber> _numberProps = {};
  Map<String, double>? _pendingBindings;
  bool _bindingUnsupported = false;

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
    try {
      final loader = fileLoader ?? ((String asset) => File.asset(asset, riveFactory: Factory.rive));
      final file = await loader(show.asset);
      if (file == null) {
        logger.error('Overlay Rive load returned null for ${show.asset}', component: LogComponent.ui);
        _loading = false;
        return;
      }
      final controller = RiveWidgetController(file);
      _file = file;
      _controller = controller;
      _loading = false;

      if (show.useDataBinding || _pendingBindings != null) {
        _initDataBinding();
        if (_pendingBindings != null) {
          applyBindings(_pendingBindings!);
        }
      }

      // Notify host that controller is ready so the overlay can rebuild immediately
      onReady?.call();
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
    }
  }

  void applyBindings(Map<String, double> bindings) {
    if (_controller == null) {
      _pendingBindings = bindings;
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null || _bindingUnsupported) {
      _pendingBindings = bindings;
      return;
    }
    bindings.forEach((key, value) {
      var prop = _numberProps[key];
      prop ??= viewModel.number(key);
      if (prop != null) {
        _numberProps[key] = prop;
        prop.value = value;
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
}
