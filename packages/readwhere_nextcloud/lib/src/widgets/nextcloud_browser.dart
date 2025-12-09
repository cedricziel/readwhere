import 'package:flutter/material.dart';

import '../webdav/nextcloud_file.dart';
import 'nextcloud_file_tile.dart';

/// A reusable widget for browsing Nextcloud files
///
/// This widget provides a complete file browser experience including:
/// - Breadcrumb navigation
/// - File listing with appropriate icons
/// - Pull-to-refresh support
/// - Download progress display
/// - Error and empty states
class NextcloudBrowser extends StatelessWidget {
  /// Current list of files to display
  final List<NextcloudFile> files;

  /// Current path (for breadcrumbs)
  final String currentPath;

  /// Whether files are being loaded
  final bool isLoading;

  /// Error message if loading failed
  final String? error;

  /// Called when a file is tapped
  final void Function(NextcloudFile file) onFileTap;

  /// Called when a directory is tapped
  final void Function(NextcloudFile directory) onDirectoryTap;

  /// Called when a breadcrumb is tapped
  final void Function(String path) onBreadcrumbTap;

  /// Called when refresh is requested
  final Future<void> Function() onRefresh;

  /// Get download progress for a file path (0.0 to 1.0)
  final double? Function(String path)? getDownloadProgress;

  /// Root folder name (defaults to "Home")
  final String rootFolderName;

  const NextcloudBrowser({
    super.key,
    required this.files,
    required this.currentPath,
    required this.isLoading,
    required this.onFileTap,
    required this.onDirectoryTap,
    required this.onBreadcrumbTap,
    required this.onRefresh,
    this.error,
    this.getDownloadProgress,
    this.rootFolderName = 'Home',
  });

  List<String> get _breadcrumbs {
    if (currentPath == '/' || currentPath.isEmpty) {
      return [rootFolderName];
    }

    final parts = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    return [rootFolderName, ...parts];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBreadcrumbs(context),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final theme = Theme.of(context);
    final breadcrumbs = _breadcrumbs;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) =>
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        itemBuilder: (context, index) {
          final isLast = index == breadcrumbs.length - 1;
          return TextButton(
            onPressed: isLast
                ? null
                : () {
                    if (index == 0) {
                      onBreadcrumbTap('/');
                    } else {
                      final pathParts =
                          breadcrumbs.sublist(1, index + 1).join('/');
                      onBreadcrumbTap('/$pathParts');
                    }
                  },
            child: Text(
              breadcrumbs[index],
              style: TextStyle(
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorState(context, error!);
    }

    if (files.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return NextcloudFileTile(
            file: file,
            onTap: () {
              if (file.isDirectory) {
                onDirectoryTap(file);
              } else {
                onFileTap(file);
              }
            },
            downloadProgress: getDownloadProgress?.call(file.path),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for download options
class NextcloudDownloadSheet extends StatelessWidget {
  /// The file to download
  final NextcloudFile file;

  /// Called when the download button is pressed
  final VoidCallback onDownload;

  /// Called when cancel is pressed
  final VoidCallback? onCancel;

  /// Download button text (defaults to "Download to Library")
  final String downloadButtonText;

  const NextcloudDownloadSheet({
    super.key,
    required this.file,
    required this.onDownload,
    this.onCancel,
    this.downloadButtonText = 'Download to Library',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              file.name,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (file.size != null) ...[
              const SizedBox(height: 8),
              Text(
                NextcloudFileTile.formatFileSize(file.size!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                label: Text(downloadButtonText),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
