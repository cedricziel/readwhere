import 'package:flutter/material.dart';

import '../api/models/synology_file.dart';

/// A list tile widget for displaying a Synology file or directory.
class SynologyFileTile extends StatelessWidget {
  /// Creates a new [SynologyFileTile].
  const SynologyFileTile({
    super.key,
    required this.file,
    required this.onTap,
    this.downloadProgress,
    this.folderColor,
    this.epubColor,
    this.pdfColor,
    this.comicColor,
    this.fileColor,
  });

  /// The file to display.
  final SynologyFile file;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Download progress (0.0 to 1.0), or null if not downloading.
  final double? downloadProgress;

  /// Color for folder icons.
  final Color? folderColor;

  /// Color for EPUB file icons.
  final Color? epubColor;

  /// Color for PDF file icons.
  final Color? pdfColor;

  /// Color for comic file icons.
  final Color? comicColor;

  /// Color for other file icons.
  final Color? fileColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: _buildLeadingWidget(colorScheme),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(colorScheme),
      onTap: onTap,
    );
  }

  Widget _buildLeadingWidget(ColorScheme colorScheme) {
    if (downloadProgress != null && downloadProgress! < 1.0) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 3,
            ),
            Text(
              '${(downloadProgress! * 100).toInt()}%',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }

    if (downloadProgress == 1.0) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.green,
        ),
      );
    }

    return Icon(
      _getIcon(),
      size: 40,
      color: _getIconColor(colorScheme),
    );
  }

  IconData _getIcon() {
    if (file.isDirectory) return Icons.folder;
    if (file.isEpub) return Icons.menu_book;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isComic) return Icons.collections_bookmark;
    return Icons.insert_drive_file;
  }

  Color _getIconColor(ColorScheme colorScheme) {
    if (file.isDirectory) return folderColor ?? colorScheme.primary;
    if (file.isEpub) return epubColor ?? Colors.orange;
    if (file.isPdf) return pdfColor ?? Colors.red;
    if (file.isComic) return comicColor ?? Colors.purple;
    return fileColor ?? colorScheme.onSurfaceVariant;
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];

    if (!file.isDirectory && file.formattedSize.isNotEmpty) {
      parts.add(file.formattedSize);
    }

    if (file.modifiedTime != null) {
      parts.add(_formatDate(file.modifiedTime!));
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailing(ColorScheme colorScheme) {
    final widgets = <Widget>[];

    if (file.isStarred) {
      widgets.add(Icon(
        Icons.star,
        size: 16,
        color: Colors.amber,
      ));
    }

    if (file.isShared) {
      widgets.add(Icon(
        Icons.people,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ));
    }

    if (file.isEncrypted) {
      widgets.add(Icon(
        Icons.lock,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ));
    }

    if (file.isDirectory) {
      widgets.add(Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ));
    }

    if (widgets.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
