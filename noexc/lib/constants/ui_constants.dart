import 'package:flutter/material.dart';

/// UI-related constants for consistent styling
class UIConstants {
  // Animation Durations
  static const Duration panelAnimationDuration = Duration(milliseconds: 300);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  
  // Animation Curves
  static const Curve panelAnimationCurve = Curves.easeInOut;
  static const Curve scrollAnimationCurve = Curves.easeOut;
  
  // Border Radius
  static const double messageBubbleRadius = 12.0;
  static const double panelTopRadius = 16.0;
  static const double standardBorderRadius = 8.0;
  
  // Spacing and Padding
  static const EdgeInsets chatListPadding = EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0);
  static const EdgeInsets messageBubblePadding = EdgeInsets.all(12.0);
  static const EdgeInsets panelHeaderPadding = EdgeInsets.all(16.0);
  static const EdgeInsets panelContentPadding = EdgeInsets.all(16.0);
  static const EdgeInsets panelEmptyStatePadding = EdgeInsets.all(32.0);
  static const EdgeInsets variableItemPadding = EdgeInsets.symmetric(vertical: 8.0);
  
  // Margins
  static const EdgeInsets messageBubbleMargin = EdgeInsets.only(bottom: 12.0);
  static const EdgeInsets choiceButtonMargin = EdgeInsets.only(bottom: 8.0);
  
  // Sizes
  static const double messageMaxWidthFactor = 0.7;
  static const double panelHeight = 400.0;
  static const double avatarSpacing = 12.0;
  static const double iconSpacing = 8.0;
  static const double messageSpacing = 8.0;
  static const double variableKeySpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double standardSpacing = 16.0;
  
  // Icon Sizes
  static const double sendIconSize = 20.0;
  static const double checkIconSize = 18.0;
  static const double buttonIconSize = 16.0;
  static const double panelIconSize = 20.0;
  static const double sequenceSelectorIconSize = 20.0;
  
  // Font Sizes
  static const double messageFontSize = 16.0;
  
  // Opacity Values
  static const double overlayOpacity = 0.3;
  static const double unselectedChoiceOpacity = 0.3;
  static const double selectedChoiceOpacity = 0.8;
  static const double shadowOpacity = 0.1;
  static const double hintTextOpacity = 0.7;
  static const double unselectedTextOpacity = 0.6;
  static const double choiceBorderOpacity = 0.5;
  
  // Border Widths
  static const double selectedChoiceBorderWidth = 2.0;
  static const double unselectedChoiceBorderWidth = 1.0;
  
  // Shadow Properties
  static const double shadowBlurRadius = 10.0;
  static const Offset shadowOffset = Offset(0, -2);
  
  // Private constructor to prevent instantiation
  UIConstants._();
}