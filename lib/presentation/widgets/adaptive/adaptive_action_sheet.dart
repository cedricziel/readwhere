import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An action that can be displayed in an [AdaptiveActionSheet].
///
/// Each action has a label, optional icon, and callback. Actions can be
/// marked as destructive to display them in a warning style.
class AdaptiveActionSheetAction {
  /// The text label displayed for this action.
  final String label;

  /// Optional icon displayed before the label (Material only).
  final IconData? icon;

  /// Callback invoked when this action is tapped.
  final VoidCallback onPressed;

  /// Whether this action is destructive (e.g., delete, remove).
  ///
  /// Destructive actions are displayed in red/error color.
  final bool isDestructive;

  /// Whether this action is the default/primary action.
  ///
  /// On iOS, the default action has bold text.
  final bool isDefault;

  const AdaptiveActionSheetAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// An adaptive action sheet that displays as a bottom sheet on Material
/// platforms and as a Cupertino action sheet on Apple platforms.
///
/// Use this for presenting a list of actions to the user, such as
/// context menus, share options, or confirmation actions.
///
/// Example:
/// ```dart
/// AdaptiveActionSheet.show(
///   context: context,
///   title: 'Book Options',
///   actions: [
///     AdaptiveActionSheetAction(
///       label: 'Share',
///       icon: Icons.share,
///       onPressed: () => shareBook(),
///     ),
///     AdaptiveActionSheetAction(
///       label: 'Delete',
///       icon: Icons.delete,
///       onPressed: () => deleteBook(),
///       isDestructive: true,
///     ),
///   ],
/// );
/// ```
class AdaptiveActionSheet {
  AdaptiveActionSheet._();

  /// Shows an adaptive action sheet.
  ///
  /// On Apple platforms (iOS/macOS), shows a [CupertinoActionSheet].
  /// On other platforms, shows a Material bottom sheet.
  ///
  /// Returns a [Future] that completes when the sheet is dismissed.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveActionSheetAction> actions,
    AdaptiveActionSheetAction? cancelAction,
  }) {
    if (context.useCupertino) {
      return _showCupertinoActionSheet<T>(
        context: context,
        title: title,
        message: message,
        actions: actions,
        cancelAction: cancelAction,
      );
    }

    return _showMaterialBottomSheet<T>(
      context: context,
      title: title,
      message: message,
      actions: actions,
      cancelAction: cancelAction,
    );
  }

  /// Shows a Cupertino-style action sheet.
  static Future<T?> _showCupertinoActionSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveActionSheetAction> actions,
    AdaptiveActionSheetAction? cancelAction,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        message: message != null ? Text(message) : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            isDefaultAction: action.isDefault,
            onPressed: () {
              Navigator.pop(context);
              action.onPressed();
            },
            child: Text(action.label),
          );
        }).toList(),
        cancelButton: cancelAction != null
            ? CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  cancelAction.onPressed();
                },
                child: Text(cancelAction.label),
              )
            : CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
      ),
    );
  }

  /// Shows a Material-style bottom sheet.
  static Future<T?> _showMaterialBottomSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveActionSheetAction> actions,
    AdaptiveActionSheetAction? cancelAction,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title and message
            if (title != null || message != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (message != null) ...[
                      if (title != null) const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Actions (scrollable to handle many items or small screens)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions.map((action) {
                    final color = action.isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface;

                    return ListTile(
                      leading: action.icon != null
                          ? Icon(action.icon, color: color)
                          : null,
                      title: Text(
                        action.label,
                        style: TextStyle(
                          color: color,
                          fontWeight: action.isDefault ? FontWeight.w600 : null,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        action.onPressed();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // Cancel action (if provided, show as a separate button)
            if (cancelAction != null) ...[
              const Divider(height: 1),
              ListTile(
                title: Text(
                  cancelAction.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  cancelAction.onPressed();
                },
              ),
            ],

            // Bottom padding
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
