import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

/// Dialog for browsing and selecting a folder on Nextcloud
///
/// Used during catalog setup to let users pick a starting folder
/// before the catalog is saved.
class NextcloudFolderPickerDialog extends StatefulWidget {
  /// Nextcloud server URL
  final String serverUrl;

  /// User ID for WebDAV path
  final String userId;

  /// Username for authentication
  final String username;

  /// App password for authentication
  final String appPassword;

  /// Initial path to start browsing from
  final String initialPath;

  const NextcloudFolderPickerDialog({
    super.key,
    required this.serverUrl,
    required this.userId,
    required this.username,
    required this.appPassword,
    this.initialPath = '/',
  });

  @override
  State<NextcloudFolderPickerDialog> createState() =>
      _NextcloudFolderPickerDialogState();
}

class _NextcloudFolderPickerDialogState
    extends State<NextcloudFolderPickerDialog> {
  late String _currentPath;
  late List<String> _pathStack;
  List<NextcloudFile> _folders = [];
  bool _isLoading = true;
  String? _error;

  NextcloudClient get _client => GetIt.I<NextcloudClient>();

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath.isEmpty ? '/' : widget.initialPath;
    _pathStack = _buildPathStack(_currentPath);
    _loadDirectory();
  }

  /// Build path stack from a path string
  List<String> _buildPathStack(String path) {
    if (path == '/' || path.isEmpty) return ['/'];

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final stack = <String>['/'];
    var currentPath = '';
    for (final segment in segments) {
      currentPath = '$currentPath/$segment';
      stack.add(currentPath);
    }
    return stack;
  }

  /// Load directory contents
  Future<void> _loadDirectory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _client.listDirectoryWithCredentials(
        serverUrl: widget.serverUrl,
        userId: widget.userId,
        username: widget.username,
        password: widget.appPassword,
        path: _currentPath,
      );

      if (!mounted) return;

      // Filter to only show directories
      final folders = files
          .where((f) => f.isDirectory && f.path != _currentPath)
          .toList();

      // Sort alphabetically
      folders.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Navigate to a subfolder
  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _pathStack.add(path);
    });
    _loadDirectory();
  }

  /// Navigate back to parent folder
  void _navigateBack() {
    if (_pathStack.length <= 1) return;

    setState(() {
      _pathStack.removeLast();
      _currentPath = _pathStack.last;
    });
    _loadDirectory();
  }

  /// Navigate to a specific breadcrumb
  void _navigateToBreadcrumb(int index) {
    if (index >= _pathStack.length - 1) return;

    setState(() {
      _pathStack = _pathStack.sublist(0, index + 1);
      _currentPath = _pathStack.last;
    });
    _loadDirectory();
  }

  /// Get display name for a path segment
  String _getDisplayName(String path) {
    if (path == '/') return 'Home';
    final segments = path.split('/');
    return segments.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Starting Folder'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Breadcrumbs
            _buildBreadcrumbs(theme),
            const Divider(height: 1),
            // Content
            Expanded(child: _buildContent(theme)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentPath),
          child: const Text('Select This Folder'),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(ThemeData theme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pathStack.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: theme.colorScheme.outline,
          ),
        ),
        itemBuilder: (context, index) {
          final isLast = index == _pathStack.length - 1;
          final path = _pathStack[index];
          final displayName = _getDisplayName(path);

          return Center(
            child: InkWell(
              onTap: isLast ? null : () => _navigateToBreadcrumb(index),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0)
                      Icon(
                        Icons.folder,
                        size: 16,
                        color: isLast
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.primary,
                      ),
                    if (index == 0) const SizedBox(width: 4),
                    Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLast
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.primary,
                        fontWeight: isLast
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_folders.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return ListTile(
          leading: Icon(Icons.folder, color: theme.colorScheme.primary),
          title: Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateTo(folder.path),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No subfolders',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This folder has no subdirectories',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load folder',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_pathStack.length > 1)
                  OutlinedButton.icon(
                    onPressed: _navigateBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                if (_pathStack.length > 1) const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loadDirectory,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
