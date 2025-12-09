import 'package:flutter/material.dart';

import '../webdav/nextcloud_file.dart';

/// List tile for displaying a Nextcloud file or directory
///
/// This is a reusable widget that can be used to display files
/// in a list with appropriate icons and metadata.
class NextcloudFileTile extends StatelessWidget {
  /// The file to display
  final NextcloudFile file;

  /// Called when the tile is tapped
  final VoidCallback onTap;

  /// Download progress (0.0 to 1.0) if the file is being downloaded
  final double? downloadProgress;

  /// Icon for EPUB files (defaults to menu_book)
  final IconData epubIcon;

  /// Color for EPUB files (defaults to orange)
  final Color? epubColor;

  /// Icon for PDF files (defaults to picture_as_pdf)
  final IconData pdfIcon;

  /// Color for PDF files (defaults to red)
  final Color? pdfColor;

  /// Icon for comic files (defaults to collections_bookmark)
  final IconData comicIcon;

  /// Color for comic files (defaults to purple)
  final Color? comicColor;

  const NextcloudFileTile({
    super.key,
    required this.file,
    required this.onTap,
    this.downloadProgress,
    this.epubIcon = Icons.menu_book,
    this.epubColor,
    this.pdfIcon = Icons.picture_as_pdf,
    this.pdfColor,
    this.comicIcon = Icons.collections_bookmark,
    this.comicColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloading = downloadProgress != null && downloadProgress! < 1.0;

    return ListTile(
      leading: _buildIcon(theme),
      title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(theme),
      trailing: _buildTrailing(theme, isDownloading),
      onTap: isDownloading ? null : onTap,
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (file.isDirectory) {
      return Icon(Icons.folder, size: 40, color: theme.colorScheme.primary);
    }

    IconData icon;
    Color color;

    if (file.isEpub) {
      icon = epubIcon;
      color = epubColor ?? Colors.orange;
    } else if (file.isPdf) {
      icon = pdfIcon;
      color = pdfColor ?? Colors.red;
    } else if (file.isComic) {
      icon = comicIcon;
      color = comicColor ?? Colors.purple;
    } else {
      icon = Icons.insert_drive_file;
      color = theme.colorScheme.outline;
    }

    return Icon(icon, size: 40, color: color);
  }

  Widget? _buildSubtitle(ThemeData theme) {
    if (file.isDirectory) {
      return null;
    }

    final parts = <String>[];

    if (file.size != null) {
      parts.add(formatFileSize(file.size!));
    }

    if (file.lastModified != null) {
      parts.add(formatDate(file.lastModified!));
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' | '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );
  }

  Widget? _buildTrailing(ThemeData theme, bool isDownloading) {
    if (isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: downloadProgress, strokeWidth: 3),
            Text(
              '${(downloadProgress! * 100).toInt()}%',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    if (downloadProgress == 1.0) {
      return Icon(Icons.check_circle, color: theme.colorScheme.primary);
    }

    if (file.isDirectory) {
      return const Icon(Icons.chevron_right);
    }

    if (file.isSupportedBook) {
      return Icon(Icons.download, color: theme.colorScheme.primary);
    }

    return null;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
