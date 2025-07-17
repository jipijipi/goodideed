import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/ui_constants.dart';
import '../../constants/theme_constants.dart';

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
      padding: UIConstants.choiceButtonMargin,
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
          const SizedBox(width: UIConstants.avatarSpacing),
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
        maxWidth: MediaQuery.of(context).size.width * UIConstants.messageMaxWidthFactor,
      ),
      padding: UIConstants.messageBubblePadding,
      decoration: BoxDecoration(
        color: _getChoiceColor(context, isSelected, isUnselected),
        borderRadius: BorderRadius.circular(UIConstants.messageBubbleRadius),
        border: Border.all(
          color: _getChoiceBorderColor(context, isSelected),
          width: isSelected 
              ? UIConstants.selectedChoiceBorderWidth 
              : UIConstants.unselectedChoiceBorderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              choice.text,
              style: TextStyle(
                fontSize: UIConstants.messageFontSize,
                color: _getChoiceTextColor(isUnselected),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: UIConstants.iconSpacing),
            const Icon(
              Icons.check_circle,
              color: ThemeConstants.userMessageTextColor,
              size: UIConstants.checkIconSize,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the user avatar for choice buttons
  Widget _buildUserAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: const Icon(Icons.person, color: ThemeConstants.avatarIconColor),
    );
  }

  /// Gets the appropriate color for choice button background
  Color _getChoiceColor(BuildContext context, bool isSelected, bool isUnselected) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    } else if (isUnselected) {
      return Theme.of(context).colorScheme.primary.withOpacity(UIConstants.unselectedChoiceOpacity);
    } else {
      return Theme.of(context).colorScheme.primary.withOpacity(UIConstants.selectedChoiceOpacity);
    }
  }

  /// Gets the appropriate border color for choice buttons
  Color _getChoiceBorderColor(BuildContext context, bool isSelected) {
    return isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary.withOpacity(UIConstants.choiceBorderOpacity);
  }

  /// Gets the appropriate text color for choice buttons
  Color _getChoiceTextColor(bool isUnselected) {
    return isUnselected 
        ? ThemeConstants.userMessageTextColor.withOpacity(UIConstants.unselectedTextOpacity)
        : ThemeConstants.userMessageTextColor;
  }
}