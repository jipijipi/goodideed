import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// A reusable fade transition wrapper for consistent animations
class FadeTransitionWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool fadeInOnInit;
  final VoidCallback? onComplete;

  const FadeTransitionWrapper({
    super.key,
    required this.child,
    this.duration = DesignTokens.animationNormal,
    this.curve = DesignTokens.curveStandard,
    this.fadeInOnInit = true,
    this.onComplete,
  });

  @override
  State<FadeTransitionWrapper> createState() => _FadeTransitionWrapperState();
}

class _FadeTransitionWrapperState extends State<FadeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacity = Tween<double>(
      begin: widget.fadeInOnInit ? 0.0 : 1.0,
      end: widget.fadeInOnInit ? 1.0 : 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.fadeInOnInit) {
      _controller.forward().then((_) => widget.onComplete?.call());
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void fadeIn() {
    _controller.forward();
  }

  void fadeOut() {
    _controller.reverse();
  }

  void toggle() {
    if (_controller.status == AnimationStatus.completed) {
      fadeOut();
    } else {
      fadeIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// A widget that provides fade transition on visibility changes
class ConditionalFadeTransition extends StatefulWidget {
  final bool isVisible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ConditionalFadeTransition({
    super.key,
    required this.isVisible,
    required this.child,
    this.duration = DesignTokens.animationNormal,
    this.curve = DesignTokens.curveStandard,
  });

  @override
  State<ConditionalFadeTransition> createState() =>
      _ConditionalFadeTransitionState();
}

class _ConditionalFadeTransitionState extends State<ConditionalFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConditionalFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
