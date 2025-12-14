import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/entities/annotation.dart';
import 'annotation_context_menu.dart';

/// Dialog result for the note editor.
class NoteEditorResult {
  /// The note text (can be empty).
  final String note;

  /// The selected annotation color.
  final AnnotationColor color;

  const NoteEditorResult({required this.note, required this.color});
}

/// A dialog for creating or editing annotation notes.
///
/// Shows the selected text preview, a multi-line text field for notes,
/// and a color picker for the highlight color.
class NoteEditorDialog extends StatefulWidget {
  /// The text that was selected (for preview).
  final String selectedText;

  /// Initial note text (for editing existing annotations).
  final String? initialNote;

  /// Initial color (for editing existing annotations).
  final AnnotationColor initialColor;

  /// Whether this is editing an existing annotation.
  final bool isEditing;

  const NoteEditorDialog({
    super.key,
    required this.selectedText,
    this.initialNote,
    this.initialColor = AnnotationColor.yellow,
    this.isEditing = false,
  });

  /// Shows the note editor dialog and returns the result.
  ///
  /// Returns null if the dialog was cancelled.
  static Future<NoteEditorResult?> show({
    required BuildContext context,
    required String selectedText,
    String? initialNote,
    AnnotationColor initialColor = AnnotationColor.yellow,
    bool isEditing = false,
  }) {
    if (context.useCupertino) {
      return showCupertinoDialog<NoteEditorResult>(
        context: context,
        builder: (context) => NoteEditorDialog(
          selectedText: selectedText,
          initialNote: initialNote,
          initialColor: initialColor,
          isEditing: isEditing,
        ),
      );
    }

    return showDialog<NoteEditorResult>(
      context: context,
      builder: (context) => NoteEditorDialog(
        selectedText: selectedText,
        initialNote: initialNote,
        initialColor: initialColor,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _noteController;
  late AnnotationColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      NoteEditorResult(
        note: _noteController.text.trim(),
        color: _selectedColor,
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoDialog(context);
    }
    return _buildMaterialDialog(context);
  }

  Widget _buildMaterialDialog(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Note' : 'Add Note'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AnnotationColorHelper.getHighlightColor(_selectedColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _truncateText(widget.selectedText, 100),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Highlight Color', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 16),
            // Note text field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add your thoughts...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: _save,
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildCupertinoDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.isEditing ? 'Edit Note' : 'Add Note'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AnnotationColorHelper.getHighlightColor(_selectedColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _truncateText(widget.selectedText, 100),
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Color picker
            _buildColorPicker(),
            const SizedBox(height: 16),
            // Note text field
            CupertinoTextField(
              controller: _noteController,
              placeholder: 'Add your thoughts...',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _cancel,
          isDefaultAction: false,
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: _save,
          isDefaultAction: true,
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AnnotationColor.values.map((color) {
        final isSelected = color == _selectedColor;
        final colorValue = AnnotationColorHelper.getColor(color);

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorValue,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black54 : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorValue.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.black54)
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
