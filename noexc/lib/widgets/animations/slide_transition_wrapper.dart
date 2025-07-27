import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// Direction for slide animations
enum SlideDirection {
  up,
  down,
  left,
  right,
}

/// A reusable slide transition wrapper for consistent animations
class SlideTransitionWrapper extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;
  final bool slideInOnInit;
  final double offset;
  final VoidCallback? onComplete;

  const SlideTransitionWrapper({
    super.key,
    required this.child,
    this.direction = SlideDirection.up,
    this.duration = DesignTokens.animationNormal,
    this.curve = DesignTokens.curveStandard,
    this.slideInOnInit = true,
    this.offset = 1.0,
    this.onComplete,
  });

  @override
  State<SlideTransitionWrapper> createState() => _SlideTransitionWrapperState();
}

class _SlideTransitionWrapperState extends State<SlideTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: widget.slideInOnInit ? _getBeginOffset() : Offset.zero,
      end: widget.slideInOnInit ? Offset.zero : _getEndOffset(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.slideInOnInit) {
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

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.up:
        return Offset(0, widget.offset);
      case SlideDirection.down:
        return Offset(0, -widget.offset);
      case SlideDirection.left:
        return Offset(widget.offset, 0);
      case SlideDirection.right:
        return Offset(-widget.offset, 0);
    }
  }

  Offset _getEndOffset() {
    switch (widget.direction) {
      case SlideDirection.up:
        return Offset(0, -widget.offset);
      case SlideDirection.down:
        return Offset(0, widget.offset);
      case SlideDirection.left:
        return Offset(-widget.offset, 0);
      case SlideDirection.right:
        return Offset(widget.offset, 0);
    }
  }

  void slideIn() {
    _controller.forward();
  }

  void slideOut() {
    _controller.reverse();
  }

  void toggle() {
    if (_controller.status == AnimationStatus.completed) {
      slideOut();
    } else {
      slideIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: widget.child,
    );
  }
}

/// A widget that provides slide transition on visibility changes
class ConditionalSlideTransition extends StatefulWidget {
  final bool isVisible;
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;
  final double offset;

  const ConditionalSlideTransition({
    super.key,
    required this.isVisible,
    required this.child,
    this.direction = SlideDirection.up,
    this.duration = DesignTokens.animationNormal,
    this.curve = DesignTokens.curveStandard,
    this.offset = 1.0,
  });

  @override
  State<ConditionalSlideTransition> createState() => _ConditionalSlideTransitionState();
}

class _ConditionalSlideTransitionState extends State<ConditionalSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: _getHiddenOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConditionalSlideTransition oldWidget) {
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

  Offset _getHiddenOffset() {
    switch (widget.direction) {
      case SlideDirection.up:
        return Offset(0, widget.offset);
      case SlideDirection.down:
        return Offset(0, -widget.offset);
      case SlideDirection.left:
        return Offset(widget.offset, 0);
      case SlideDirection.right:
        return Offset(-widget.offset, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: widget.child,
    );
  }
}