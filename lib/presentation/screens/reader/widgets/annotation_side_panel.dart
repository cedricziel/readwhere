import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/annotation.dart';
import '../../../providers/annotation_provider.dart';
import 'annotation_list_item.dart';

/// A slide-in panel from the right that displays all annotations for the current book.
///
/// Annotations are grouped by chapter and can be tapped to navigate to their location.
class AnnotationSidePanel extends StatelessWidget {
  /// Whether the panel is visible.
  final bool visible;

  /// Callback when an annotation is tapped (for navigation).
  final void Function(Annotation annotation)? onAnnotationTap;

  /// Callback when the close button is tapped.
  final VoidCallback? onClose;

  /// Map of chapter IDs to chapter titles for display.
  final Map<String, String> chapterTitles;

  /// Width of the panel.
  final double width;

  const AnnotationSidePanel({
    super.key,
    required this.visible,
    this.onAnnotationTap,
    this.onClose,
    this.chapterTitles = const {},
    this.width = 320,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 400 ? screenWidth * 0.85 : width;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: visible ? 0 : -panelWidth,
      top: 0,
      bottom: 0,
      width: panelWidth,
      child: Material(
        elevation: 16,
        child: Container(
          color: theme.colorScheme.surface,
          child: SafeArea(
            left: false,
            child: Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: Consumer<AnnotationProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }

                      if (provider.annotations.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      return _buildAnnotationList(context, provider);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.highlight_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Consumer<AnnotationProvider>(
              builder: (context, provider, _) {
                final count = provider.annotationCount;
                return Text(
                  'Annotations ($count)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.highlight_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No annotations yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select text to create highlights and notes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationList(
    BuildContext context,
    AnnotationProvider provider,
  ) {
    final annotationsByChapter = provider.annotationsByChapter;
    final chapters = annotationsByChapter.keys.toList();

    // If there's only one chapter or no grouping, show flat list
    if (chapters.length <= 1) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.annotations.length,
        itemBuilder: (context, index) {
          final annotation = provider.annotations[index];
          return _buildAnnotationItem(context, provider, annotation);
        },
      );
    }

    // Grouped by chapter
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chapters.length,
      itemBuilder: (context, chapterIndex) {
        final chapterId = chapters[chapterIndex];
        final annotations = annotationsByChapter[chapterId]!;
        final chapterTitle = chapterTitles[chapterId] ?? chapterId ?? 'Unknown';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                chapterTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // Annotations in this chapter
            ...annotations.map(
              (annotation) =>
                  _buildAnnotationItem(context, provider, annotation),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnotationItem(
    BuildContext context,
    AnnotationProvider provider,
    Annotation annotation,
  ) {
    return AnnotationListItem(
      annotation: annotation,
      chapterTitle: chapterTitles[annotation.chapterId],
      onTap: onAnnotationTap != null
          ? () => onAnnotationTap!(annotation)
          : null,
      onEditNote: (newNote) async {
        await provider.updateNote(annotation.id, newNote);
      },
      onChangeColor: (newColor) async {
        await provider.updateColor(annotation.id, newColor);
      },
      onDelete: () async {
        await provider.deleteAnnotation(annotation.id);
      },
    );
  }
}

/// A toggle button for showing/hiding the annotation side panel.
///
/// Shows a badge with the annotation count when there are annotations.
class AnnotationPanelToggle extends StatelessWidget {
  /// Callback when the button is tapped.
  final VoidCallback onTap;

  /// Whether the panel is currently visible.
  final bool panelVisible;

  const AnnotationPanelToggle({
    super.key,
    required this.onTap,
    this.panelVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnotationProvider>(
      builder: (context, provider, _) {
        final count = provider.annotationCount;

        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : count.toString()),
            child: Icon(
              panelVisible ? Icons.highlight : Icons.highlight_outlined,
            ),
          ),
          onPressed: onTap,
          tooltip: panelVisible ? 'Hide annotations' : 'Show annotations',
        );
      },
    );
  }
}
