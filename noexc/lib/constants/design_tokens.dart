import 'package:flutter/material.dart';

/// Comprehensive design tokens for consistent UI styling
/// This centralizes all design values to minimize merge conflicts
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ==================== COLORS ====================
  
  /// Primary color palette
  static const Color primarySeed = Colors.deepPurple;
  
  /// Brand colors
  static const Color brandPrimary = Color(0xFF6750A4);
  static const Color brandSecondary = Color(0xFF625B71);
  static const Color brandTertiary = Color(0xFF7D5260);
  
  /// Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  /// Chat-specific colors
  static const Color botMessageBackgroundLight = Color(0xFFE0E0E0);
  static const Color botMessageBackgroundDark = Color(0xFF424242);
  static const Color userMessageBackground = brandPrimary;
  static const Color botMessageTextLight = Color(0xFF1C1B1F);
  static const Color botMessageTextDark = Color(0xFFE6E1E5);
  static const Color userMessageText = Colors.white;
  static const Color avatarIconColor = Colors.white;
  
  /// Interactive colors
  static const Color hintTextColor = Color(0xFFB3B3B3);
  static const Color disabledColor = Color(0xFF9E9E9E);
  static const Color selectedColor = Color(0xFF6750A4);
  static const Color unselectedColor = Color(0xFFB0B0B0);
  
  // ==================== TYPOGRAPHY ====================
  
  /// Font families
  static const String primaryFontFamily = 'Roboto';
  static const String displayFontFamily = 'Roboto';
  
  /// Font sizes
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;
  
  /// Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightLoose = 1.6;
  
  /// Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  // ==================== SPACING ====================
  
  /// Base spacing unit (4px)
  static const double spaceUnit = 4.0;
  
  /// Spacing scale
  static const double spaceXS = spaceUnit; // 4px
  static const double spaceS = spaceUnit * 2; // 8px
  static const double spaceM = spaceUnit * 3; // 12px
  static const double spaceL = spaceUnit * 4; // 16px
  static const double spaceXL = spaceUnit * 6; // 24px
  static const double spaceXXL = spaceUnit * 8; // 32px
  static const double spaceXXXL = spaceUnit * 12; // 48px
  
  /// Component-specific spacing
  static const double chatListTopPadding = 80.0;
  static const double panelHeight = 400.0;
  static const double avatarSpacing = spaceM;
  static const double messageSpacing = spaceS;
  static const double variableKeySpacing = spaceL;
  
  // ==================== SIZING ====================
  
  /// Icon sizes
  static const double iconXS = 16.0;
  static const double iconS = 18.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;
  
  /// Button heights
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 40.0;
  static const double buttonHeightL = 48.0;
  
  /// Message constraints
  static const double messageMaxWidthFactor = 0.7;
  
  // ==================== BORDER RADIUS ====================
  
  /// Border radius scale
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0; // Fully rounded
  
  /// Component-specific radius
  static const double messageBubbleRadius = radiusM;
  static const double panelTopRadius = radiusL;
  static const double buttonRadius = radiusS;
  static const double cardRadius = radiusM;
  
  // ==================== ELEVATION ====================
  
  /// Shadow elevations
  static const double elevationNone = 0.0;
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  
  /// Shadow properties
  static const double shadowBlurRadius = 10.0;
  static const Offset shadowOffset = Offset(0, -2);
  static const double shadowOpacity = 0.1;
  
  // ==================== ANIMATION ====================
  
  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  
  /// Animation curves
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveBounce = Curves.elasticOut;
  
  // ==================== OPACITY ====================
  
  /// Opacity levels
  static const double opacityInvisible = 0.0;
  static const double opacityFaint = 0.1;
  static const double opacityLight = 0.3;
  static const double opacityMedium = 0.5;
  static const double opacityStrong = 0.7;
  static const double opacityOpaque = 1.0;
  
  /// Component-specific opacity
  static const double overlayOpacity = opacityLight;
  static const double unselectedChoiceOpacity = opacityLight;
  static const double selectedChoiceOpacity = opacityStrong;
  static const double hintTextOpacity = opacityStrong;
  static const double unselectedTextOpacity = 0.6;
  static const double choiceBorderOpacity = opacityMedium;
  
  // ==================== BORDER ====================
  
  /// Border widths
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 4.0;
  
  /// Component-specific border widths
  static const double selectedChoiceBorderWidth = borderMedium;
  static const double unselectedChoiceBorderWidth = borderThin;
  
  // ==================== PREDEFINED EDGE INSETS ====================
  
  /// Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingL = EdgeInsets.all(spaceL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spaceXL);
  
  /// Symmetric padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spaceS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spaceM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spaceL);
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spaceS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spaceM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spaceL);
  
  /// Component-specific padding
  static const EdgeInsets chatListPadding = EdgeInsets.fromLTRB(spaceL, chatListTopPadding, spaceL, spaceL);
  static const EdgeInsets messageBubblePadding = paddingM;
  static const EdgeInsets panelHeaderPadding = paddingL;
  static const EdgeInsets panelContentPadding = paddingL;
  static const EdgeInsets panelEmptyStatePadding = EdgeInsets.all(spaceXXL);
  static const EdgeInsets variableItemPadding = paddingVerticalS;
  
  /// Margin presets
  static const EdgeInsets marginXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets marginS = EdgeInsets.all(spaceS);
  static const EdgeInsets marginM = EdgeInsets.all(spaceM);
  static const EdgeInsets marginL = EdgeInsets.all(spaceL);
  
  /// Component-specific margins
  static const EdgeInsets messageBubbleMargin = EdgeInsets.only(bottom: spaceM);
  static const EdgeInsets choiceButtonMargin = EdgeInsets.only(bottom: spaceS);
}