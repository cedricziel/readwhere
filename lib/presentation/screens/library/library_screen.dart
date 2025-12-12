import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/library_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../router/routes.dart';
import 'widgets/book_card.dart';
import 'widgets/book_list_tile.dart';

/// The main library screen displaying the user's book collection.
///
/// This is the default landing screen of the application where users
/// can browse, search, and manage their e-book library.
///
/// Features:
/// - Grid and list view modes
/// - Search functionality
/// - Sort options (recently added, recently opened, title, author)
/// - Pull to refresh
/// - Import books via file picker
/// - Book management (favorite, delete)
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    // Load library when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      libraryProvider.loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          // Loading state
          if (libraryProvider.isLoading && libraryProvider.books.isEmpty) {
            return const LoadingIndicator(message: 'Loading your library...');
          }

          // Error state
          if (libraryProvider.error != null) {
            return _buildErrorState(libraryProvider);
          }

          // Empty state
          if (libraryProvider.books.isEmpty) {
            return _buildEmptyState();
          }

          // Books display
          return _buildBooksView(libraryProvider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook,
        tooltip: 'Add Book',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds the app bar with title, search, view toggle, and sort menu
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: _isSearching
          ? null
          : const Padding(
              padding: EdgeInsets.all(8.0),
              child: AppLogo(size: 40),
            ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search books...',
                border: InputBorder.none,
              ),
              onChanged: (query) {
                final libraryProvider = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                libraryProvider.search(query);
              },
            )
          : const Text('Library'),
      actions: [
        // Search icon
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          tooltip: _isSearching ? 'Close search' : 'Search',
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                final libraryProvider = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                libraryProvider.clearSearch();
              }
            });
          },
        ),
        // View mode toggle
        Consumer<LibraryProvider>(
          builder: (context, libraryProvider, child) {
            return IconButton(
              icon: Icon(
                libraryProvider.viewMode == LibraryViewMode.grid
                    ? Icons.view_list
                    : Icons.grid_view,
              ),
              tooltip: libraryProvider.viewMode == LibraryViewMode.grid
                  ? 'List view'
                  : 'Grid view',
              onPressed: () {
                libraryProvider.setViewMode(
                  libraryProvider.viewMode == LibraryViewMode.grid
                      ? LibraryViewMode.list
                      : LibraryViewMode.grid,
                );
              },
            );
          },
        ),
        // Sort menu
        Consumer<LibraryProvider>(
          builder: (context, libraryProvider, child) {
            return PopupMenuButton<LibrarySortOrder>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort',
              onSelected: (order) {
                libraryProvider.setSortOrder(order);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: LibrarySortOrder.recentlyAdded,
                  child: Row(
                    children: [
                      if (libraryProvider.sortOrder ==
                          LibrarySortOrder.recentlyAdded)
                        const Icon(Icons.check, size: 20),
                      if (libraryProvider.sortOrder !=
                          LibrarySortOrder.recentlyAdded)
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      const Text('Recently Added'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LibrarySortOrder.recentlyOpened,
                  child: Row(
                    children: [
                      if (libraryProvider.sortOrder ==
                          LibrarySortOrder.recentlyOpened)
                        const Icon(Icons.check, size: 20),
                      if (libraryProvider.sortOrder !=
                          LibrarySortOrder.recentlyOpened)
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      const Text('Recently Opened'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LibrarySortOrder.title,
                  child: Row(
                    children: [
                      if (libraryProvider.sortOrder == LibrarySortOrder.title)
                        const Icon(Icons.check, size: 20),
                      if (libraryProvider.sortOrder != LibrarySortOrder.title)
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      const Text('Title'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LibrarySortOrder.author,
                  child: Row(
                    children: [
                      if (libraryProvider.sortOrder == LibrarySortOrder.author)
                        const Icon(Icons.check, size: 20),
                      if (libraryProvider.sortOrder != LibrarySortOrder.author)
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      const Text('Author'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        // More options menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) {
            if (value == 'refresh_all_metadata') {
              _refreshAllMetadata();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh_all_metadata',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh All Metadata'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the books view based on the current view mode
  Widget _buildBooksView(LibraryProvider libraryProvider) {
    return RefreshIndicator(
      onRefresh: () => libraryProvider.loadLibrary(),
      child: libraryProvider.viewMode == LibraryViewMode.grid
          ? _buildGridView(libraryProvider)
          : _buildListView(libraryProvider),
    );
  }

  /// Builds the grid view of books
  Widget _buildGridView(LibraryProvider libraryProvider) {
    final books = libraryProvider.books;

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(context),
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(book: book, onTap: () => _openBook(book.id));
      },
    );
  }

  /// Builds the list view of books
  Widget _buildListView(LibraryProvider libraryProvider) {
    final books = libraryProvider.books;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookListTile(book: book, onTap: () => _openBook(book.id));
      },
    );
  }

  /// Builds the empty state when no books are in the library
  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.library_books,
      title: 'Your library is empty',
      subtitle: 'Add books to start reading',
      actionLabel: 'Add Book',
      onAction: _importBook,
    );
  }

  /// Builds the error state when loading fails
  Widget _buildErrorState(LibraryProvider libraryProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Error Loading Library',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              libraryProvider.error ?? 'An unknown error occurred',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => libraryProvider.loadLibrary(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates the number of columns for grid view based on screen width
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return 6; // Extra large screens
    } else if (width >= 900) {
      return 5; // Large screens
    } else if (width >= 600) {
      return 4; // Tablets
    } else if (width >= 400) {
      return 3; // Large phones
    } else {
      return 2; // Small phones
    }
  }

  /// Opens the book in the reader
  void _openBook(String bookId) {
    context.push(AppRoutes.readerPath(bookId));
  }

  /// Shows the file picker to import a book
  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'mobi', 'azw3', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;

        if (filePath == null) {
          if (mounted) {
            _showErrorSnackBar('Failed to get file path');
          }
          return;
        }

        if (mounted) {
          final libraryProvider = Provider.of<LibraryProvider>(
            context,
            listen: false,
          );

          final book = await libraryProvider.importBook(filePath);

          if (mounted) {
            if (book != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${book.title}" to library'),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: () => _openBook(book.id),
                  ),
                ),
              );
            } else {
              _showErrorSnackBar(
                libraryProvider.error ?? 'Failed to import book',
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error importing book: ${e.toString()}');
      }
    }
  }

  /// Shows an error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Refreshes metadata for all books in the library
  Future<void> _refreshAllMetadata() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    if (libraryProvider.bookCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No books to refresh')));
      return;
    }

    // Show progress dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RefreshMetadataProgressDialog(
        libraryProvider: libraryProvider,
        onComplete: (refreshedCount, totalCount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Refreshed metadata for $refreshedCount of $totalCount books',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Dialog showing progress of metadata refresh operation
class _RefreshMetadataProgressDialog extends StatefulWidget {
  final LibraryProvider libraryProvider;
  final void Function(int refreshedCount, int totalCount) onComplete;

  const _RefreshMetadataProgressDialog({
    required this.libraryProvider,
    required this.onComplete,
  });

  @override
  State<_RefreshMetadataProgressDialog> createState() =>
      _RefreshMetadataProgressDialogState();
}

class _RefreshMetadataProgressDialogState
    extends State<_RefreshMetadataProgressDialog> {
  int _current = 0;
  int _total = 0;
  String _currentBook = '';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _total = widget.libraryProvider.bookCount;
    _startRefresh();
  }

  Future<void> _startRefresh() async {
    final refreshedCount = await widget.libraryProvider.refreshAllMetadata(
      onProgress: (current, total, bookTitle) {
        if (mounted) {
          setState(() {
            _current = current;
            _total = total;
            _currentBook = bookTitle;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isComplete = true;
      });
      // Small delay to show completion before closing
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete(refreshedCount, _total);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _current / _total : 0.0;

    return AlertDialog(
      title: Text(_isComplete ? 'Refresh Complete' : 'Refreshing Metadata'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 16),
          Text(
            '$_current of $_total books',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_currentBook.isNotEmpty && !_isComplete) ...[
            const SizedBox(height: 8),
            Text(
              _currentBook,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
