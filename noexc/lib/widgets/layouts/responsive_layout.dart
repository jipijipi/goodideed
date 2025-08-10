import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// Responsive layout breakpoints
class BreakPoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= BreakPoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= BreakPoints.tablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// A responsive builder that provides screen type information
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = _getScreenType(constraints.maxWidth);
        return builder(context, screenType);
      },
    );
  }

  ScreenType _getScreenType(double width) {
    if (width >= BreakPoints.desktop) {
      return ScreenType.desktop;
    } else if (width >= BreakPoints.tablet) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }
}

enum ScreenType { mobile, tablet, desktop }

/// Extension to get responsive values based on screen type
extension ResponsiveExtension on BuildContext {
  ScreenType get screenType {
    final width = MediaQuery.of(this).size.width;
    if (width >= BreakPoints.desktop) {
      return ScreenType.desktop;
    } else if (width >= BreakPoints.tablet) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// Get responsive padding based on screen type
  EdgeInsets get responsivePadding {
    switch (screenType) {
      case ScreenType.mobile:
        return DesignTokens.paddingL;
      case ScreenType.tablet:
        return DesignTokens.paddingXL;
      case ScreenType.desktop:
        return const EdgeInsets.all(DesignTokens.spaceXXXL);
    }
  }

  /// Get responsive spacing based on screen type
  double get responsiveSpacing {
    switch (screenType) {
      case ScreenType.mobile:
        return DesignTokens.spaceL;
      case ScreenType.tablet:
        return DesignTokens.spaceXL;
      case ScreenType.desktop:
        return DesignTokens.spaceXXL;
    }
  }

  /// Get responsive font size multiplier
  double get fontSizeMultiplier {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.1;
      case ScreenType.desktop:
        return 1.2;
    }
  }
}

/// A widget that provides max width constraints for content
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool center;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? _getDefaultMaxWidth(context.screenType);

    return Container(
      width: double.infinity,
      alignment: center ? Alignment.center : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }

  double _getDefaultMaxWidth(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return double.infinity;
      case ScreenType.tablet:
        return 600;
      case ScreenType.desktop:
        return 800;
    }
  }
}
