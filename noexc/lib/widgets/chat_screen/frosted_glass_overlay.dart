import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// A frosted glass overlay that creates a blur effect in the upper part of the screen
/// Messages will disappear behind this overlay as they scroll up
class FrostedGlassOverlay extends StatelessWidget {
  const FrostedGlassOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.paddingOf(context).top;
    final totalHeight = DesignTokens.frostedGlassHeight + safeAreaTop;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: totalHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DesignTokens.frostedGlassBlurRadius,
            sigmaY: DesignTokens.frostedGlassBlurRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                  Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
