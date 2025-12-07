import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/reader_provider.dart';
import '../../themes/reading_themes.dart';
import 'widgets/reader_content.dart';
import 'widgets/reader_controls.dart';
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

  const ReaderScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = false;
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
        final cfi = 'chapter-$currentChapter-${(_scrollPosition * 100).toInt()}';

        // Calculate overall progress (simplified)
        final totalChapters = readerProvider.tableOfContents.length;
        final overallProgress = totalChapters > 0
            ? (currentChapter / totalChapters) + (_scrollPosition / totalChapters)
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
            appBar: AppBar(
              title: const Text('Error'),
            ),
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
        final readingTheme = ReadingThemes.fromSettings(readerProvider.settings);

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
                    child: ReaderContentWidget(
                      scrollController: _scrollController,
                    ),
                  ),

                  // Overlay controls (top and bottom bars)
                  ReaderControls(
                    visible: _showControls,
                    bookTitle: readerProvider.currentBook?.title ?? 'Unknown',
                    currentChapter: readerProvider.currentChapterIndex,
                    totalChapters: readerProvider.tableOfContents.length,
                    progress: readerProvider.progressPercentage,
                    onClose: () async {
                      await readerProvider.saveProgress();
                      await readerProvider.closeBook();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    onBookmark: _handleBookmark,
                    onSettings: _showReadingSettings,
                    onTableOfContents: _showTableOfContents,
                    onProgressChanged: (value) {
                      // Update progress slider
                      final totalChapters = readerProvider.tableOfContents.length;
                      if (totalChapters > 0) {
                        final targetChapter = (value / 100 * totalChapters).floor();
                        if (targetChapter != readerProvider.currentChapterIndex) {
                          readerProvider.goToChapter(targetChapter.clamp(0, totalChapters - 1));
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
