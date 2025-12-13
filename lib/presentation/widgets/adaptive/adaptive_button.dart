import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive filled/primary button.
///
/// Displays as a [FilledButton] on Material platforms and a
/// [CupertinoButton.filled] on Apple platforms.
///
/// Example:
/// ```dart
/// AdaptiveFilledButton(
///   onPressed: () => saveChanges(),
///   child: Text('Save'),
/// )
/// ```
class AdaptiveFilledButton extends StatelessWidget {
  /// The button's child widget (typically a [Text]).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Minimum size of the button.
  final Size? minimumSize;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  const AdaptiveFilledButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.minimumSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.useCupertino
                    ? CupertinoColors.white
                    : Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
        : child;

    if (context.useCupertino) {
      return CupertinoButton.filled(
        onPressed: isLoading ? null : onPressed,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: minimumSize ?? const Size(0, 44),
        child: effectiveChild,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: minimumSize, padding: padding),
      child: effectiveChild,
    );
  }
}

/// An adaptive text/secondary button.
///
/// Displays as a [TextButton] on Material platforms and a
/// [CupertinoButton] on Apple platforms.
///
/// Example:
/// ```dart
/// AdaptiveTextButton(
///   onPressed: () => cancel(),
///   child: Text('Cancel'),
/// )
/// ```
class AdaptiveTextButton extends StatelessWidget {
  /// The button's child widget (typically a [Text]).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  const AdaptiveTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDestructive = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: DefaultTextStyle(
          style: TextStyle(
            color: isDestructive
                ? CupertinoColors.destructiveRed
                : CupertinoTheme.of(context).primaryColor,
          ),
          child: child,
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDestructive
            ? Theme.of(context).colorScheme.error
            : null,
        padding: padding,
      ),
      child: child,
    );
  }
}

/// An adaptive outlined button.
///
/// Displays as an [OutlinedButton] on Material platforms and a
/// [CupertinoButton] with a border on Apple platforms.
///
/// Example:
/// ```dart
/// AdaptiveOutlinedButton(
///   onPressed: () => showMore(),
///   child: Text('Show More'),
/// )
/// ```
class AdaptiveOutlinedButton extends StatelessWidget {
  /// The button's child widget (typically a [Text]).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  const AdaptiveOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      final primaryColor = CupertinoTheme.of(context).primaryColor;

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          onPressed: onPressed,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle(
            style: TextStyle(color: primaryColor),
            child: child,
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(padding: padding),
      child: child,
    );
  }
}

/// An adaptive icon button.
///
/// Displays as an [IconButton] on Material platforms and a
/// [CupertinoButton] on Apple platforms.
///
/// Example:
/// ```dart
/// AdaptiveIconButton(
///   icon: Icons.close,
///   onPressed: () => closeDialog(),
/// )
/// ```
class AdaptiveIconButton extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Size of the icon.
  final double? iconSize;

  /// Color of the icon.
  final Color? color;

  /// Tooltip text.
  final String? tooltip;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      final button = CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: Size.square(iconSize ?? 44),
        child: Icon(
          icon,
          size: iconSize ?? 24,
          color: color ?? CupertinoTheme.of(context).primaryColor,
        ),
      );

      if (tooltip != null) {
        return Tooltip(message: tooltip!, child: button);
      }
      return button;
    }

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
    );
  }
}
