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
  
  // Private constructor to prevent instantiation
  ThemeConstants._();
}