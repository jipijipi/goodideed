import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';

/// Standard app card component with consistent styling
/// Provides common card variants to minimize UI duplication
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  final bool hasBorder;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.onTap,
    this.hasBorder = false,
    this.borderRadius,
  });

  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.hasBorder = false,
    this.borderRadius,
  }) : elevation = DesignTokens.elevationM;

  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  }) : elevation = DesignTokens.elevationNone,
       hasBorder = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardRadius = borderRadius ?? DesignTokens.cardRadius;

    Widget cardChild = Container(
      padding: padding ?? DesignTokens.paddingL,
      child: child,
    );

    if (onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: cardChild,
      );
    }

    return Card(
      elevation: elevation ?? DesignTokens.elevationS,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side:
            hasBorder
                ? BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: DesignTokens.borderThin,
                )
                : BorderSide.none,
      ),
      child: cardChild,
    );
  }
}

/// A specialized card for displaying content sections
class ContentCard extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;

  const ContentCard({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: DesignTokens.paddingL,
              child: Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ],
          Padding(
            padding: contentPadding ?? DesignTokens.paddingL,
            child: content,
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: DesignTokens.paddingL,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:
                    actions!
                        .expand(
                          (action) => [
                            action,
                            const SizedBox(width: DesignTokens.spaceS),
                          ],
                        )
                        .take(actions!.length * 2 - 1)
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
