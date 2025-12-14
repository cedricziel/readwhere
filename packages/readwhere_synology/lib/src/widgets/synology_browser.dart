import 'package:flutter/material.dart';

import '../api/models/synology_file.dart';
import 'synology_file_tile.dart';

/// A widget for browsing Synology Drive files.
class SynologyBrowser extends StatelessWidget {
  /// Creates a new [SynologyBrowser].
  const SynologyBrowser({
    super.key,
    required this.files,
    required this.currentPath,
    required this.isLoading,
    required this.onFileTap,
    required this.onDirectoryTap,
    this.error,
    this.breadcrumbs,
    this.onBreadcrumbTap,
    this.onRefresh,
    this.getDownloadProgress,
    this.rootFolderName = 'My Drive',
    this.emptyMessage = 'This folder is empty',
    this.errorRetryLabel = 'Retry',
    this.onErrorRetry,
  });

  /// The list of files and directories.
  final List<SynologyFile> files;

  /// The current path.
  final String currentPath;

  /// Whether the browser is loading.
  final bool isLoading;

  /// Error message, if any.
  final String? error;

  /// Breadcrumb path segments.
  final List<String>? breadcrumbs;

  /// Called when a file is tapped.
  final void Function(SynologyFile file) onFileTap;

  /// Called when a directory is tapped.
  final void Function(SynologyFile directory) onDirectoryTap;

  /// Called when a breadcrumb is tapped (index in breadcrumbs list).
  final void Function(int index)? onBreadcrumbTap;

  /// Called when the user pulls to refresh.
  final Future<void> Function()? onRefresh;

  /// Returns the download progress for a file path.
  final double? Function(String path)? getDownloadProgress;

  /// Name to display for the root folder.
  final String rootFolderName;

  /// Message to show when the folder is empty.
  final String emptyMessage;

  /// Label for the error retry button.
  final String errorRetryLabel;

  /// Called when the user taps retry on an error.
  final VoidCallback? onErrorRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (breadcrumbs != null && breadcrumbs!.isNotEmpty)
          _buildBreadcrumbs(context),
        Expanded(
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs!.length,
        separatorBuilder: (_, __) => const Icon(
          Icons.chevron_right,
          size: 20,
        ),
        itemBuilder: (context, index) {
          final isLast = index == breadcrumbs!.length - 1;

          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: isLast ? null : () => onBreadcrumbTap?.call(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  breadcrumbs![index],
                  style: TextStyle(
                    color: isLast
                        ? theme.textTheme.bodyLarge?.color
                        : theme.colorScheme.primary,
                    fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && files.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return _buildErrorState(context);
    }

    if (files.isEmpty) {
      return _buildEmptyState(context);
    }

    final list = ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return SynologyFileTile(
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
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }

    return list;
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
            if (onErrorRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onErrorRetry,
                icon: const Icon(Icons.refresh),
                label: Text(errorRetryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
