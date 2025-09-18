import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../constants/design_tokens.dart';

/// Enum representing the three states of a choice button
enum ChoiceState { unselected, selected, disabled }

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
      children:
          message.choices!.map((choice) {
            final ChoiceState state = _getChoiceState(
              hasSelection,
              message.selectedChoiceText == choice.text,
            );

            return _buildChoiceButton(
              context,
              choice,
              state: state,
              hasSelection: hasSelection,
            );
          }).toList(),
    );
  }

  /// Determines the state of a choice button
  ChoiceState _getChoiceState(bool hasSelection, bool isSelected) {
    if (!hasSelection) return ChoiceState.unselected;
    if (isSelected) return ChoiceState.selected;
    return ChoiceState.disabled;
  }

  /// Builds an individual choice button
  Widget _buildChoiceButton(
    BuildContext context,
    Choice choice, {
    required ChoiceState state,
    required bool hasSelection,
  }) {
    return Padding(
      padding: DesignTokens.choiceButtonMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onTap:
                  hasSelection
                      ? null
                      : () => onChoiceSelected?.call(choice, message),
              child: _buildChoiceContainer(context, choice, state: state),
            ),
          ),
          if (DesignTokens.showAvatars) ...[
            const SizedBox(width: DesignTokens.avatarSpacing),
            _buildUserAvatar(context),
          ],
        ],
      ),
    );
  }

  /// Builds the choice button container with styling
  Widget _buildChoiceContainer(
    BuildContext context,
    Choice choice, {
    required ChoiceState state,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth:
            MediaQuery.of(context).size.width *
            DesignTokens.messageMaxWidthFactor,
      ),
      padding: DesignTokens.messageBubblePadding,
      decoration: BoxDecoration(
        color: _getChoiceColor(context, state),
        borderRadius: BorderRadius.circular(DesignTokens.messageBubbleRadius),
        border: Border.all(
          color: _getChoiceBorderColor(context, state),
          width:
              state == ChoiceState.selected
                  ? DesignTokens.selectedChoiceBorderWidth
                  : DesignTokens.unselectedChoiceBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.getChoiceShadowColor(context, state),
            offset: DesignTokens.getChoiceShadowOffset(state),
            blurRadius: DesignTokens.getChoiceShadowBlurRadius(state),
          ),
        ],
      ),
      child: MarkdownBody(
        data: choice.text,
        styleSheet: DesignTokens.getChoiceMarkdownStyle(
          context,
          state: state,
        ),
        shrinkWrap: true,
        selectable: false,
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
  Color _getChoiceColor(BuildContext context, ChoiceState state) {
    switch (state) {
      case ChoiceState.selected:
        return DesignTokens.getSelectedChoiceColor(context);
      case ChoiceState.unselected:
        return DesignTokens.getUnselectedChoiceColor(context);
      case ChoiceState.disabled:
        return DesignTokens.getDisabledChoiceColor(context);
    }
  }

  /// Gets the appropriate border color for choice buttons
  Color _getChoiceBorderColor(BuildContext context, ChoiceState state) {
    switch (state) {
      case ChoiceState.selected:
        return DesignTokens.getSelectedChoiceBorder(context);
      case ChoiceState.unselected:
        return DesignTokens.getUnselectedChoiceBorder(context);
      case ChoiceState.disabled:
        return DesignTokens.getDisabledChoiceBorder(context);
    }
  }
}
