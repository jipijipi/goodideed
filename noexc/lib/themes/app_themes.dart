import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/design_tokens.dart';

class AppThemes {
  static const String themeKey = AppConstants.themeKey;
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        surface: DesignTokens.lightBackground,
        primary: DesignTokens.lightPrimary,
        secondary: DesignTokens.lightSecondary,
        tertiary: DesignTokens.lightSecondary,
        onSurface: DesignTokens.brandBlack,
        onPrimary: DesignTokens.avatarIconColor,
        onSecondary: DesignTokens.avatarIconColor,
        onTertiary: DesignTokens.avatarIconColor,
      ),
      scaffoldBackgroundColor: DesignTokens.lightBackground,
      useMaterial3: DesignTokens.useMaterial3,
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        surface: DesignTokens.darkBackground,
        primary: DesignTokens.darkPrimary,
        secondary: DesignTokens.darkSecondary,
        tertiary: DesignTokens.darkSecondary,
        onSurface: DesignTokens.avatarIconColor,
        onPrimary: DesignTokens.avatarIconColor,
        onSecondary: DesignTokens.brandBlack,
        onTertiary: DesignTokens.brandBlack,
      ),
      scaffoldBackgroundColor: DesignTokens.darkBackground,
      useMaterial3: DesignTokens.useMaterial3,
    );
  }
  
  static ThemeMode getThemeMode(bool isDarkMode) {
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}