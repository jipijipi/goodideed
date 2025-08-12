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
  bool _active = false;
  Alignment _align = Alignment.center;
  Fit _fit = Fit.contain;
  EdgeInsets? _margin;
  File? _file;
  RiveWidgetController? _controller;
  bool _loading = false;
  Timer? _hideTimer;
  ViewModelInstance? _viewModelInstance;
  final Map<String, ViewModelInstanceNumber> _numberProps = {};
  Map<String, double>? _pendingBindings;

  @override
  void initState() {
    super.initState();
    _sub = widget.service.commands.listen(_handleCommand);
  }

  Future<void> _handleCommand(RiveOverlayCommand cmd) async {
    if (cmd is RiveOverlayShow && cmd.zone == widget.zone) {
      await _show(cmd);
      return;
    }
    if (cmd is RiveOverlayHide && cmd.zone == widget.zone) {
      _hide();
      return;
    }
    if (cmd is RiveOverlayUpdate && cmd.zone == widget.zone) {
      _applyBindings(cmd.bindings);
      return;
    }
  }

  Future<void> _show(RiveOverlayShow show) async {
    setState(() {
      _active = true;
      _align = show.align;
      _fit = show.fit;
      _margin = show.margin;
      _loading = true;
    });

    // Schedule auto-hide immediately, independent of load completion
    _hideTimer?.cancel();
    if (show.autoHideAfter != null) {
      _hideTimer = Timer(show.autoHideAfter!, () {
        if (mounted) _hide();
      });
    }

    // Stash incoming bindings until controller is ready
    _pendingBindings = show.bindings;

    try {
      // Load Rive file and controller
      final loader = widget.fileLoader ??
          ((String asset) => File.asset(asset, riveFactory: Factory.rive));
      final file = await loader(show.asset);
      if (file == null) {
        if (mounted) {
          logger.error('Overlay Rive load returned null for ${show.asset}', component: LogComponent.ui);
          setState(() {
            _loading = false;
            _active = false;
          });
        }
        return;
      }
      final controller = RiveWidgetController(file);
      if (!mounted) {
        // Clean up if unmounted
        controller.dispose();
        file.dispose();
        return;
      }
      setState(() {
        _file = file;
        _controller = controller;
        _loading = false;
      });

      // Initialize data binding and apply pending bindings
      _initDataBinding();
      if (_pendingBindings != null) {
        _applyBindings(_pendingBindings!);
      }
    } catch (e) {
      logger.error('Overlay Rive load failed: $e', component: LogComponent.ui);
      if (mounted) {
        setState(() {
          _loading = false;
          _active = false;
        });
      }
    }
  }

  void _hide() {
    setState(() {
      _active = false;
    });
    _disposeRive();
  }

  void _disposeRive() {
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
    if (controller == null) return;
    _viewModelInstance ??= controller.dataBind(DataBind.auto());
  }

  void _applyBindings(Map<String, double> bindings) {
    if (_controller == null) {
      _pendingBindings = bindings;
      return;
    }
    _initDataBinding();
    final viewModel = _viewModelInstance;
    if (viewModel == null) {
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

  @override
  void dispose() {
    _sub?.cancel();
    _disposeRive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Host container always present; content toggles based on _active
    return IgnorePointer(
      ignoring: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _active
            ? Container(
                key: ValueKey('rive_overlay_zone_${widget.zone}_active'),
                alignment: _align,
                margin: _margin,
                // Ensure overlay sits above everything with a full-screen box
                child: _loading || _controller == null
                    ? const SizedBox.shrink()
                    : RiveWidget(controller: _controller!, fit: _fit),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
