import 'package:flutter/material.dart';

/// A button widget for downloading books with progress indication
class DownloadButton extends StatelessWidget {
  final bool isDownloading;
  final bool isDownloaded;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;

  const DownloadButton({
    super.key,
    required this.isDownloading,
    required this.isDownloaded,
    required this.progress,
    required this.onDownload,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isDownloaded) {
      return FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.menu_book, size: 18),
        label: const Text('Read'),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              minHeight: 36,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Download'),
    );
  }
}

/// Compact download icon button for grid view
class DownloadIconButton extends StatelessWidget {
  final bool isDownloading;
  final bool isDownloaded;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;

  const DownloadIconButton({
    super.key,
    required this.isDownloading,
    required this.isDownloaded,
    required this.progress,
    required this.onDownload,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isDownloaded) {
      return IconButton.filled(
        onPressed: onOpen,
        icon: const Icon(Icons.menu_book),
        tooltip: 'Open in reader',
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: progress, strokeWidth: 3),
            Text(
              '${(progress * 100).toInt()}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    return IconButton.outlined(
      onPressed: onDownload,
      icon: const Icon(Icons.download),
      tooltip: 'Download',
    );
  }
}
