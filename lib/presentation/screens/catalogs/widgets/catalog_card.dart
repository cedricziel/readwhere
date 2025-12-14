import 'package:flutter/material.dart';

import '../../../../domain/entities/catalog.dart';
import '../../../widgets/adaptive/adaptive_action_sheet.dart';
import '../../../widgets/adaptive/adaptive_button.dart';

/// A card widget displaying a catalog (server) entry
class CatalogCard extends StatelessWidget {
  final Catalog catalog;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onChangeFolder;

  const CatalogCard({
    super.key,
    required this.catalog,
    required this.onTap,
    required this.onDelete,
    this.onChangeFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Server icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  catalog.isKavita ? Icons.menu_book : Icons.public,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Server info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            catalog.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (catalog.isKavita)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Kavita',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatUrl(catalog.url),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (catalog.lastAccessedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Last accessed: ${_formatDate(catalog.lastAccessedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    if (catalog.serverVersion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Version: ${catalog.serverVersion}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Menu button
              AdaptiveIconButton(
                icon: Icons.more_vert,
                tooltip: 'Server options',
                onPressed: () => _showContextMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a context menu for server actions
  void _showContextMenu(BuildContext context) {
    AdaptiveActionSheet.show(
      context: context,
      title: catalog.name,
      actions: [
        if (catalog.isNextcloud && onChangeFolder != null)
          AdaptiveActionSheetAction(
            label: 'Change Starting Folder',
            icon: Icons.folder_open,
            onPressed: () => onChangeFolder!(),
          ),
        AdaptiveActionSheetAction(
          label: 'Remove',
          icon: Icons.delete_outline,
          isDestructive: true,
          onPressed: onDelete,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatUrl(String url) {
    // Remove protocol and trailing slashes for display
    var formatted = url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }
}
