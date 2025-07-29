import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/chat_screen/choice_buttons.dart';

/// Comprehensive design tokens for consistent UI styling
/// This centralizes all design values to minimize merge conflicts
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ==================== COLORS ====================
  
  /// Custom Brand Colors (Your Design System)
  static const Color brandBeige = Color(0xFFE4D5C2);
  static const Color brandBluePurple = Color(0xFF484B85);
  static const Color brandOrangeRed = Color(0xFFE24825);
  
  /// Light Theme Colors
  static const Color lightBackground = brandBeige;
  static const Color lightPrimary = brandBluePurple;
  static const Color lightSecondary = brandOrangeRed;
  
  /// Dark Theme Colors
  static const Color darkBackground = Color(0xFF2D2A25);
  static const Color darkPrimary = Color(0xFF6B6FA3);
  static const Color darkSecondary = Color(0xFFD4412A);
  
  /// Legacy Brand Colors (Deprecated - use custom brand colors above)
  static const Color primarySeed = Colors.deepPurple;
  static const Color brandPrimary = Color(0xFF6750A4);
  static const Color brandSecondary = Color(0xFF625B71);
  static const Color brandTertiary = Color(0xFF7D5260);
  
  /// Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  /// Message Bubble Colors
  static const Color botMessageBackgroundLight = Color.fromARGB(150, 255, 255, 255); // Full opacity white
  static const Color botMessageBackgroundLightWithAlpha = Color.fromARGB(127, 255, 255, 255); // 80% white for alpha variant
  static const Color botMessageBackgroundDark = Color(0xFF424242);
  static const Color userMessageBackground = Colors.white;
  static const Color userMessageTextColor = Colors.black;
  static const Color botMessageTextColor = Colors.black;
  static const Color botMessageTextLight = Color(0xFF1C1B1F);
  static const Color botMessageTextDark = Color(0xFFE6E1E5);
  static const Color userMessageText = Colors.white; // Legacy
  static const Color avatarIconColor = Colors.white;
  
  /// Selected Choice Button Colors - Light Theme
  static const Color selectedChoiceColorLight = Color(0xFFFFFFFF);     // Full opacity white
  static const Color selectedChoiceTextLight = Colors.black;
  static const Color selectedChoiceBorderLight = Color.fromARGB(255, 255, 255, 255);          // Brand blue #484B85
  
  /// Unselected Choice Button Colors - Light Theme (with direct alpha)
  static const Color unselectedChoiceColorLight = Color.fromARGB(250, 255, 255, 255);    // 30% white
  static const Color unselectedChoiceTextLight = Color.fromARGB(200, 0, 0, 0);     // 60% black
  static const Color unselectedChoiceBorderLight = Color.fromARGB(128, 255, 255, 255);   // 50% brand blue
  
  /// Selected Choice Button Colors - Dark Theme
  static const Color selectedChoiceColorDark = darkPrimary;             // Brand blue dark #6B6FA3
  static const Color selectedChoiceTextDark = Colors.white;
  static const Color selectedChoiceBorderDark = darkPrimary;
  
  /// Unselected Choice Button Colors - Dark Theme (with direct alpha)
  static const Color unselectedChoiceColorDark = Color(0x4D6B6FA3);     // 30% brand blue dark
  static const Color unselectedChoiceTextDark = Color(0x99FFFFFF);      // 60% white
  static const Color unselectedChoiceBorderDark = Color(0x806B6FA3);    // 50% brand blue dark

  /// Disabled Choice Button Colors - Light Theme (with direct alpha - most muted)
  static const Color disabledChoiceColorLight = Color.fromARGB(0, 255, 255, 255);      // 10% white
  static const Color disabledChoiceTextLight = Color(0x4D000000);       // 30% black
  static const Color disabledChoiceBorderLight = Color(0x33484B85);     // 20% brand blue
  
  /// Disabled Choice Button Colors - Dark Theme (with direct alpha - most muted)
  static const Color disabledChoiceColorDark = Color(0x1A6B6FA3);       // 10% brand blue dark
  static const Color disabledChoiceTextDark = Color(0x4DFFFFFF);        // 30% white
  static const Color disabledChoiceBorderDark = Color(0x336B6FA3);      // 20% brand blue dark

  /// Other Interactive Element Colors - Light Theme  
  static const Color inputAvatarBackgroundLight = lightSecondary;
  static const Color primaryButtonBackgroundLight = Color.fromARGB(255, 223, 218, 57);
  static const Color primaryButtonTextLight = Colors.white;
  static const Color secondaryButtonBackgroundLight = Color.fromARGB(255, 16, 158, 183);
  static const Color secondaryButtonTextLight = lightPrimary;
  
  /// Other Interactive Element Colors - Dark Theme
  static const Color inputAvatarBackgroundDark = darkSecondary;
  static const Color primaryButtonBackgroundDark = darkPrimary;
  static const Color primaryButtonTextDark = Colors.white;
  static const Color secondaryButtonBackgroundDark = Color(0xFF424242);
  static const Color secondaryButtonTextDark = darkPrimary;

  /// Input Background Colors
  static const Color inputBackgroundLight = Color.fromARGB(255, 255, 255, 255);  // #484B85
  static const Color inputBackgroundDark = darkPrimary;    // #6B6FA3

  /// Input Border Colors
  static const Color inputBorderColorLight = lightPrimary;   // Brand blue #484B85
  static const Color inputBorderColorDark = darkPrimary;     // Brand blue dark #6B6FA3

  /// Input Shadow Colors
  static const Color inputShadowColorLight = Color(0x33484B85);  // 20% brand blue
  static const Color inputShadowColorDark = Color(0x33000000);   // 20% black

  /// Legacy Interactive colors
  static const Color hintTextColorLegacy = Color(0xFFB3B3B3);
  static const Color hintTextColor = Colors.white70;
  static const Color disabledColor = Color(0xFF9E9E9E);
  static const Color selectedColor = Color(0xFF6750A4);
  static const Color unselectedColor = Color(0xFFB0B0B0);
  
  /// Selected Choice Shadow Properties (strongest - elevated)
  static const Color selectedChoiceShadowColorLight = Color(0x66484B85); // 40% brand blue
  static const Color selectedChoiceShadowColorDark = Color(0x4D000000);   // 30% black
  
  /// Unselected Choice Shadow Properties (medium - interactive)  
  static const Color unselectedChoiceShadowColorLight = brandBluePurple; 
  static const Color unselectedChoiceShadowColorDark = Color(0x33000000);  // 20% black
  
  /// Disabled Choice Shadow Properties (minimal - flat)
  static const Color disabledChoiceShadowColorLight = Color(0x1A484B85);  // 10% brand blue
  static const Color disabledChoiceShadowColorDark = Color(0x1A000000);   // 10% black

  /// Shadow Offset Properties
  static const Offset selectedChoiceShadowOffset = Offset(0, 0);   // Most pronounced
  static const Offset unselectedChoiceShadowOffset = Offset(0, 3); // Moderate
  static const Offset disabledChoiceShadowOffset = Offset(0, 1);   // Minimal

  /// Shadow Blur Radius Properties
  static const double selectedChoiceShadowBlurRadius = 0.0;   // Most elevated
  static const double unselectedChoiceShadowBlurRadius = 0.0; // Moderate elevation
  static const double disabledChoiceShadowBlurRadius = 1.0;   // Minimal elevation

  /// Input Styling Properties
  static const double inputBorderWidth = 1.0;
  static const Offset inputShadowOffset = Offset(0, 2);
  static const double inputShadowBlurRadius = 4.0;
  
  /// Theme Configuration
  static const bool useMaterial3 = true;

  /// UI Configuration Flags
  static const bool showAvatars = false; // Toggle to hide/show all avatars for testing
  
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
  static const double iconSpacing = spaceS;
  static const double smallSpacing = spaceS;
  static const double mediumSpacing = spaceM;
  static const double standardSpacing = spaceL;
  
  // ==================== SIZING ====================
  
  /// Icon sizes
  static const double iconXS = 16.0;
  static const double iconS = 18.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;
  
  /// Specific icon sizes (from UIConstants)
  static const double sendIconSize = 20.0;
  static const double checkIconSize = 18.0;
  static const double buttonIconSize = 16.0;
  static const double panelIconSize = 20.0;
  static const double sequenceSelectorIconSize = 20.0;
  
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
  
  /// Component-specific animation curves (from UIConstants)
  static const Curve messageSlideAnimationCurve = Curves.easeOutCubic;
  static const Curve scrollAnimationCurve = Curves.easeOut;
  static const Curve panelAnimationCurve = Curves.easeInOut;
  
  /// Component-specific animation durations (from UIConstants)
  static const Duration messageSlideAnimationDuration = Duration(milliseconds: 350);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration panelAnimationDuration = Duration(milliseconds: 300);
  
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
  static const double hintTextOpacity = opacityStrong;
  
  /// Additional UI Constants (from UIConstants)
  static const double messageFontSize = 16.0;
  
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
  
  // ==================== THEME-AWARE GETTERS ====================
  
  /// Theme-aware color getters (from ThemeConstants)
  static Color getSelectedChoiceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? selectedChoiceColorLight 
        : selectedChoiceColorDark;
  }
  
  static Color getUnselectedChoiceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? unselectedChoiceColorLight 
        : unselectedChoiceColorDark;
  }
  
  static Color getSelectedChoiceText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? selectedChoiceTextLight 
        : selectedChoiceTextDark;
  }
  
  static Color getUnselectedChoiceText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? unselectedChoiceTextLight 
        : unselectedChoiceTextDark;
  }
  
  static Color getSelectedChoiceBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? selectedChoiceBorderLight 
        : selectedChoiceBorderDark;
  }
  
  static Color getUnselectedChoiceBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? unselectedChoiceBorderLight 
        : unselectedChoiceBorderDark;
  }

  static Color getDisabledChoiceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? disabledChoiceColorLight 
        : disabledChoiceColorDark;
  }
  
  static Color getDisabledChoiceText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? disabledChoiceTextLight 
        : disabledChoiceTextDark;
  }
  
  static Color getDisabledChoiceBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? disabledChoiceBorderLight 
        : disabledChoiceBorderDark;
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
  
  static Color getSelectedChoiceShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? selectedChoiceShadowColorLight 
        : selectedChoiceShadowColorDark;
  }

  static Color getUnselectedChoiceShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? unselectedChoiceShadowColorLight 
        : unselectedChoiceShadowColorDark;
  }

  static Color getDisabledChoiceShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? disabledChoiceShadowColorLight 
        : disabledChoiceShadowColorDark;
  }

  static Offset getChoiceShadowOffset(ChoiceState state) {
    switch (state) {
      case ChoiceState.selected:
        return selectedChoiceShadowOffset;
      case ChoiceState.unselected:
        return unselectedChoiceShadowOffset;
      case ChoiceState.disabled:
        return disabledChoiceShadowOffset;
    }
  }

  static double getChoiceShadowBlurRadius(ChoiceState state) {
    switch (state) {
      case ChoiceState.selected:
        return selectedChoiceShadowBlurRadius;
      case ChoiceState.unselected:
        return unselectedChoiceShadowBlurRadius;
      case ChoiceState.disabled:
        return disabledChoiceShadowBlurRadius;
    }
  }

  static Color getChoiceShadowColor(BuildContext context, ChoiceState state) {
    switch (state) {
      case ChoiceState.selected:
        return getSelectedChoiceShadowColor(context);
      case ChoiceState.unselected:
        return getUnselectedChoiceShadowColor(context);
      case ChoiceState.disabled:
        return getDisabledChoiceShadowColor(context);
    }
  }

  static Color getInputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? inputBackgroundLight 
        : inputBackgroundDark;
  }

  static Color getInputBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? inputBorderColorLight 
        : inputBorderColorDark;
  }

  static Color getInputShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? inputShadowColorLight 
        : inputShadowColorDark;
  }

  // ==================== MARKDOWN STYLES ====================
  
  /// Creates a MarkdownStyleSheet for regular messages
  static MarkdownStyleSheet getMessageMarkdownStyle(BuildContext context, {required bool isBot}) {
    final textColor = isBot 
        ? botMessageTextColor 
        : userMessageTextColor;
        
    return MarkdownStyleSheet(
      // Base text style
      p: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        height: 1.4,
      ),
      // Bold text
      strong: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      // Italic text
      em: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        fontStyle: FontStyle.italic,
      ),
      // Strikethrough text
      del: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        decoration: TextDecoration.lineThrough,
      ),
      // Disable all other markdown elements
      h1: const TextStyle(fontSize: 0, height: 0),
      h2: const TextStyle(fontSize: 0, height: 0),
      h3: const TextStyle(fontSize: 0, height: 0),
      h4: const TextStyle(fontSize: 0, height: 0),
      h5: const TextStyle(fontSize: 0, height: 0),
      h6: const TextStyle(fontSize: 0, height: 0),
      blockquote: const TextStyle(fontSize: 0, height: 0),
      code: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
      ),
      codeblockDecoration: const BoxDecoration(),
    );
  }
  
  /// Creates a MarkdownStyleSheet for choice buttons
  static MarkdownStyleSheet getChoiceMarkdownStyle(BuildContext context, {required ChoiceState state}) {
    final Color textColor;
    switch (state) {
      case ChoiceState.selected:
        textColor = getSelectedChoiceText(context);
        break;
      case ChoiceState.unselected:
        textColor = getUnselectedChoiceText(context);
        break;
      case ChoiceState.disabled:
        textColor = getDisabledChoiceText(context);
        break;
    }
        
    return MarkdownStyleSheet(
      // Base text style
      p: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        height: 1.4,
      ),
      // Bold text
      strong: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      // Italic text
      em: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        fontStyle: FontStyle.italic,
      ),
      // Strikethrough text
      del: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
        decoration: TextDecoration.lineThrough,
      ),
      // Disable headers and blockquotes
      h1: const TextStyle(fontSize: 0, height: 0),
      h2: const TextStyle(fontSize: 0, height: 0),
      h3: const TextStyle(fontSize: 0, height: 0),
      h4: const TextStyle(fontSize: 0, height: 0),
      h5: const TextStyle(fontSize: 0, height: 0),
      h6: const TextStyle(fontSize: 0, height: 0),
      blockquote: const TextStyle(fontSize: 0, height: 0),
      code: TextStyle(
        fontSize: messageFontSize,
        color: textColor,
      ),
      codeblockDecoration: const BoxDecoration(),
    );
  }
}