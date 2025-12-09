import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/reader_provider.dart';
import '../../providers/settings_provider.dart';
import '../../themes/reading_themes.dart';
import '../../../plugins/epub/readwhere_epub_controller.dart';
import '../../../plugins/cbr/cbr_reader_controller.dart';
import '../../../plugins/cbz/cbz_reader_controller.dart';
import 'widgets/audio_controls.dart';
import 'widgets/reader_content.dart';
import 'widgets/reader_controls.dart';
import 'widgets/fixed_layout_reader.dart';
import 'widgets/table_of_contents_sheet.dart';
import 'widgets/reading_settings_sheet.dart';

/// Main reader screen for displaying book content
///
/// This screen provides a full-screen reading experience with:
/// - Tap to show/hide controls
/// - Swipe gestures for page navigation
/// - Reading content display
/// - Overlay controls for navigation and settings
class ReaderScreen extends StatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = false;
  bool _showAudioControls = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    // Open the book when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndOpenBook();
    });

    // Track scroll position for progress updates
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadAndOpenBook() async {
    final libraryProvider = context.read<LibraryProvider>();
    final readerProvider = context.read<ReaderProvider>();

    // Find the book in the library
    final book = libraryProvider.books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => throw Exception('Book not found: ${widget.bookId}'),
    );

    await readerProvider.openBook(book);

    // Initialize audio for the current chapter if available
    if (mounted) {
      await _initializeAudioForChapter();
    }
  }

  Future<void> _initializeAudioForChapter() async {
    final readerProvider = context.read<ReaderProvider>();
    final audioProvider = context.read<AudioProvider>();

    final controller = readerProvider.readerController;
    if (controller is ReadwhereEpubController && controller.hasMediaOverlays) {
      final hasAudio = await audioProvider.initializeForChapter(
        controller,
        readerProvider.currentChapterIndex,
      );
      if (hasAudio && mounted) {
        setState(() {
          _showAudioControls = true;
        });
      }
    }
  }

  void _toggleAudioControls() {
    setState(() {
      _showAudioControls = !_showAudioControls;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final scrollExtent = position.maxScrollExtent;

    if (scrollExtent > 0) {
      final newScrollPosition = position.pixels / scrollExtent;

      // Only update if position changed significantly (reduce updates)
      if ((newScrollPosition - _scrollPosition).abs() > 0.01) {
        _scrollPosition = newScrollPosition;

        // Update reading progress in provider
        final readerProvider = context.read<ReaderProvider>();
        final currentChapter = readerProvider.currentChapterIndex;

        // Simple CFI based on chapter and scroll position
        final cfi =
            'chapter-$currentChapter-${(_scrollPosition * 100).toInt()}';

        // Calculate overall progress (simplified)
        final totalChapters = readerProvider.tableOfContents.length;
        final overallProgress = totalChapters > 0
            ? (currentChapter / totalChapters) +
                  (_scrollPosition / totalChapters)
            : _scrollPosition;

        readerProvider.updateProgressWhileReading(
          cfi,
          overallProgress.clamp(0.0, 1.0),
        );
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TableOfContentsSheet(
        onChapterSelected: (index) {
          Navigator.pop(context);
          context.read<ReaderProvider>().goToChapter(index);
          // Reset scroll position when changing chapters
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        },
      ),
    );
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReadingSettingsSheet(),
    );
  }

  Future<void> _handleBookmark() async {
    final readerProvider = context.read<ReaderProvider>();
    final currentChapter = readerProvider.currentChapterIndex;
    final toc = readerProvider.tableOfContents;

    final chapterTitle = toc.isNotEmpty && currentChapter < toc.length
        ? toc[currentChapter].title
        : 'Chapter $currentChapter';

    await readerProvider.addBookmark('Bookmark at $chapterTitle');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookmark added'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Build the appropriate content widget based on whether
  /// the content is fixed-layout or reflowable.
  Widget _buildContentWidget(ReaderProvider readerProvider) {
    final controller = readerProvider.readerController;

    // Check if this is fixed-layout content (comics, fixed-layout EPUBs)
    // Uses InteractiveViewer for zoom/pan functionality
    if (controller != null && controller.isFixedLayout) {
      return const FixedLayoutReader();
    }

    // Default to reflowable reader for text-based content
    return ReaderContentWidget(scrollController: _scrollController);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, readerProvider, child) {
        // Show loading state
        if (readerProvider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Opening book...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (readerProvider.error != null && !readerProvider.hasOpenBook) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      readerProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Get reading theme from settings
        final readingTheme = ReadingThemes.fromSettings(
          readerProvider.settings,
        );

        // Main reader UI
        return ReadingThemeProvider(
          themeData: readingTheme,
          child: Scaffold(
            backgroundColor: readingTheme.backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  // Main content area with gesture detection
                  GestureDetector(
                    onTap: _toggleControls,
                    onHorizontalDragEnd: (details) {
                      // Swipe right to left (next chapter)
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < -500) {
                        readerProvider.nextChapter();
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      }
                      // Swipe left to right (previous chapter)
                      else if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 500) {
                        readerProvider.previousChapter();
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      }
                    },
                    child: _buildContentWidget(readerProvider),
                  ),

                  // Overlay controls (top and bottom bars)
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, _) {
                      final controller = readerProvider.readerController;
                      final isComic =
                          controller is CbrReaderController ||
                          controller is CbzReaderController;

                      return ReaderControls(
                        visible: _showControls,
                        bookTitle:
                            readerProvider.currentBook?.title ?? 'Unknown',
                        currentChapter: readerProvider.currentChapterIndex,
                        totalChapters: readerProvider.tableOfContents.length,
                        progress: readerProvider.progressPercentage,
                        isComic: isComic,
                        panelModeEnabled:
                            settingsProvider.comicPanelModeEnabled,
                        readingDirection:
                            settingsProvider.comicReadingDirection,
                        onTogglePanelMode: isComic
                            ? () => settingsProvider.toggleComicPanelMode()
                            : null,
                        onToggleReadingDirection: isComic
                            ? () =>
                                  settingsProvider.toggleComicReadingDirection()
                            : null,
                        onClose: () async {
                          final navigator = Navigator.of(context);
                          final audioProvider = context.read<AudioProvider>();
                          await audioProvider.reset();
                          await readerProvider.saveProgress();
                          await readerProvider.closeBook();
                          if (mounted) {
                            navigator.pop();
                          }
                        },
                        onBookmark: _handleBookmark,
                        onSettings: _showReadingSettings,
                        onTableOfContents: _showTableOfContents,
                        onAudio: _toggleAudioControls,
                        onProgressChanged: (value) {
                          // Update progress slider
                          final totalChapters =
                              readerProvider.tableOfContents.length;
                          if (totalChapters > 0) {
                            final targetChapter = (value / 100 * totalChapters)
                                .floor();
                            if (targetChapter !=
                                readerProvider.currentChapterIndex) {
                              readerProvider.goToChapter(
                                targetChapter.clamp(0, totalChapters - 1),
                              );
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            }
                          }
                        },
                        onPreviousChapter: () {
                          readerProvider.previousChapter();
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                        },
                        onNextChapter: () {
                          readerProvider.nextChapter();
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                        },
                      );
                    },
                  ),

                  // Audio controls (floating bottom bar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AudioControls(
                      visible: _showAudioControls,
                      onDismiss: () {
                        setState(() {
                          _showAudioControls = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
