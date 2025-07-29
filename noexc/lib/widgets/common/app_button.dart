import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// Standard app button component with consistent styling
/// Provides common button variants to minimize UI duplication
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : variant = ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : variant = ButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  }) : variant = ButtonVariant.outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context, colorScheme),
    );
  }

  Widget _buildButton(BuildContext context, ColorScheme colorScheme) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: _getElevatedButtonStyle(context, colorScheme),
          child: _buildContent(),
        );
      case ButtonVariant.secondary:
        return FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: _getFilledButtonStyle(context, colorScheme),
          child: _buildContent(),
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: _getOutlinedButtonStyle(colorScheme),
          child: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary ? DesignTokens.avatarIconColor : DesignTokens.brandPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: DesignTokens.spaceS),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getElevatedButtonStyle(BuildContext context, ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: DesignTokens.getPrimaryButtonBackground(context),
      foregroundColor: DesignTokens.getPrimaryButtonText(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(),
    );
  }

  ButtonStyle _getFilledButtonStyle(BuildContext context, ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: DesignTokens.getSecondaryButtonBackground(context),
      foregroundColor: DesignTokens.getSecondaryButtonText(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(),
    );
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.buttonHeightS;
      case ButtonSize.medium:
        return DesignTokens.buttonHeightM;
      case ButtonSize.large:
        return DesignTokens.buttonHeightL;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.iconXS;
      case ButtonSize.medium:
        return DesignTokens.iconS;
      case ButtonSize.large:
        return DesignTokens.iconM;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceM,
          vertical: DesignTokens.spaceS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXL,
          vertical: DesignTokens.spaceL,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return const TextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
        );
      case ButtonSize.medium:
        return const TextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
        );
      case ButtonSize.large:
        return const TextStyle(
          fontSize: DesignTokens.fontSizeL,
          fontWeight: DesignTokens.fontWeightMedium,
        );
    }
  }
}

enum ButtonVariant {
  primary,
  secondary,
  outline,
}

enum ButtonSize {
  small,
  medium,
  large,
}