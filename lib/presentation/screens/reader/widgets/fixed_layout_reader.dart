import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../providers/reader_provider.dart';
import '../../../themes/reading_themes.dart';
import '../../../../plugins/epub/readwhere_epub_controller.dart';

/// Widget for displaying fixed-layout (pre-paginated) EPUB content.
///
/// This widget renders fixed-layout EPUBs with:
/// - Proper viewport sizing based on the EPUB's specified dimensions
/// - Zoom and pan using InteractiveViewer
/// - Horizontal page navigation (swipe-based)
/// - Page fitting to screen while preserving aspect ratio
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

        // Get viewport dimensions from the controller
        final controller = readerProvider.readerController;
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
