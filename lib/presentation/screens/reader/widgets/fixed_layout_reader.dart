import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../providers/reader_provider.dart';
import '../../../themes/reading_themes.dart';
import '../../../../plugins/epub/readwhere_epub_controller.dart';
import '../../../../plugins/cbr/cbr_reader_controller.dart';
import '../../../../plugins/cbz/cbz_reader_controller.dart';

/// Widget for displaying fixed-layout content (comics, pre-paginated EPUBs).
///
/// This widget renders fixed-layout content with:
/// - Proper viewport sizing based on content dimensions
/// - Zoom and pan using InteractiveViewer
/// - Horizontal page navigation (swipe-based)
/// - Page fitting to screen while preserving aspect ratio
///
/// Supports:
/// - Fixed-layout EPUBs (HTML rendering with viewport constraints)
/// - CBR/CBZ comics (direct image rendering)
class FixedLayoutReader extends StatefulWidget {
  const FixedLayoutReader({super.key});

  @override
  State<FixedLayoutReader> createState() => _FixedLayoutReaderState();
}

class _FixedLayoutReaderState extends State<FixedLayoutReader> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final readingTheme = context.readingTheme;

    return Consumer<ReaderProvider>(
      builder: (context, readerProvider, child) {
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

        final controller = readerProvider.readerController;

        // Handle comic formats (CBR/CBZ) - render images directly
        if (controller is CbrReaderController) {
          return _buildComicViewer(
            readingTheme,
            controller.getPageBytes(controller.currentChapterIndex),
            readerProvider.currentChapterIndex,
            readerProvider.tableOfContents.length,
          );
        }

        if (controller is CbzReaderController) {
          return _buildComicViewer(
            readingTheme,
            controller.getPageBytes(controller.currentChapterIndex),
            readerProvider.currentChapterIndex,
            readerProvider.tableOfContents.length,
          );
        }

        // Handle fixed-layout EPUBs - render HTML with viewport constraints
        int viewportWidth = 1024; // default
        int viewportHeight = 768; // default

        if (controller is ReadwhereEpubController) {
          viewportWidth = controller.viewportWidth ?? 1024;
          viewportHeight = controller.viewportHeight ?? 768;
        }

        // Get the actual chapter HTML content from the provider
        final htmlContent = readerProvider.currentChapterHtml.isNotEmpty
            ? readerProvider.currentChapterHtml
            : _generatePlaceholderContent();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the scale to fit the viewport within the available space
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            final scaleX = availableWidth / viewportWidth;
            final scaleY = availableHeight / viewportHeight;
            final scale = scaleX < scaleY ? scaleX : scaleY;

            final scaledWidth = viewportWidth * scale;
            final scaledHeight = viewportHeight * scale;

            return GestureDetector(
              onDoubleTap: _resetZoom,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(100),
                child: Center(
                  child: Container(
                    width: scaledWidth,
                    height: scaledHeight,
                    decoration: BoxDecoration(
                      color: readingTheme.backgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: viewportWidth.toDouble(),
                          height: viewportHeight.toDouble(),
                          child: _buildPageContent(
                            htmlContent,
                            readingTheme,
                            viewportWidth,
                            viewportHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build the comic viewer with direct image rendering.
  ///
  /// Uses InteractiveViewer for zoom/pan functionality on comic pages.
  Widget _buildComicViewer(
    ReadingThemeData readingTheme,
    Uint8List? imageBytes,
    int currentPage,
    int totalPages,
  ) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: readingTheme.textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load page ${currentPage + 1}',
              style: TextStyle(
                color: readingTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: Container(
        color: Colors.black,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(100),
          child: Center(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: readingTheme.textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading image',
                        style: TextStyle(
                          color: readingTheme.textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build the page content with proper fixed-layout styling.
  Widget _buildPageContent(
    String htmlContent,
    ReadingThemeData readingTheme,
    int viewportWidth,
    int viewportHeight,
  ) {
    return Html(
      data: htmlContent,
      style: {
        'html': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          width: Width(viewportWidth.toDouble()),
          height: Height(viewportHeight.toDouble()),
        ),
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          width: Width(viewportWidth.toDouble()),
          height: Height(viewportHeight.toDouble()),
          color: readingTheme.textColor,
        ),
        // Fixed-layout EPUBs typically position elements absolutely
        // so we don't apply much additional styling
        'p': Style(margin: Margins.zero),
        'div': Style(margin: Margins.zero),
        'span': Style(color: readingTheme.textColor),
        'img': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
      onLinkTap: (url, attributes, element) {
        if (url != null && url.startsWith('#')) {
          debugPrint('Navigate to anchor: $url');
        } else if (url != null) {
          debugPrint('External link: $url');
        }
      },
    );
  }

  /// Generate placeholder content for fixed-layout.
  String _generatePlaceholderContent() {
    return '''
      <div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;">
        <p style="text-align: center; font-size: 24px;">Loading fixed-layout page...</p>
      </div>
    ''';
  }
}

/// Badge showing fixed-layout mode indicator.
class FixedLayoutBadge extends StatelessWidget {
  const FixedLayoutBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_square, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Fixed Layout',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
