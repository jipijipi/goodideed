import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Constants for the Tristopher app

// App Theme Colors
class AppColors {
  static const Color primaryText = Color.fromARGB(255, 42, 21, 1);
  static const Color accentColor = Color(0xFFFBBC05);
  static const Color backgroundColor = Color.fromARGB(255, 246, 240, 244); // Light Beige
}

// App Routes
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String mainChat = '/main';
  static const String goalStake = '/goal';
  static const String account = '/account';
}

// Text Styles
class AppTextStyles {
  // Special Elite font for Tristopher's messages (typewriter feel)
  static TextStyle tristopherText({double size = 20, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.specialElite(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.primaryText,
    );
  }

  // Cutive font for user's messages and UI text
  static TextStyle userText({
    double size = 16,
    FontWeight weight = FontWeight.normal,
    double alpha = 0.8,
    bool italic = true,
  }) {
    return GoogleFonts.cutive(
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: AppColors.primaryText.withAlpha((alpha * 255).toInt()),
    );
  }

  // Header styles
  static TextStyle header({double size = 24}) {
    return GoogleFonts.specialElite(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
    );
  }

  // Button text
  static TextStyle buttonText() {
    return GoogleFonts.cutive(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
    );
  }
  // Body text
  static TextStyle body() {
    return GoogleFonts.cutive(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
    );
  }
}

// Anti-Charity Options
class AntiCharities {
  static const List<Map<String, String>> options = [
    {
      'id': 'charity1',
      'name': 'Climate Denial Organization',
      'description': 'An organization that actively works against climate change initiatives.'
    },
    {
      'id': 'charity2',
      'name': 'Corporate Lobbying Group',
      'description': 'A lobbying group that advocates for reduced corporate regulation.'
    },
    {
      'id': 'charity3',
      'name': 'Political Campaign',
      'description': 'A political campaign you strongly oppose.'
    },
  ];
}
