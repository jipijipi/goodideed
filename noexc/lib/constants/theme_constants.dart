import 'package:flutter/material.dart';

/// Theme-related constants
class ThemeConstants {
  // Color Scheme
  static const Color seedColor = Colors.deepPurple;
  
  // Theme Configuration
  static const bool useMaterial3 = true;
  
  // Message Bubble Colors
  static const Color botMessageBackgroundLight = Color(0xFFE0E0E0); // Colors.grey[200]
  static const Color userMessageTextColor = Colors.white;
  static const Color botMessageTextColor = Colors.black;
  static const Color avatarIconColor = Colors.white;
  static const Color hintTextColor = Colors.white70;
  
  // Private constructor to prevent instantiation
  ThemeConstants._();
}