import 'package:flutter/material.dart';

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
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

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
    required this.onProgressChanged,
    required this.onPreviousChapter,
    required this.onNextChapter,
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

  const _TopBar({
    required this.bookTitle,
    required this.onClose,
    required this.onBookmark,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action buttons
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
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
