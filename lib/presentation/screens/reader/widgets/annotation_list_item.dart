import 'package:flutter/material.dart';

import '../../../../domain/entities/annotation.dart';
import '../../../widgets/adaptive/adaptive_action_sheet.dart';
import 'annotation_context_menu.dart';
import 'note_editor_dialog.dart';

/// A list item card for displaying an annotation.
///
/// Shows the highlighted text, optional note, and provides
/// actions for editing, navigating to, and deleting the annotation.
class AnnotationListItem extends StatelessWidget {
  /// The annotation to display.
  final Annotation annotation;

  /// Callback when the item is tapped (navigate to annotation location).
  final VoidCallback? onTap;

  /// Callback to edit the annotation's note.
  final void Function(String? newNote)? onEditNote;

  /// Callback to change the annotation's color.
  final void Function(AnnotationColor newColor)? onChangeColor;

  /// Callback to delete the annotation.
  final VoidCallback? onDelete;

  /// Optional chapter title for display.
  final String? chapterTitle;

  const AnnotationListItem({
    super.key,
    required this.annotation,
    this.onTap,
    this.onEditNote,
    this.onChangeColor,
    this.onDelete,
    this.chapterTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = AnnotationColorHelper.getColor(annotation.color);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with color indicator and timestamp
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: highlightColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chapter title (if provided)
                  if (chapterTitle != null) ...[
                    Expanded(
                      child: Text(
                        chapterTitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  // Timestamp
                  Text(
                    _formatTimestamp(annotation.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Highlighted text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: highlightColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  annotation.text,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Note (if present)
              if (annotation.note != null && annotation.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        annotation.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    AdaptiveActionSheet.show(
      context: context,
      title: 'Annotation Options',
      actions: [
        if (onEditNote != null)
          AdaptiveActionSheetAction(
            label: 'Edit Note',
            icon: Icons.edit_outlined,
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await NoteEditorDialog.show(
                context: context,
                selectedText: annotation.text,
                initialNote: annotation.note,
                initialColor: annotation.color,
                isEditing: true,
              );
              if (result != null) {
                onEditNote!(result.note.isEmpty ? null : result.note);
                if (result.color != annotation.color) {
                  onChangeColor?.call(result.color);
                }
              }
            },
          ),
        if (onChangeColor != null)
          AdaptiveActionSheetAction(
            label: 'Change Color',
            icon: Icons.palette_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              _showColorPicker(context);
            },
          ),
        if (onTap != null)
          AdaptiveActionSheetAction(
            label: 'Go to Location',
            icon: Icons.my_location_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onTap!();
            },
          ),
        if (onDelete != null)
          AdaptiveActionSheetAction(
            label: 'Delete',
            icon: Icons.delete_outline,
            isDestructive: true,
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context);
            },
          ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Color'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnnotationColor.values.map((color) {
            final isSelected = color == annotation.color;
            final colorValue = AnnotationColorHelper.getColor(color);

            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onChangeColor?.call(color);
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colorValue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black54 : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 20, color: Colors.black54)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation?'),
        content: const Text(
          'This will permanently delete this highlight and any associated note.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes min ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hr ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
