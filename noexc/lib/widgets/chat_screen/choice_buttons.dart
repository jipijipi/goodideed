import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/design_tokens.dart';

/// A widget that displays choice buttons for user selection
/// Handles choice selection state and visual feedback
class ChoiceButtons extends StatelessWidget {
  final ChatMessage message;
  final Function(Choice, ChatMessage)? onChoiceSelected;

  const ChoiceButtons({
    super.key,
    required this.message,
    this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = message.selectedChoiceText != null;
    
    return Column(
      children: message.choices!.map((choice) {
        final bool isSelected = message.selectedChoiceText == choice.text;
        final bool isUnselected = hasSelection && !isSelected;
        
        return _buildChoiceButton(
          context,
          choice,
          isSelected: isSelected,
          isUnselected: isUnselected,
          hasSelection: hasSelection,
        );
      }).toList(),
    );
  }

  /// Builds an individual choice button
  Widget _buildChoiceButton(
    BuildContext context,
    Choice choice, {
    required bool isSelected,
    required bool isUnselected,
    required bool hasSelection,
  }) {
    return Padding(
      padding: DesignTokens.choiceButtonMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: hasSelection ? null : () => onChoiceSelected?.call(choice, message),
              child: _buildChoiceContainer(
                context,
                choice,
                isSelected: isSelected,
                isUnselected: isUnselected,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.avatarSpacing),
          _buildUserAvatar(context),
        ],
      ),
    );
  }

  /// Builds the choice button container with styling
  Widget _buildChoiceContainer(
    BuildContext context,
    Choice choice, {
    required bool isSelected,
    required bool isUnselected,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * DesignTokens.messageMaxWidthFactor,
      ),
      padding: DesignTokens.messageBubblePadding,
      decoration: BoxDecoration(
        color: _getChoiceColor(context, isSelected, isUnselected),
        borderRadius: BorderRadius.circular(DesignTokens.messageBubbleRadius),
        border: Border.all(
          color: _getChoiceBorderColor(context, isSelected),
          width: isSelected 
              ? DesignTokens.selectedChoiceBorderWidth 
              : DesignTokens.unselectedChoiceBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.getChoiceButtonShadow(context),
            offset: DesignTokens.choiceButtonShadowOffset,
            blurRadius: DesignTokens.choiceButtonShadowBlurRadius,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              choice.text,
              style: TextStyle(
                fontSize: DesignTokens.messageFontSize,
                color: _getChoiceTextColor(context, isUnselected),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: DesignTokens.iconSpacing),
            const Icon(
              Icons.check_circle,
              color: DesignTokens.userMessageTextColor,
              size: DesignTokens.checkIconSize,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the user avatar for choice buttons
  Widget _buildUserAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: DesignTokens.getInputAvatarBackground(context),
      child: const Icon(Icons.person, color: DesignTokens.avatarIconColor),
    );
  }

  /// Gets the appropriate color for choice button background
  Color _getChoiceColor(BuildContext context, bool isSelected, bool isUnselected) {
    final baseColor = DesignTokens.getChoiceButtonColor(context);
    if (isSelected) {
      return baseColor;
    } else if (isUnselected) {
      return baseColor.withValues(alpha: DesignTokens.unselectedChoiceOpacity);
    } else {
      return baseColor.withValues(alpha: DesignTokens.selectedChoiceOpacity);
    }
  }

  /// Gets the appropriate border color for choice buttons
  Color _getChoiceBorderColor(BuildContext context, bool isSelected) {
    final borderColor = DesignTokens.getChoiceButtonBorder(context);
    return isSelected
        ? borderColor
        : borderColor.withValues(alpha: DesignTokens.choiceBorderOpacity);
  }

  /// Gets the appropriate text color for choice buttons
  Color _getChoiceTextColor(BuildContext context, bool isUnselected) {
    final textColor = DesignTokens.getChoiceButtonText(context);
    return isUnselected 
        ? textColor.withValues(alpha: DesignTokens.unselectedTextOpacity)
        : textColor;
  }
}