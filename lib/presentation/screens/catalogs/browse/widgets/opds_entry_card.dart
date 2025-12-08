import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/entities/opds_entry.dart';
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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    final theme = Theme.of(context);

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

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

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

    return Row(
      children: [
        if (format != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              format.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
        ],
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

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        height: 64,
        child: _buildThumbnail(context, isNavigation),
      ),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: entry.author != null
          ? Text(
              entry.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.outline),
            )
          : null,
      trailing: isNavigation
          ? const Icon(Icons.chevron_right)
          : DownloadIconButton(
              isDownloading: isDownloading,
              isDownloaded: isDownloaded,
              progress: downloadProgress,
              onDownload: onDownload,
              onOpen: onOpen,
            ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isNavigation) {
    final theme = Theme.of(context);

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

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: coverUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholderThumb(context),
          errorWidget: (context, url, error) => _buildPlaceholderThumb(context),
        ),
      );
    }

    return _buildPlaceholderThumb(context);
  }

  Widget _buildPlaceholderThumb(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, color: theme.colorScheme.outline),
    );
  }
}
