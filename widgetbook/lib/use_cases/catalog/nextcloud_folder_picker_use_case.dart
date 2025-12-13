import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Preview widget for folder picker content states
/// Since the actual dialog requires network access, we preview the internal states
class _FolderPickerPreview extends StatelessWidget {
  final Widget content;
  final List<String> breadcrumbs;
  final VoidCallback? onBreadcrumbTap;

  const _FolderPickerPreview({
    required this.content,
    required this.breadcrumbs,
    this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SizedBox(
        width: 400,
        height: 450,
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Select Starting Folder',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () {}),
                ],
              ),
            ),
            // Breadcrumbs
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: breadcrumbs.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ),
                itemBuilder: (context, index) {
                  final isLast = index == breadcrumbs.length - 1;
                  return Center(
                    child: InkWell(
                      onTap: isLast ? null : onBreadcrumbTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index == 0) ...[
                              Icon(
                                Icons.folder,
                                size: 16,
                                color: isLast
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              breadcrumbs[index],
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
            ),
            const Divider(height: 1),
            // Content
            Expanded(child: content),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () {}, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Select This Folder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@widgetbook.UseCase(
  name: 'Loading',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildLoading(BuildContext context) {
  return _FolderPickerPreview(
    breadcrumbs: const ['Home'],
    content: const Center(child: CircularProgressIndicator()),
  );
}

@widgetbook.UseCase(
  name: 'With Folders',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildWithFolders(BuildContext context) {
  final theme = Theme.of(context);
  final folders = ['Books', 'Comics', 'Documents', 'eBooks', 'Magazines'];

  return _FolderPickerPreview(
    breadcrumbs: const ['Home', 'Documents'],
    content: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.folder, color: theme.colorScheme.primary),
          title: Text(folders[index]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => debugPrint('Tapped ${folders[index]}'),
        );
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'Deep Path',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildDeepPath(BuildContext context) {
  final theme = Theme.of(context);
  final folders = ['Fantasy', 'Mystery', 'Romance', 'Sci-Fi'];

  return _FolderPickerPreview(
    breadcrumbs: const ['Home', 'Documents', 'Books', 'Fiction'],
    content: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.folder, color: theme.colorScheme.primary),
          title: Text(folders[index]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => debugPrint('Tapped ${folders[index]}'),
        );
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'Empty (No Subfolders)',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildEmpty(BuildContext context) {
  final theme = Theme.of(context);

  return _FolderPickerPreview(
    breadcrumbs: const ['Home', 'Books', 'Empty Folder'],
    content: Center(
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
    ),
  );
}

@widgetbook.UseCase(
  name: 'Error',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildError(BuildContext context) {
  final theme = Theme.of(context);

  return _FolderPickerPreview(
    breadcrumbs: const ['Home', 'Documents'],
    content: Center(
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
              'Connection timed out. Please check your network.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Interactive',
  type: _FolderPickerPreview,
  path: '[Catalog]/Nextcloud Folder Picker',
)
Widget buildInteractive(BuildContext context) {
  final theme = Theme.of(context);

  final folderCount = context.knobs.int.slider(
    label: 'Number of Folders',
    initialValue: 4,
    min: 0,
    max: 10,
  );

  final pathDepth = context.knobs.int.slider(
    label: 'Path Depth',
    initialValue: 2,
    min: 1,
    max: 5,
  );

  final showError = context.knobs.boolean(
    label: 'Show Error State',
    initialValue: false,
  );

  final breadcrumbs = List.generate(
    pathDepth,
    (index) => index == 0 ? 'Home' : 'Level $index',
  );

  final folders = List.generate(folderCount, (index) => 'Folder ${index + 1}');

  Widget content;
  if (showError) {
    content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load folder',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  } else if (folderCount == 0) {
    content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No subfolders',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  } else {
    content = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.folder, color: theme.colorScheme.primary),
          title: Text(folders[index]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => debugPrint('Tapped ${folders[index]}'),
        );
      },
    );
  }

  return _FolderPickerPreview(
    breadcrumbs: breadcrumbs,
    content: content,
    onBreadcrumbTap: () => debugPrint('Breadcrumb tapped'),
  );
}
