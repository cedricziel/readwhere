import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:readwhere_opds/readwhere_opds.dart';

import 'download_button.dart';

/// Card widget for displaying an OPDS entry (book or navigation item)
class OpdsEntryCard extends StatelessWidget {
  final OpdsEntry entry;
  final String? coverUrl;
  final bool isDownloading;
  final bool isDownloaded;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;

  const OpdsEntryCard({
    super.key,
    required this.entry,
    this.coverUrl,
    required this.isDownloading,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onTap,
    required this.onDownload,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNavigation = entry.isNavigation;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image or placeholder
            Expanded(flex: 3, child: _buildCover(context, isNavigation)),
            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and author
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              entry.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.author != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.author!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action row
                    if (!isNavigation) _buildActionRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, bool isNavigation) {
    // Always try to show cover image first if available
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(context, isNavigation),
        errorWidget: (context, url, error) =>
            _buildPlaceholder(context, isNavigation),
      );
    }

    // Fall back to placeholder (folder icon for navigation, book icon for books)
    return _buildPlaceholder(context, isNavigation);
  }

  Widget _buildPlaceholder(BuildContext context, bool isNavigation) {
    final theme = Theme.of(context);

    // Navigation entries get folder icon, books get book icon
    if (isNavigation) {
      return Container(
        color: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.folder,
          size: 48,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              entry.title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final theme = Theme.of(context);
    final format = entry.preferredFormat;
    final isUnsupported = entry.hasOnlyUnsupportedFormats;

    return Row(
      children: [
        if (format != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUnsupported
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              format.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUnsupported
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
        ],
        if (isUnsupported)
          Tooltip(
            message: 'Format not supported',
            child: Icon(Icons.block, size: 20, color: theme.colorScheme.error),
          )
        else
          DownloadIconButton(
            isDownloading: isDownloading,
            isDownloaded: isDownloaded,
            progress: downloadProgress,
            onDownload: onDownload,
            onOpen: onOpen,
          ),
      ],
    );
  }
}

/// List tile version of OPDS entry for list view
class OpdsEntryListTile extends StatelessWidget {
  final OpdsEntry entry;
  final String? coverUrl;
  final bool isDownloading;
  final bool isDownloaded;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;

  const OpdsEntryListTile({
    super.key,
    required this.entry,
    this.coverUrl,
    required this.isDownloading,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onTap,
    required this.onDownload,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNavigation = entry.isNavigation;
    final isUnsupported = entry.hasOnlyUnsupportedFormats;

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        height: 64,
        child: _buildThumbnail(context, isNavigation),
      ),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(context, isUnsupported),
      trailing: isNavigation
          ? const Icon(Icons.chevron_right)
          : isUnsupported
          ? Tooltip(
              message: 'Format not supported',
              child: Icon(Icons.block, color: theme.colorScheme.error),
            )
          : DownloadIconButton(
              isDownloading: isDownloading,
              isDownloaded: isDownloaded,
              progress: downloadProgress,
              onDownload: onDownload,
              onOpen: onOpen,
            ),
    );
  }

  Widget? _buildSubtitle(BuildContext context, bool isUnsupported) {
    final theme = Theme.of(context);
    final format = entry.preferredFormat;

    if (isUnsupported && format != null) {
      return Row(
        children: [
          if (entry.author != null) ...[
            Flexible(
              child: Text(
                entry.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              format.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 10,
              ),
            ),
          ),
        ],
      );
    }

    if (entry.author != null) {
      return Text(
        entry.author!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.colorScheme.outline),
      );
    }

    return null;
  }

  Widget _buildThumbnail(BuildContext context, bool isNavigation) {
    // Always try to show cover image first if available
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: coverUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              _buildPlaceholderThumb(context, isNavigation),
          errorWidget: (context, url, error) =>
              _buildPlaceholderThumb(context, isNavigation),
        ),
      );
    }

    // Fall back to placeholder (folder icon for navigation, book icon for books)
    return _buildPlaceholderThumb(context, isNavigation);
  }

  Widget _buildPlaceholderThumb(BuildContext context, bool isNavigation) {
    final theme = Theme.of(context);

    // Navigation entries get folder icon, books get book icon
    if (isNavigation) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.folder,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, color: theme.colorScheme.outline),
    );
  }
}
