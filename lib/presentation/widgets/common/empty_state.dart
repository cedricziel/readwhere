import 'package:flutter/material.dart';

/// A reusable empty state widget displayed when there is no content to show.
///
/// This widget provides a consistent empty state design across the application
/// with an icon, title, optional subtitle, and optional action button.
class EmptyState extends StatelessWidget {
  /// The icon to display in the empty state
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional subtitle text providing additional context
  final String? subtitle;

  /// Optional action button text
  final String? actionLabel;

  /// Callback when the action button is pressed
  final VoidCallback? onAction;

  /// Optional icon color (defaults to theme's disabled color)
  final Color? iconColor;

  /// Optional icon size (defaults to 64)
  final double? iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize,
  }) : assert(
         (actionLabel == null && onAction == null) ||
             (actionLabel != null && onAction != null),
         'If actionLabel is provided, onAction must also be provided, and vice versa',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize ?? 64,
              color: iconColor ?? colorScheme.onSurface.withOpacity(0.38),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.87),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.60),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
