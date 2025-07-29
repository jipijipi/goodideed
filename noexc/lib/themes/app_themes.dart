import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';

class AppThemes {
  static const String themeKey = AppConstants.themeKey;
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        surface: ThemeConstants.lightBackground,
        primary: ThemeConstants.lightPrimary,
        secondary: ThemeConstants.lightSecondary,
        tertiary: ThemeConstants.lightSecondary,
        onSurface: Colors.black,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
      ),
      scaffoldBackgroundColor: ThemeConstants.lightBackground,
      useMaterial3: ThemeConstants.useMaterial3,
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        surface: ThemeConstants.darkBackground,
        primary: ThemeConstants.darkPrimary,
        secondary: ThemeConstants.darkSecondary,
        tertiary: ThemeConstants.darkSecondary,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onTertiary: Colors.black,
      ),
      scaffoldBackgroundColor: ThemeConstants.darkBackground,
      useMaterial3: ThemeConstants.useMaterial3,
    );
  }
  
  static ThemeMode getThemeMode(bool isDarkMode) {
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}