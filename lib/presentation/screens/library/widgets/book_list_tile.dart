import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/book.dart';
import '../../../providers/library_provider.dart';

/// A list tile widget displaying a book in list view.
///
/// Shows the book cover thumbnail, title, author, reading progress,
/// and favorite status. Supports tap to open reader and long-press
/// for context menu actions.
class BookListTile extends StatelessWidget {
  /// The book to display
  final Book book;

  /// Callback when the tile is tapped to open the book
  final VoidCallback onTap;

  const BookListTile({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Cover Thumbnail
              _buildCoverThumbnail(colorScheme),
              const SizedBox(width: 16),
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.60),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    if (book.readingProgress != null)
                      _buildProgressBar(colorScheme),
                    // Format and Last Opened
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.format.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (book.lastOpenedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Last read: ${_formatDate(book.lastOpenedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.50,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing Icons
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (book.isFavorite)
                    Icon(Icons.favorite, size: 20, color: colorScheme.error),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showContextMenu(context),
                    tooltip: 'More options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the book cover thumbnail
  Widget _buildCoverThumbnail(ColorScheme colorScheme) {
    const double width = 60;
    const double height = 90;

    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      final coverFile = File(book.coverPath!);
      if (coverFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            coverFile,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderThumbnail(colorScheme, width, height);
            },
          ),
        );
      }
    }

    return _buildPlaceholderThumbnail(colorScheme, width, height);
  }

  /// Builds a placeholder thumbnail with the book title
  Widget _buildPlaceholderThumbnail(
    ColorScheme colorScheme,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          book.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Builds the reading progress indicator
  Widget _buildProgressBar(ColorScheme colorScheme) {
    final progress = book.readingProgress ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shows a context menu for book actions
  void _showContextMenu(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    // Capture the parent context's messenger before showing the bottom sheet
    // The bottom sheet's context becomes invalid after it's popped
    final parentMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(sheetContext);
                onTap();
              },
            ),
            ListTile(
              leading: Icon(
                book.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                book.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                libraryProvider.toggleFavorite(book.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Book Details'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBookDetails(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteWithMessenger(libraryProvider, parentMessenger);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Shows detailed information about the book
  void _showBookDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Author', book.author),
              _buildDetailRow('Format', book.format.toUpperCase()),
              _buildDetailRow(
                'File Size',
                '${(book.fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
              ),
              _buildDetailRow('Added', _formatDate(book.addedAt)),
              if (book.lastOpenedAt != null)
                _buildDetailRow('Last Opened', _formatDate(book.lastOpenedAt!)),
              if (book.readingProgress != null)
                _buildDetailRow(
                  'Progress',
                  '${(book.readingProgress! * 100).toStringAsFixed(0)}%',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Builds a detail row for the book details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Shows a confirmation dialog before deleting the book
  /// Uses the provided messenger to show the SnackBar on the correct scaffold
  void _confirmDeleteWithMessenger(
    LibraryProvider libraryProvider,
    ScaffoldMessengerState messenger,
  ) {
    final bookTitle = book.title;

    showDialog(
      context: messenger.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "$bookTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              libraryProvider.deleteBook(book.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Deleted "$bookTitle"'),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // TODO: Implement undo functionality
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
