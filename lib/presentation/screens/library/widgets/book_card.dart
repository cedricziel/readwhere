import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/book.dart';
import '../../../providers/library_provider.dart';
import 'encryption_badge.dart';

/// A card widget displaying a book in grid view.
///
/// Shows the book cover, title, author, reading progress, and favorite status.
/// Supports tap to open reader and long-press for context menu actions.
class BookCard extends StatelessWidget {
  /// The book to display
  final Book book;

  /// Callback when the card is tapped to open the book
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover
            Expanded(flex: 3, child: _buildCover(colorScheme)),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.60),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Progress and Favorite
                    Row(
                      children: [
                        if (book.readingProgress != null) ...[
                          Expanded(child: _buildProgressBar(colorScheme)),
                          const SizedBox(width: 8),
                        ],
                        if (book.isFavorite)
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the book cover widget with optional encryption badge
  Widget _buildCover(ColorScheme colorScheme) {
    debugPrint('BookCard - Building cover for "${book.title}"');
    debugPrint('BookCard - coverPath: ${book.coverPath}');

    Widget coverImage;

    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      final coverFile = File(book.coverPath!);
      final exists = coverFile.existsSync();
      debugPrint('BookCard - File exists: $exists');

      if (exists) {
        debugPrint('BookCard - Loading cover image from file');
        coverImage = Image.file(
          coverFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('BookCard - Image.file error: $error');
            return _buildPlaceholderCover(colorScheme);
          },
        );
      } else {
        debugPrint('BookCard - Cover file does not exist at path');
        coverImage = _buildPlaceholderCover(colorScheme);
      }
    } else {
      debugPrint('BookCard - No coverPath set');
      coverImage = _buildPlaceholderCover(colorScheme);
    }

    // Wrap with encryption badge if DRM is present
    if (book.hasDrm) {
      return Stack(
        fit: StackFit.expand,
        children: [
          coverImage,
          Positioned(
            top: 8,
            right: 8,
            child: EncryptionBadge(encryptionType: book.encryptionType),
          ),
        ],
      );
    }

    return coverImage;
  }

  /// Builds a placeholder cover with the book title
  Widget _buildPlaceholderCover(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          book.title,
          style: TextStyle(
            fontSize: 16,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
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
    // Also capture the parent context for showing dialogs
    final parentContext = context;

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
                _showBookDetails(parentContext);
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
                _confirmDeleteWithMessenger(
                  parentContext,
                  libraryProvider,
                  parentMessenger,
                );
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
              // EPUB-specific details
              if (book.format.toLowerCase() == 'epub') ...[
                const Divider(height: 16),
                _buildDetailRow(
                  'Protection',
                  EncryptionBadge.getDescription(book.encryptionType),
                ),
                if (book.isFixedLayout)
                  _buildDetailRow('Layout', 'Fixed-layout (pre-paginated)'),
                if (book.hasMediaOverlays)
                  _buildDetailRow('Audio', 'Has read-aloud narration'),
              ],
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
    BuildContext context,
    LibraryProvider libraryProvider,
    ScaffoldMessengerState messenger,
  ) {
    final bookTitle = book.title;

    showDialog(
      context: context,
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
