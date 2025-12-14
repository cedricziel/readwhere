import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/entities/annotation.dart';
import '../../../providers/annotation_provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/reader_provider.dart';
import '../../../themes/reading_themes.dart';
import 'annotation_context_menu.dart';
import 'note_editor_dialog.dart';

/// Widget for displaying book content with HTML rendering
///
/// This widget displays the current chapter's HTML content using
/// flutter_html package with customizable reading theme settings.
class ReaderContentWidget extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onToggleControls;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;

  /// Whether annotation features are enabled (EPUB only).
  final bool annotationsEnabled;

  const ReaderContentWidget({
    super.key,
    required this.scrollController,
    this.onToggleControls,
    this.onNextChapter,
    this.onPreviousChapter,
    this.annotationsEnabled = true,
  });

  @override
  State<ReaderContentWidget> createState() => _ReaderContentWidgetState();
}

class _ReaderContentWidgetState extends State<ReaderContentWidget> {
  // Track pointer state for tap detection
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;

  // Track chapter index to detect changes and force SelectionArea rebuild
  int? _lastChapterIndex;
  Key _selectionAreaKey = UniqueKey();

  // Track current text selection for annotation
  String? _currentSelection;
  int? _selectionChapterIndex;

  void _clearSelection() {
    _currentSelection = null;
    _selectionChapterIndex = null;
  }

  // Threshold for tap detection
  static const double _tapMaxDistance = 20.0; // Max movement in pixels
  static const Duration _tapMaxDuration = Duration(
    milliseconds: 300,
  ); // Max tap duration

  @override
  void didUpdateWidget(covariant ReaderContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pointer tracking state when widget updates to prevent stale state
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  /// Updates the SelectionArea key when chapter changes to prevent
  /// Flutter framework bug with stale selection indices.
  void _updateSelectionAreaKeyIfNeeded(int currentChapterIndex) {
    if (_lastChapterIndex != currentChapterIndex) {
      _lastChapterIndex = currentChapterIndex;
      // Use UniqueKey to force complete rebuild of SelectionArea
      // This prevents the assertion failure when selection indices
      // reference selectables from the previous chapter
      _selectionAreaKey = UniqueKey();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _pointerDownTime = DateTime.now();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pointerDownPosition == null || _pointerDownTime == null) {
      return;
    }

    final distance = (event.position - _pointerDownPosition!).distance;
    final duration = DateTime.now().difference(_pointerDownTime!);

    // Check if this was a tap (short duration, minimal movement)
    if (distance <= _tapMaxDistance && duration <= _tapMaxDuration) {
      _handleTap(event.position);
    }

    // Reset state
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Reset state when pointer events are cancelled (e.g., gesture arena conflict)
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  void _handleTap(Offset position) {
    // If there's an active selection, show annotation menu instead of normal tap behavior
    if (_currentSelection != null &&
        _currentSelection!.trim().isNotEmpty &&
        _selectionChapterIndex != null) {
      // Show annotation menu (don't clear selection yet - clear after action)
      _showAnnotationMenu(context, _currentSelection!, _selectionChapterIndex!);
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = position.dx;

    if (tapX < screenWidth / 3) {
      // Left third - previous chapter
      widget.onPreviousChapter?.call();
    } else if (tapX > screenWidth * 2 / 3) {
      // Right third - next chapter
      widget.onNextChapter?.call();
    } else {
      // Center third - toggle controls
      widget.onToggleControls?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingTheme = context.readingTheme;

    return Consumer3<ReaderProvider, AudioProvider, AnnotationProvider>(
      builder: (context, readerProvider, audioProvider, annotationProvider, child) {
        // Placeholder content when no book is open or loading
        if (!readerProvider.hasOpenBook || readerProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: readingTheme.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No content available',
                  style: TextStyle(
                    color: readingTheme.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        // Get the current highlighted element ID from audio playback
        final highlightedElementId = audioProvider.highlightedElementId;

        // Get the actual chapter HTML content from the provider
        var htmlContent = readerProvider.currentChapterHtml.isNotEmpty
            ? readerProvider.currentChapterHtml
            : _generatePlaceholderContent(
                'Loading...',
                readerProvider.currentBook?.title ?? 'Book Title',
              );

        // Inject EPUB's embedded CSS into HTML for proper styling
        final epubCss = readerProvider.currentChapterCss;
        if (epubCss.isNotEmpty) {
          htmlContent = _injectEpubCss(htmlContent, epubCss);
        }

        // Inject highlighting CSS for media overlay sync
        if (highlightedElementId != null) {
          htmlContent = _injectHighlightStyle(
            htmlContent,
            highlightedElementId,
            readingTheme.linkColor,
          );
        }

        // Inject annotation highlights for current chapter
        if (widget.annotationsEnabled) {
          final currentChapterId =
              'chapter-${readerProvider.currentChapterIndex}';
          final chapterAnnotations = annotationProvider.annotations
              .where((a) => a.chapterId == currentChapterId)
              .toList();
          if (chapterAnnotations.isNotEmpty) {
            htmlContent = _injectAnnotationHighlights(
              htmlContent,
              chapterAnnotations,
            );
          }
        }

        // Update selection area key when chapter changes to prevent
        // Flutter framework bug with stale selection indices
        _updateSelectionAreaKeyIfNeeded(readerProvider.currentChapterIndex);

        // Use Listener to intercept raw pointer events for tap detection
        // This works around SelectionArea absorbing tap gestures
        // Wrap in SizedBox.expand to ensure full-screen hit area
        return SizedBox.expand(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: SelectionArea(
              // Use UniqueKey that changes when chapter changes to force
              // complete rebuild and avoid Flutter framework bug with
              // stale selection indices (flutter/flutter#123456).
              key: _selectionAreaKey,
              onSelectionChanged: widget.annotationsEnabled
                  ? (selectedContent) {
                      // Store selection - don't show menu immediately
                      // User will tap on selection to show menu
                      // Don't use setState to avoid rebuild that clears selection
                      _currentSelection = selectedContent?.plainText;
                      _selectionChapterIndex =
                          readerProvider.currentChapterIndex;
                      debugPrint(
                        'Selection stored: ${_currentSelection?.length ?? 0} chars',
                      );
                    }
                  : null,
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: readingTheme.marginHorizontal,
                  vertical: readingTheme.marginVertical,
                ),
                // In landscape mode on phones, constrain content width for better readability
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Max width in landscape: 600px for comfortable reading column
                      // In portrait or tablet/desktop, use full width
                      maxWidth: context.isPhoneLandscape
                          ? 600
                          : double.infinity,
                    ),
                    child: Html(
                      data: htmlContent,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(readingTheme.fontSize),
                          fontFamily: readingTheme.fontFamily,
                          lineHeight: LineHeight(readingTheme.lineHeight),
                          color: readingTheme.textColor,
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: readingTheme.fontSize),
                          textAlign: TextAlign.justify,
                        ),
                        'h1': Style(
                          fontSize: FontSize(readingTheme.fontSize * 1.8),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(
                            top: readingTheme.fontSize * 2,
                            bottom: readingTheme.fontSize,
                          ),
                        ),
                        'h2': Style(
                          fontSize: FontSize(readingTheme.fontSize * 1.5),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(
                            top: readingTheme.fontSize * 1.5,
                            bottom: readingTheme.fontSize * 0.75,
                          ),
                        ),
                        'h3': Style(
                          fontSize: FontSize(readingTheme.fontSize * 1.2),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(
                            top: readingTheme.fontSize,
                            bottom: readingTheme.fontSize * 0.5,
                          ),
                        ),
                        'a': Style(
                          color: readingTheme.linkColor,
                          textDecoration: TextDecoration.underline,
                        ),
                        'em': Style(fontStyle: FontStyle.italic),
                        'strong': Style(fontWeight: FontWeight.bold),
                        'blockquote': Style(
                          margin: Margins.symmetric(
                            vertical: readingTheme.fontSize,
                            horizontal: readingTheme.fontSize * 2,
                          ),
                          padding: HtmlPaddings.only(
                            left: readingTheme.fontSize,
                          ),
                          border: Border(
                            left: BorderSide(
                              color: readingTheme.textColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 3,
                            ),
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        'ul': Style(
                          margin: Margins.only(
                            top: readingTheme.fontSize * 0.5,
                            bottom: readingTheme.fontSize * 0.5,
                          ),
                        ),
                        'ol': Style(
                          margin: Margins.only(
                            top: readingTheme.fontSize * 0.5,
                            bottom: readingTheme.fontSize * 0.5,
                          ),
                        ),
                        'li': Style(
                          margin: Margins.only(
                            bottom: readingTheme.fontSize * 0.25,
                          ),
                        ),
                        'img': Style(
                          margin: Margins.symmetric(
                            vertical: readingTheme.fontSize,
                          ),
                        ),
                        // Code styling
                        'code': Style(
                          fontFamily: 'monospace',
                          fontSize: FontSize(readingTheme.fontSize * 0.9),
                          backgroundColor: readingTheme.textColor.withValues(
                            alpha: 0.08,
                          ),
                          padding: HtmlPaddings.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                        'pre': Style(
                          fontFamily: 'monospace',
                          fontSize: FontSize(readingTheme.fontSize * 0.85),
                          backgroundColor: readingTheme.textColor.withValues(
                            alpha: 0.06,
                          ),
                          padding: HtmlPaddings.all(
                            readingTheme.fontSize * 0.75,
                          ),
                          margin: Margins.symmetric(
                            vertical: readingTheme.fontSize,
                          ),
                          lineHeight: const LineHeight(1.4),
                        ),
                        'pre code': Style(
                          backgroundColor: Colors.transparent,
                          padding: HtmlPaddings.zero,
                        ),
                        'kbd': Style(
                          fontFamily: 'monospace',
                          fontSize: FontSize(readingTheme.fontSize * 0.85),
                          backgroundColor: readingTheme.textColor.withValues(
                            alpha: 0.1,
                          ),
                          border: Border.all(
                            color: readingTheme.textColor.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                          padding: HtmlPaddings.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                        ),
                        'samp': Style(
                          fontFamily: 'monospace',
                          fontSize: FontSize(readingTheme.fontSize * 0.9),
                        ),
                        'var': Style(
                          fontFamily: 'monospace',
                          fontStyle: FontStyle.italic,
                        ),
                        // Tables
                        'table': Style(
                          margin: Margins.symmetric(
                            vertical: readingTheme.fontSize,
                          ),
                        ),
                        'th': Style(
                          fontWeight: FontWeight.bold,
                          padding: HtmlPaddings.all(8),
                          backgroundColor: readingTheme.textColor.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        'td': Style(padding: HtmlPaddings.all(8)),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url == null) return;

                        // Handle anchor links within current chapter
                        if (url.startsWith('#')) {
                          // TODO: Implement anchor navigation within chapter
                          debugPrint('Navigate to anchor: $url');
                          return;
                        }

                        // Check if it's an external link (http/https/mailto/tel)
                        if (url.startsWith('http://') ||
                            url.startsWith('https://') ||
                            url.startsWith('mailto:') ||
                            url.startsWith('tel:')) {
                          // TODO: Open external link in browser
                          debugPrint('External link: $url');
                          return;
                        }

                        // Treat as internal EPUB link (chapter navigation)
                        // Links like 'chapter.xhtml', 'text/chapter.xhtml', 'chapter.xhtml#section'
                        debugPrint('Internal link: $url');
                        readerProvider.navigateToHref(url);
                      },
                      // Handle images from EPUB resources
                      extensions: [
                        TagExtension(
                          tagsToExtend: {'img'},
                          builder: (extensionContext) {
                            final src = extensionContext.attributes['src'];
                            if (src != null) {
                              // Handle base64 data URIs (used by CBR/CBZ)
                              if (src.startsWith('data:image/')) {
                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    vertical: readingTheme.fontSize,
                                  ),
                                  child: Image.memory(
                                    _decodeDataUri(src),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder(
                                        '${src.substring(0, 30)}...',
                                        readingTheme,
                                        error: 'Failed to decode image',
                                      );
                                    },
                                  ),
                                );
                              }

                              // Try to find the image in the chapter images
                              final images =
                                  readerProvider.currentChapterImages;
                              final imageBytes = _findImageBytes(src, images);

                              if (imageBytes != null) {
                                // Render actual image from EPUB
                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    vertical: readingTheme.fontSize,
                                  ),
                                  child: Image.memory(
                                    imageBytes,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder(
                                        src,
                                        readingTheme,
                                        error: 'Failed to load image',
                                      );
                                    },
                                  ),
                                );
                              }

                              // Show placeholder if image not found
                              return _buildImagePlaceholder(src, readingTheme);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        // Handle annotation highlights (mark tags)
                        TagExtension(
                          tagsToExtend: {'mark'},
                          builder: (extensionContext) {
                            final annotationId = extensionContext
                                .attributes['data-annotation-id'];
                            final style = extensionContext.attributes['style'];

                            // Parse background color from inline style
                            Color? bgColor;
                            if (style != null) {
                              final bgMatch = RegExp(
                                r'background-color:\s*rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)',
                              ).firstMatch(style);
                              if (bgMatch != null) {
                                bgColor = Color.fromRGBO(
                                  int.parse(bgMatch.group(1)!),
                                  int.parse(bgMatch.group(2)!),
                                  int.parse(bgMatch.group(3)!),
                                  double.parse(bgMatch.group(4)!),
                                );
                              }
                            }

                            // Get the text content from the element
                            final textContent =
                                extensionContext.element?.text ?? '';

                            return GestureDetector(
                              onTap: annotationId != null
                                  ? () => _showAnnotationDetails(
                                      context,
                                      annotationId,
                                      annotationProvider,
                                    )
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      bgColor ??
                                      Colors.yellow.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  textContent,
                                  style: TextStyle(
                                    fontSize: readingTheme.fontSize,
                                    fontFamily: readingTheme.fontFamily,
                                    height: readingTheme.lineHeight,
                                    color: readingTheme.textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows the annotation menu as a modal bottom sheet.
  ///
  /// This is an alternative to contextMenuBuilder which doesn't work on macOS.
  void _showAnnotationMenu(
    BuildContext context,
    String selectedText,
    int chapterIndex,
  ) {
    debugPrint('_showAnnotationMenu called with: $selectedText');

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highlight: "${selectedText.length > 50 ? '${selectedText.substring(0, 50)}...' : selectedText}"',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                const Text('Choose highlight color:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AnnotationColor.values.map((color) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _clearSelection();
                        _createAnnotation(selectedText, chapterIndex, color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getAnnotationColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('Add Note'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _clearSelection();
                    _showNoteDialogForSelection(selectedText, chapterIndex);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _clearSelection();
                    Clipboard.setData(ClipboardData(text: selectedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows annotation details when a highlight is tapped.
  void _showAnnotationDetails(
    BuildContext context,
    String annotationId,
    AnnotationProvider annotationProvider,
  ) {
    final annotation = annotationProvider.getAnnotation(annotationId);
    if (annotation == null) {
      debugPrint('Annotation not found: $annotationId');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with color indicator
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getAnnotationColor(annotation.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Highlight',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        final deleted = await annotationProvider
                            .deleteAnnotation(annotationId);
                        if (deleted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Highlight deleted')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Highlighted text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAnnotationColor(
                      annotation.color,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${annotation.text}"',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),

                // Note if present
                if (annotation.note != null && annotation.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note:',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(annotation.note!),
                ],

                const SizedBox(height: 16),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Change color
                    TextButton.icon(
                      icon: const Icon(Icons.palette),
                      label: const Text('Color'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showColorPicker(
                          context,
                          annotation,
                          annotationProvider,
                        );
                      },
                    ),
                    // Edit note
                    TextButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: Text(
                        annotation.note?.isNotEmpty == true
                            ? 'Edit Note'
                            : 'Add Note',
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        final result = await NoteEditorDialog.show(
                          context: context,
                          selectedText: annotation.text,
                          initialNote: annotation.note,
                          initialColor: annotation.color,
                        );
                        if (result != null) {
                          await annotationProvider.updateNote(
                            annotationId,
                            result.note.isNotEmpty ? result.note : null,
                          );
                          if (result.color != annotation.color) {
                            await annotationProvider.updateColor(
                              annotationId,
                              result.color,
                            );
                          }
                        }
                      },
                    ),
                    // Copy
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Clipboard.setData(ClipboardData(text: annotation.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a color picker for changing annotation color.
  void _showColorPicker(
    BuildContext context,
    Annotation annotation,
    AnnotationProvider annotationProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose highlight color',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AnnotationColor.values.map((color) {
                    final isSelected = color == annotation.color;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        if (color != annotation.color) {
                          await annotationProvider.updateColor(
                            annotation.id,
                            color,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Color updated')),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getAnnotationColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.black26,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAnnotationColor(AnnotationColor color) {
    switch (color) {
      case AnnotationColor.yellow:
        return const Color(0xFFFFEB3B);
      case AnnotationColor.green:
        return const Color(0xFF4CAF50);
      case AnnotationColor.blue:
        return const Color(0xFF2196F3);
      case AnnotationColor.pink:
        return const Color(0xFFE91E63);
      case AnnotationColor.purple:
        return const Color(0xFF9C27B0);
      case AnnotationColor.orange:
        return const Color(0xFFFF9800);
    }
  }

  Future<void> _createAnnotation(
    String selectedText,
    int chapterIndex,
    AnnotationColor color,
  ) async {
    final annotationProvider = context.read<AnnotationProvider>();
    annotationProvider.setSelection(
      selectedText: selectedText,
      chapterIndex: chapterIndex,
    );
    await annotationProvider.createAnnotationFromSelection(color: color);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight created')));
    }
  }

  Future<void> _showNoteDialogForSelection(
    String selectedText,
    int chapterIndex,
  ) async {
    final result = await NoteEditorDialog.show(
      context: context,
      selectedText: selectedText,
    );

    if (result != null && mounted) {
      final annotationProvider = context.read<AnnotationProvider>();
      annotationProvider.setSelection(
        selectedText: selectedText,
        chapterIndex: chapterIndex,
      );
      await annotationProvider.createAnnotationFromSelection(
        color: result.color,
        note: result.note.isNotEmpty ? result.note : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Annotation created')));
      }
    }
  }

  /// Injects annotation highlights into the HTML content.
  ///
  /// This method finds the annotated text in the HTML and wraps it with
  /// a `<mark>` tag that has the appropriate background color.
  /// Annotations are processed from longest to shortest text to avoid
  /// nested replacement issues.
  String _injectAnnotationHighlights(
    String html,
    List<Annotation> annotations,
  ) {
    if (annotations.isEmpty) return html;

    // Sort annotations by text length (longest first) to avoid
    // shorter texts matching within longer highlights
    final sortedAnnotations = List<Annotation>.from(annotations)
      ..sort((a, b) => b.text.length.compareTo(a.text.length));

    var result = html;

    for (final annotation in sortedAnnotations) {
      final text = annotation.text.trim();
      if (text.isEmpty) continue;

      // Get the highlight color with semi-transparent alpha
      final color = AnnotationColorHelper.getColor(annotation.color);
      final r = (color.r * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final b = (color.b * 255.0).round().clamp(0, 255);

      // Build the mark tag with inline style
      final markStart =
          '<mark class="rw-annotation" data-annotation-id="${annotation.id}" '
          'style="background-color: rgba($r, $g, $b, 0.4); '
          'border-radius: 2px; padding: 0 2px;">';
      const markEnd = '</mark>';

      // Escape special regex characters in the text
      final escapedText = RegExp.escape(text);

      // Try to find and replace the exact text
      // We use a regex that matches the text while preserving HTML structure
      // This simple approach works when text doesn't span multiple elements
      final regex = RegExp(escapedText, caseSensitive: true);

      if (regex.hasMatch(result)) {
        // Only replace the first occurrence to avoid highlighting duplicates
        result = result.replaceFirst(regex, '$markStart$text$markEnd');
        debugPrint(
          'Injected highlight for annotation ${annotation.id}: '
          '"${text.length > 30 ? '${text.substring(0, 30)}...' : text}"',
        );
      } else {
        // Try case-insensitive match as fallback
        final regexInsensitive = RegExp(escapedText, caseSensitive: false);
        if (regexInsensitive.hasMatch(result)) {
          final match = regexInsensitive.firstMatch(result);
          if (match != null) {
            final matchedText = match.group(0)!;
            result = result.replaceFirst(
              regexInsensitive,
              '$markStart$matchedText$markEnd',
            );
            debugPrint(
              'Injected highlight (case-insensitive) for ${annotation.id}',
            );
          }
        } else {
          debugPrint(
            'Could not find text for annotation ${annotation.id}: '
            '"${text.length > 30 ? '${text.substring(0, 30)}...' : text}"',
          );
        }
      }
    }

    return result;
  }

  /// Injects CSS for annotation highlights into the HTML content.
  ///
  /// This method generates CSS classes for each annotation to render
  /// highlights in the HTML content. Call this after loading annotations
  /// to visually display them in the reader.
  // ignore: unused_element
  String _injectAnnotationHighlightsCss(
    String html,
    List<Annotation> annotations,
  ) {
    if (annotations.isEmpty) return html;

    final cssBuffer = StringBuffer('<style type="text/css">\n');

    for (final annotation in annotations) {
      final color = AnnotationColorHelper.getColor(annotation.color);
      final r = (color.r * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final b = (color.b * 255.0).round().clamp(0, 255);

      cssBuffer.writeln('''
.annotation-${annotation.id} {
  background-color: rgba($r, $g, $b, 0.4);
  border-radius: 2px;
  cursor: pointer;
}
''');
    }

    cssBuffer.writeln('</style>');
    final styleTag = cssBuffer.toString();

    // Inject styles into HTML
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$styleTag');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$styleTag');
    } else {
      return styleTag + html;
    }
  }

  /// Generate placeholder HTML content for testing
  String _generatePlaceholderContent(String chapterTitle, String bookTitle) {
    return '''
      <h1>$chapterTitle</h1>

      <p>
        This is placeholder content for the e-reader. In a production implementation,
        this would be replaced with the actual chapter content from the EPUB file.
      </p>

      <p>
        The content is rendered using the <strong>flutter_html</strong> package,
        which supports most HTML tags and CSS styling. The reading theme can be
        customized through the settings menu.
      </p>

      <h2>Reading Features</h2>

      <p>
        The ReadWhere e-reader supports the following features:
      </p>

      <ul>
        <li>Customizable font size, family, and line height</li>
        <li>Multiple reading themes (light, dark, sepia)</li>
        <li>Chapter navigation with table of contents</li>
        <li>Bookmarks and reading progress tracking</li>
        <li>Swipe gestures for page navigation</li>
        <li>Responsive text layout with proper margins</li>
      </ul>

      <h3>HTML Support</h3>

      <p>
        The reader supports <em>emphasized text</em>, <strong>bold text</strong>,
        and <a href="#example">hyperlinks</a>. Images can be embedded within the
        content as well.
      </p>

      <blockquote>
        "Reading is to the mind what exercise is to the body." - Joseph Addison
      </blockquote>

      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
        consequat.
      </p>

      <p>
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
        eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,
        sunt in culpa qui officia deserunt mollit anim id est laborum.
      </p>

      <h2>Next Steps</h2>

      <p>
        To display actual book content, integrate with the EPUB plugin system to:
      </p>

      <ol>
        <li>Parse EPUB files and extract chapter HTML</li>
        <li>Load embedded images and resources</li>
        <li>Handle internal navigation and anchors</li>
        <li>Track reading position with CFI (Canonical Fragment Identifier)</li>
        <li>Support annotations and highlights</li>
      </ol>

      <p>
        The current placeholder implementation demonstrates the layout and styling
        capabilities of the reader interface.
      </p>

      <p>
        You are currently reading: <strong>$bookTitle</strong>
      </p>
    ''';
  }

  /// Decode a base64 data URI to bytes.
  ///
  /// Handles data URIs in the format: data:image/jpeg;base64,...
  Uint8List _decodeDataUri(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      return Uint8List(0);
    }
    final base64Data = dataUri.substring(commaIndex + 1);
    return base64Decode(base64Data);
  }

  /// Find image bytes from the images map, handling path variations.
  ///
  /// EPUB images may be referenced with different path formats:
  /// - Relative: "../images/cover.jpg"
  /// - Absolute from root: "/OEBPS/images/cover.jpg"
  /// - Just filename: "cover.jpg"
  Uint8List? _findImageBytes(String src, Map<String, Uint8List> images) {
    // Direct match
    if (images.containsKey(src)) {
      return images[src];
    }

    // Try matching by filename only
    final srcFilename = src.split('/').last;
    for (final entry in images.entries) {
      final entryFilename = entry.key.split('/').last;
      if (entryFilename == srcFilename) {
        return entry.value;
      }
    }

    // Try matching by normalized path (remove ../ and leading /)
    final normalizedSrc = src
        .replaceAll('../', '')
        .replaceAll(RegExp(r'^/'), '');
    for (final entry in images.entries) {
      final normalizedKey = entry.key
          .replaceAll('../', '')
          .replaceAll(RegExp(r'^/'), '');
      if (normalizedKey == normalizedSrc ||
          normalizedKey.endsWith(normalizedSrc) ||
          normalizedSrc.endsWith(normalizedKey)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Build a placeholder widget for images that couldn't be loaded.
  Widget _buildImagePlaceholder(
    String src,
    ReadingThemeData readingTheme, {
    String? error,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: readingTheme.fontSize),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: readingTheme.textColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: readingTheme.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Image not found',
            style: TextStyle(
              fontSize: readingTheme.fontSize * 0.75,
              color: readingTheme.textColor.withValues(alpha: 0.5),
            ),
          ),
          Text(
            src.split('/').last,
            style: TextStyle(
              fontSize: readingTheme.fontSize * 0.6,
              color: readingTheme.textColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Injects the EPUB's embedded CSS into the HTML content.
  ///
  /// This preserves the publisher's intended styling for code blocks,
  /// tips, callouts, and other formatted content.
  String _injectEpubCss(String html, String css) {
    if (css.isEmpty) return html;

    // Sanitize CSS to prevent layout issues with flutter_html
    // Some EPUB CSS rules cause rendering problems like one-char-per-line
    var sanitizedCss = css
        // Remove fixed widths that can break text flow
        .replaceAll(RegExp(r'width\s*:\s*\d+[^;]*;'), '')
        // Remove max-width that can constrain content
        .replaceAll(RegExp(r'max-width\s*:\s*\d+[^;]*;'), '')
        // Remove column layouts that flutter_html doesn't support well
        .replaceAll(RegExp(r'column-[^:]+\s*:[^;]+;'), '')
        // Remove word-break: break-all which can cause one-char-per-line
        .replaceAll(RegExp(r'word-break\s*:\s*break-all[^;]*;'), '');

    // Wrap CSS in a style tag
    final styleTag = '<style type="text/css">\n$sanitizedCss\n</style>';

    // Inject into <head> if present, otherwise prepend to content
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$styleTag');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$styleTag');
    } else {
      return styleTag + html;
    }
  }

  /// Injects CSS styling to highlight the element with the given ID.
  ///
  /// This is used for media overlay synchronization to highlight the
  /// currently spoken text element during audio playback.
  String _injectHighlightStyle(
    String html,
    String elementId,
    Color highlightColor,
  ) {
    // Convert color to CSS rgba format
    final r = highlightColor.r.toInt();
    final g = highlightColor.g.toInt();
    final b = highlightColor.b.toInt();
    final cssColor = 'rgba($r, $g, $b, 0.3)';

    // Create CSS style for the highlighted element
    final highlightCss =
        '''
<style>
#$elementId {
  background-color: $cssColor;
  border-radius: 4px;
  padding: 2px 4px;
  transition: background-color 0.2s ease-in-out;
}
</style>
''';

    // Inject the style at the beginning of the HTML
    // Check if there's a <head> tag to inject into, otherwise prepend
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$highlightCss');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$highlightCss');
    } else {
      return highlightCss + html;
    }
  }
}
