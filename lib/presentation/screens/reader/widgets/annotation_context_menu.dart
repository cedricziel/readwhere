import 'package:flutter/material.dart';

import '../../../../domain/entities/annotation.dart';
import '../../../themes/colors.dart';

/// A context menu that appears when text is selected in the reader.
///
/// Displays a row of color swatches for quick highlighting and
/// an "Add Note" button for creating annotations with notes.
class AnnotationContextMenu extends StatelessWidget {
  /// Callback when a color is selected for highlighting.
  final void Function(AnnotationColor color) onHighlight;

  /// Callback when "Add Note" is tapped.
  final VoidCallback onAddNote;

  /// Callback when "Copy" is tapped.
  final VoidCallback? onCopy;

  /// Currently selected text (for display).
  final String? selectedText;

  const AnnotationContextMenu({
    super.key,
    required this.onHighlight,
    required this.onAddNote,
    this.onCopy,
    this.selectedText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color swatches
            ...AnnotationColor.values.map(
              (color) => _ColorSwatch(
                color: _getColorValue(color),
                onTap: () => onHighlight(color),
                tooltip: _getColorName(color),
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            // Add Note button
            _ActionButton(
              icon: Icons.note_add_outlined,
              label: 'Note',
              onTap: onAddNote,
            ),
            // Copy button (if provided)
            if (onCopy != null) ...[
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.copy_outlined,
                label: 'Copy',
                onTap: onCopy!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorValue(AnnotationColor color) {
    switch (color) {
      case AnnotationColor.yellow:
        return AppColors.highlightYellow;
      case AnnotationColor.green:
        return AppColors.highlightGreen;
      case AnnotationColor.blue:
        return AppColors.highlightBlue;
      case AnnotationColor.pink:
        return AppColors.highlightPink;
      case AnnotationColor.purple:
        return AppColors.primary;
      case AnnotationColor.orange:
        return AppColors.highlightOrange;
    }
  }

  String _getColorName(AnnotationColor color) {
    switch (color) {
      case AnnotationColor.yellow:
        return 'Yellow';
      case AnnotationColor.green:
        return 'Green';
      case AnnotationColor.blue:
        return 'Blue';
      case AnnotationColor.pink:
        return 'Pink';
      case AnnotationColor.purple:
        return 'Purple';
      case AnnotationColor.orange:
        return 'Orange';
    }
  }
}

/// A circular color swatch for selecting highlight colors.
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ColorSwatch({
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An action button with icon and label.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to get color information for annotations.
class AnnotationColorHelper {
  AnnotationColorHelper._();

  /// Returns the Flutter Color for an AnnotationColor.
  static Color getColor(AnnotationColor color) {
    switch (color) {
      case AnnotationColor.yellow:
        return AppColors.highlightYellow;
      case AnnotationColor.green:
        return AppColors.highlightGreen;
      case AnnotationColor.blue:
        return AppColors.highlightBlue;
      case AnnotationColor.pink:
        return AppColors.highlightPink;
      case AnnotationColor.purple:
        return AppColors.primary;
      case AnnotationColor.orange:
        return AppColors.highlightOrange;
    }
  }

  /// Returns a semi-transparent version of the color for highlights.
  static Color getHighlightColor(AnnotationColor color) {
    return getColor(color).withValues(alpha: 0.4);
  }

  /// Returns the display name for an AnnotationColor.
  static String getName(AnnotationColor color) {
    switch (color) {
      case AnnotationColor.yellow:
        return 'Yellow';
      case AnnotationColor.green:
        return 'Green';
      case AnnotationColor.blue:
        return 'Blue';
      case AnnotationColor.pink:
        return 'Pink';
      case AnnotationColor.purple:
        return 'Purple';
      case AnnotationColor.orange:
        return 'Orange';
    }
  }
}
