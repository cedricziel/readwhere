import 'package:flutter/material.dart';

/// A reusable loading indicator widget displayed during async operations.
///
/// This widget provides a consistent loading state design across the application
/// with a circular progress indicator and optional message.
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;

  /// Optional size of the progress indicator (defaults to null for default size)
  final double? size;

  /// Optional color for the progress indicator
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size != null ? size! / 8 : 4.0,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );

    if (message == null) {
      return Center(child: indicator);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.60),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A compact loading indicator for use in smaller spaces like buttons.
///
/// This widget provides a smaller, inline loading indicator that can be
/// used within buttons, list tiles, or other compact UI elements.
class CompactLoadingIndicator extends StatelessWidget {
  /// Optional size of the progress indicator (defaults to 16)
  final double? size;

  /// Optional color for the progress indicator
  final Color? color;

  const CompactLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorSize = size ?? 16.0;

    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: indicatorSize / 8,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
}
