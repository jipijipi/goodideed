import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// Standard app text field component with consistent styling
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputAction? textInputAction;
  final EdgeInsets? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.textInputAction,
    this.contentPadding,
  });

  const AppTextField.search({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  }) : label = null,
       helperText = null,
       errorText = null,
       onTap = null,
       keyboardType = TextInputType.text,
       obscureText = false,
       readOnly = false,
       maxLines = 1,
       maxLength = null,
       prefix = null,
       suffix = null,
       prefixIcon = Icons.search,
       suffixIcon = null,
       onSuffixIconPressed = null,
       textInputAction = TextInputAction.search,
       contentPadding = null;

  const AppTextField.multiline({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 5,
    this.maxLength,
    this.contentPadding,
  }) : keyboardType = TextInputType.multiline,
       obscureText = false,
       prefix = null,
       suffix = null,
       prefixIcon = null,
       suffixIcon = null,
       onSuffixIconPressed = null,
       textInputAction = TextInputAction.newline,
       onSubmitted = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceS),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: DesignTokens.fontSizeM,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : prefix,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceL,
              vertical: DesignTokens.spaceM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (suffixIcon != null) {
      return IconButton(
        icon: Icon(suffixIcon),
        onPressed: onSuffixIconPressed,
      );
    }
    if (suffix != null) {
      return suffix;
    }
    return null;
  }
}