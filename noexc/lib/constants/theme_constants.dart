import 'package:flutter/material.dart';

/// Theme-related constants
class ThemeConstants {
  // Custom Brand Colors
  static const Color brandBeige = Color(0xFFE4D5C2);
  static const Color brandBluePurple = Color(0xFF484B85);
  static const Color brandOrangeRed = Color(0xFFE24825);
  
  // Light Theme Colors
  static const Color lightBackground = brandBeige;
  static const Color lightPrimary = brandBluePurple;
  static const Color lightSecondary = brandOrangeRed;
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF2D2A25);
  static const Color darkPrimary = Color(0xFF6B6FA3);
  static const Color darkSecondary = Color(0xFFD4412A);
  
  // Theme Configuration
  static const bool useMaterial3 = true;
  
  // Message Bubble Colors
  static const Color botMessageBackgroundLight = Color(0xFFFFFFFF); // White with alpha applied in widget
  static const Color botMessageBackgroundDark = Color(0xFF424242);
  static const Color userMessageBackground = Colors.white;
  static const Color userMessageTextColor = Colors.black;
  static const Color botMessageTextColor = Colors.black;
  static const Color avatarIconColor = Colors.white;
  static const Color hintTextColor = Colors.white70;
  
  // Interactive Element Colors - Light Theme
  static const Color choiceButtonColorLight = lightPrimary;
  static const Color choiceButtonTextLight = Colors.white;
  static const Color choiceButtonBorderLight = lightPrimary;
  static const Color inputAvatarBackgroundLight = lightSecondary;
  static const Color primaryButtonBackgroundLight = lightPrimary;
  static const Color primaryButtonTextLight = Colors.white;
  static const Color secondaryButtonBackgroundLight = Color(0xFFF3E5F5);
  static const Color secondaryButtonTextLight = lightPrimary;
  
  // Interactive Element Colors - Dark Theme  
  static const Color choiceButtonColorDark = darkPrimary;
  static const Color choiceButtonTextDark = Colors.white;
  static const Color choiceButtonBorderDark = darkPrimary;
  static const Color inputAvatarBackgroundDark = darkSecondary;
  static const Color primaryButtonBackgroundDark = darkPrimary;
  static const Color primaryButtonTextDark = Colors.white;
  static const Color secondaryButtonBackgroundDark = Color(0xFF424242);
  static const Color secondaryButtonTextDark = darkPrimary;
  
  // Theme-aware color getters
  static Color getChoiceButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? choiceButtonColorLight 
        : choiceButtonColorDark;
  }
  
  static Color getChoiceButtonText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? choiceButtonTextLight 
        : choiceButtonTextDark;
  }
  
  static Color getChoiceButtonBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? choiceButtonBorderLight 
        : choiceButtonBorderDark;
  }
  
  static Color getInputAvatarBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? inputAvatarBackgroundLight 
        : inputAvatarBackgroundDark;
  }
  
  static Color getPrimaryButtonBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? primaryButtonBackgroundLight 
        : primaryButtonBackgroundDark;
  }
  
  static Color getPrimaryButtonText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? primaryButtonTextLight 
        : primaryButtonTextDark;
  }
  
  static Color getSecondaryButtonBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? secondaryButtonBackgroundLight 
        : secondaryButtonBackgroundDark;
  }
  
  static Color getSecondaryButtonText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? secondaryButtonTextLight 
        : secondaryButtonTextDark;
  }
  
  // Private constructor to prevent instantiation
  ThemeConstants._();
}