import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../services/logger_service.dart';
import '../../services/rive_overlay_service.dart';

/// Full-screen overlay host for displaying Rive animations above the UI.
class RiveOverlayHost extends StatefulWidget {
  final RiveOverlayService service;
  final int zone; // Which zone this host is responsible for

  const RiveOverlayHost({
    super.key,
    required this.service,
    this.zone = 2,
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
  }

  Future<void> _show(RiveOverlayShow show) async {
    setState(() {
      _active = true;
      _align = show.align;
      _fit = show.fit;
      _margin = show.margin;
      _loading = true;
    });

    try {
      // Load Rive file and controller
      final file = await File.asset(show.asset, riveFactory: Factory.rive);
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

      // Schedule auto-hide if requested
      if (show.autoHideAfter != null) {
        Future.delayed(show.autoHideAfter!, () {
          if (mounted) _hide();
        });
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
    _controller?.dispose();
    _controller = null;
    _file?.dispose();
    _file = null;
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
                key: const ValueKey('rive_overlay_zone_2_active'),
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
