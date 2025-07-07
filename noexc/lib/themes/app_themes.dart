import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';

class AppThemes {
  static const String themeKey = AppConstants.themeKey;
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeConstants.seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: ThemeConstants.useMaterial3,
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeConstants.seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: ThemeConstants.useMaterial3,
    );
  }
  
  static ThemeMode getThemeMode(bool isDarkMode) {
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}