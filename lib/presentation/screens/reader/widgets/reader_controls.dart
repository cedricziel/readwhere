import 'package:flutter/material.dart';
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';

/// Overlay controls for the reader screen
///
/// Provides top and bottom bars with navigation controls, settings,
/// and progress tracking. The controls can be shown/hidden with a fade animation.
class ReaderControls extends StatelessWidget {
  final bool visible;
  final String bookTitle;
  final int currentChapter;
  final int totalChapters;
  final double progress; // 0-100
  final VoidCallback onClose;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;
  final VoidCallback onTableOfContents;
  final VoidCallback? onAudio;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

  /// Whether this is comic content (CBR/CBZ) showing panel mode controls
  final bool isComic;

  /// Whether panel mode is currently enabled
  final bool panelModeEnabled;

  /// Current reading direction for comics
  final ReadingDirection readingDirection;

  /// Callback to toggle panel mode
  final VoidCallback? onTogglePanelMode;

  /// Callback to toggle reading direction
  final VoidCallback? onToggleReadingDirection;

  const ReaderControls({
    super.key,
    required this.visible,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.progress,
    required this.onClose,
    required this.onBookmark,
    required this.onSettings,
    required this.onTableOfContents,
    this.onAudio,
    required this.onProgressChanged,
    required this.onPreviousChapter,
    required this.onNextChapter,
    this.isComic = false,
    this.panelModeEnabled = false,
    this.readingDirection = ReadingDirection.leftToRight,
    this.onTogglePanelMode,
    this.onToggleReadingDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: visible ? 0 : -120,
          left: 0,
          right: 0,
          child: _TopBar(
            bookTitle: bookTitle,
            onClose: onClose,
            onBookmark: onBookmark,
            onSettings: onSettings,
            onAudio: onAudio,
            isComic: isComic,
            panelModeEnabled: panelModeEnabled,
            readingDirection: readingDirection,
            onTogglePanelMode: onTogglePanelMode,
            onToggleReadingDirection: onToggleReadingDirection,
          ),
        ),

        // Bottom bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: visible ? 0 : -200,
          left: 0,
          right: 0,
          child: _BottomBar(
            currentChapter: currentChapter,
            totalChapters: totalChapters,
            progress: progress,
            onTableOfContents: onTableOfContents,
            onProgressChanged: onProgressChanged,
            onPreviousChapter: onPreviousChapter,
            onNextChapter: onNextChapter,
          ),
        ),
      ],
    );
  }
}

/// Top bar with title and action buttons
class _TopBar extends StatelessWidget {
  final String bookTitle;
  final VoidCallback onClose;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;
  final VoidCallback? onAudio;
  final bool isComic;
  final bool panelModeEnabled;
  final ReadingDirection readingDirection;
  final VoidCallback? onTogglePanelMode;
  final VoidCallback? onToggleReadingDirection;

  const _TopBar({
    required this.bookTitle,
    required this.onClose,
    required this.onBookmark,
    required this.onSettings,
    this.onAudio,
    this.isComic = false,
    this.panelModeEnabled = false,
    this.readingDirection = ReadingDirection.leftToRight,
    this.onTogglePanelMode,
    this.onToggleReadingDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onClose,
                tooltip: 'Close book',
              ),

              // Book title
              Expanded(
                child: Text(
                  bookTitle,
                  style: TextStyle(
                    color: Colors.white,
                    // Use textScaler for accessibility - respects system text size
                    fontSize: MediaQuery.textScalerOf(context).scale(16),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action buttons
              if (onAudio != null)
                IconButton(
                  icon: const Icon(Icons.headphones, color: Colors.white),
                  onPressed: onAudio,
                  tooltip: 'Audio controls',
                ),

              // Comic-specific controls
              if (isComic) ...[
                // Panel mode toggle
                IconButton(
                  icon: Icon(
                    panelModeEnabled
                        ? Icons.grid_view_rounded
                        : Icons.crop_square_outlined,
                    color: panelModeEnabled ? Colors.amber : Colors.white,
                  ),
                  onPressed: onTogglePanelMode,
                  tooltip: panelModeEnabled
                      ? 'Disable panel mode'
                      : 'Enable panel mode',
                ),
                // Reading direction toggle
                IconButton(
                  icon: Icon(
                    readingDirection == ReadingDirection.leftToRight
                        ? Icons.format_textdirection_l_to_r
                        : Icons.format_textdirection_r_to_l,
                    color: Colors.white,
                  ),
                  onPressed: onToggleReadingDirection,
                  tooltip: readingDirection == ReadingDirection.leftToRight
                      ? 'Western (LTR)'
                      : 'Manga (RTL)',
                ),
              ],

              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: onBookmark,
                tooltip: 'Add bookmark',
              ),
              IconButton(
                icon: const Icon(Icons.text_format, color: Colors.white),
                onPressed: onSettings,
                tooltip: 'Reading settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom bar with navigation controls and progress slider
class _BottomBar extends StatelessWidget {
  final int currentChapter;
  final int totalChapters;
  final double progress;
  final VoidCallback onTableOfContents;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

  const _BottomBar({
    required this.currentChapter,
    required this.totalChapters,
    required this.progress,
    required this.onTableOfContents,
    required this.onProgressChanged,
    required this.onPreviousChapter,
    required this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    final hasChapters = totalChapters > 0;
    final chapterText = hasChapters
        ? 'Chapter ${currentChapter + 1} of $totalChapters'
        : 'No chapters';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chapter navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous chapter button
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: hasChapters && currentChapter > 0
                        ? onPreviousChapter
                        : null,
                    tooltip: 'Previous chapter',
                  ),

                  // Table of contents button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: hasChapters ? onTableOfContents : null,
                      icon: const Icon(
                        Icons.list,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        chapterText,
                        style: TextStyle(
                          color: Colors.white,
                          // Use textScaler for accessibility
                          fontSize: MediaQuery.textScalerOf(context).scale(14),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),

                  // Next chapter button
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: hasChapters && currentChapter < totalChapters - 1
                        ? onNextChapter
                        : null,
                    tooltip: 'Next chapter',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Progress slider
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withValues(alpha: 0.2),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 100.0),
                        min: 0,
                        max: 100,
                        onChanged: onProgressChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white,
                        // Use textScaler for accessibility
                        fontSize: MediaQuery.textScalerOf(context).scale(12),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
