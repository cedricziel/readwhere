import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';

import '../../../providers/reader_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../themes/reading_themes.dart';
import 'package:readwhere_cbr_plugin/readwhere_cbr_plugin.dart';
import 'package:readwhere_cbz_plugin/readwhere_cbz_plugin.dart';
import 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';

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
  /// Callback when the center of the screen is tapped (to toggle controls)
  final VoidCallback? onToggleControls;

  const FixedLayoutReader({super.key, this.onToggleControls});

  @override
  State<FixedLayoutReader> createState() => _FixedLayoutReaderState();
}

class _FixedLayoutReaderState extends State<FixedLayoutReader> {
  final TransformationController _transformationController =
      TransformationController();

  // Panel mode state
  bool _isDetectingPanels = false;
  int _currentPanelIndex = 0;
  List<Panel>? _currentPanels;
  int? _lastDetectedPage;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  /// Detect panels for the current page if not already cached.
  void _detectPanels(
    dynamic controller,
    int pageIndex,
    ReadingDirection direction,
  ) {
    // Skip if already detecting or same page
    if (_isDetectingPanels || _lastDetectedPage == pageIndex) return;

    setState(() {
      _isDetectingPanels = true;
    });

    try {
      List<Panel>? panels;
      if (controller is CbrReaderController) {
        controller.setReadingDirection(direction);
        panels = controller.detectPanels(pageIndex);
      } else if (controller is CbzReaderController) {
        controller.setReadingDirection(direction);
        panels = controller.detectPanels(pageIndex);
      }

      setState(() {
        _currentPanels = panels;
        _lastDetectedPage = pageIndex;
        _currentPanelIndex = 0;
        _isDetectingPanels = false;
      });
    } catch (e) {
      debugPrint('Panel detection error: $e');
      setState(() {
        _currentPanels = null;
        _isDetectingPanels = false;
      });
    }
  }

  /// Navigate to the next panel or next page.
  void _nextPanel(
    ReaderProvider readerProvider,
    dynamic controller,
    int totalPages,
  ) {
    if (_currentPanels == null || _currentPanels!.isEmpty) {
      // No panels detected, go to next page
      if (readerProvider.currentChapterIndex < totalPages - 1) {
        readerProvider.goToChapter(readerProvider.currentChapterIndex + 1);
        _resetPanelState();
      }
      return;
    }

    if (_currentPanelIndex < _currentPanels!.length - 1) {
      setState(() {
        _currentPanelIndex++;
      });
      _resetZoom();
    } else {
      // Last panel, go to next page
      if (readerProvider.currentChapterIndex < totalPages - 1) {
        readerProvider.goToChapter(readerProvider.currentChapterIndex + 1);
        _resetPanelState();
      }
    }
  }

  /// Navigate to the previous panel or previous page.
  void _previousPanel(
    ReaderProvider readerProvider,
    dynamic controller,
    int totalPages,
  ) {
    if (_currentPanels == null || _currentPanels!.isEmpty) {
      // No panels detected, go to previous page
      if (readerProvider.currentChapterIndex > 0) {
        readerProvider.goToChapter(readerProvider.currentChapterIndex - 1);
        _resetPanelState();
      }
      return;
    }

    if (_currentPanelIndex > 0) {
      setState(() {
        _currentPanelIndex--;
      });
      _resetZoom();
    } else {
      // First panel, go to previous page (at last panel)
      if (readerProvider.currentChapterIndex > 0) {
        readerProvider.goToChapter(readerProvider.currentChapterIndex - 1);
        // Set to last panel of previous page (will be updated on next build)
        _resetPanelState();
        _currentPanelIndex = -1; // Signal to go to last panel
      }
    }
  }

  void _resetPanelState() {
    _currentPanels = null;
    _lastDetectedPage = null;
    _currentPanelIndex = 0;
  }

  /// Navigate to the next page (full-page mode).
  void _nextPage(ReaderProvider readerProvider, int totalPages) {
    if (readerProvider.currentChapterIndex < totalPages - 1) {
      readerProvider.goToChapter(readerProvider.currentChapterIndex + 1);
      _resetPanelState();
      _resetZoom();
    }
  }

  /// Navigate to the previous page (full-page mode).
  void _previousPage(ReaderProvider readerProvider, int totalPages) {
    if (readerProvider.currentChapterIndex > 0) {
      readerProvider.goToChapter(readerProvider.currentChapterIndex - 1);
      _resetPanelState();
      _resetZoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingTheme = context.readingTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final panelModeEnabled = settingsProvider.comicPanelModeEnabled;
    final readingDirection = settingsProvider.comicReadingDirection;

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
        final totalPages = readerProvider.tableOfContents.length;

        // Handle comic formats (CBR/CBZ) - render images directly
        if (controller is CbrReaderController) {
          return _buildComicViewer(
            context,
            readingTheme,
            controller,
            controller.getPageBytes(controller.currentChapterIndex),
            readerProvider.currentChapterIndex,
            totalPages,
            readerProvider,
            panelModeEnabled,
            readingDirection,
          );
        }

        if (controller is CbzReaderController) {
          return _buildComicViewer(
            context,
            readingTheme,
            controller,
            controller.getPageBytes(controller.currentChapterIndex),
            readerProvider.currentChapterIndex,
            totalPages,
            readerProvider,
            panelModeEnabled,
            readingDirection,
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
                            readerProvider,
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
  /// Supports panel mode for frame-by-frame reading.
  Widget _buildComicViewer(
    BuildContext context,
    ReadingThemeData readingTheme,
    dynamic controller,
    Uint8List? imageBytes,
    int currentPage,
    int totalPages,
    ReaderProvider readerProvider,
    bool panelModeEnabled,
    ReadingDirection readingDirection,
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

    // Trigger panel detection if panel mode is enabled
    if (panelModeEnabled && !_isDetectingPanels) {
      // Schedule panel detection after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectPanels(controller, currentPage, readingDirection);
      });
    }

    // Handle going to last panel when coming from next page
    if (_currentPanelIndex == -1 &&
        _currentPanels != null &&
        _currentPanels!.isNotEmpty) {
      _currentPanelIndex = _currentPanels!.length - 1;
    }

    // Get panel image if in panel mode and panels are detected
    Uint8List? displayBytes = imageBytes;
    if (panelModeEnabled &&
        _currentPanels != null &&
        _currentPanels!.isNotEmpty &&
        _currentPanelIndex >= 0 &&
        _currentPanelIndex < _currentPanels!.length) {
      // Get cropped panel image from controller
      if (controller is CbrReaderController) {
        final panelBytes = controller.getPanelImage(
          currentPage,
          _currentPanelIndex,
        );
        if (panelBytes != null) {
          displayBytes = panelBytes;
        }
      } else if (controller is CbzReaderController) {
        final panelBytes = controller.getPanelImage(
          currentPage,
          _currentPanelIndex,
        );
        if (panelBytes != null) {
          displayBytes = panelBytes;
        }
      }
    }

    return Stack(
      children: [
        // Main image viewer with gesture detection
        GestureDetector(
          onDoubleTap: _resetZoom,
          onTapUp: (details) {
            // Tap zone navigation - left third for previous, right third for next
            final screenWidth = MediaQuery.of(context).size.width;
            final tapX = details.globalPosition.dx;

            if (tapX < screenWidth / 3) {
              // Left third - previous page/panel
              if (panelModeEnabled) {
                _previousPanel(readerProvider, controller, totalPages);
              } else {
                _previousPage(readerProvider, totalPages);
              }
            } else if (tapX > screenWidth * 2 / 3) {
              // Right third - next page/panel
              if (panelModeEnabled) {
                _nextPanel(readerProvider, controller, totalPages);
              } else {
                _nextPage(readerProvider, totalPages);
              }
            } else {
              // Center third - toggle controls
              widget.onToggleControls?.call();
            }
          },
          onHorizontalDragEnd: (details) {
            // Swipe navigation - works in both panel mode and full-page mode
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200) {
                // Swipe left - next page/panel
                if (panelModeEnabled) {
                  _nextPanel(readerProvider, controller, totalPages);
                } else {
                  _nextPage(readerProvider, totalPages);
                }
              } else if (details.primaryVelocity! > 200) {
                // Swipe right - previous page/panel
                if (panelModeEnabled) {
                  _previousPanel(readerProvider, controller, totalPages);
                } else {
                  _previousPage(readerProvider, totalPages);
                }
              }
            }
          },
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: Image.memory(
                  displayBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: readingTheme.textColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading image',
                            style: TextStyle(
                              color: readingTheme.textColor.withValues(
                                alpha: 0.5,
                              ),
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
        ),

        // Panel mode indicator and controls
        if (panelModeEnabled)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(child: _buildPanelIndicator(context, totalPages)),
          ),

        // Loading indicator for panel detection
        if (_isDetectingPanels)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Detecting panels...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build the panel indicator showing current panel position.
  Widget _buildPanelIndicator(BuildContext context, int totalPages) {
    final panelCount = _currentPanels?.length ?? 0;
    final currentPanel = _currentPanelIndex + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel mode icon
          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          // Panel counter
          if (panelCount > 0)
            Text(
              'Panel $currentPanel of $panelCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            const Text(
              'Full page',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          const SizedBox(width: 16),
          // Panel dots indicator
          if (panelCount > 0 && panelCount <= 10)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(panelCount, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPanelIndex
                        ? Colors.white
                        : Colors.white38,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  /// Build the page content with proper fixed-layout styling.
  Widget _buildPageContent(
    String htmlContent,
    ReadingThemeData readingTheme,
    int viewportWidth,
    int viewportHeight,
    ReaderProvider readerProvider,
  ) {
    return SelectionArea(
      // Use a key that changes when chapter or content changes to avoid
      // Flutter framework bug with stale selection indices (issue #123456).
      // The hashCode ensures a new SelectionArea when content loads.
      key: ValueKey(
        'selection_${readerProvider.currentChapterIndex}_${htmlContent.hashCode}',
      ),
      child: Html(
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
      ),
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
