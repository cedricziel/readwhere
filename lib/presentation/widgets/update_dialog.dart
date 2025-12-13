import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/update_service.dart';

/// A dialog that displays information about an available app update.
///
/// Shows the new version number, release notes, and provides buttons
/// to update or dismiss the dialog.
class UpdateDialog extends StatelessWidget {
  /// The update information to display.
  final UpdateInfo updateInfo;

  /// The current app version.
  final String currentVersion;

  /// Callback when the user dismisses the dialog.
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog.adaptive(
      title: Row(
        children: [
          Icon(Icons.system_update, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'v$currentVersion',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'New',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'v${updateInfo.version}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Release notes
            if (updateInfo.releaseNotes != null &&
                updateInfo.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "What's New",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Markdown(
                  data: updateInfo.releaseNotes!,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium,
                    h1: theme.textTheme.titleLarge,
                    h2: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    h3: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: theme.textTheme.bodyMedium,
                    code: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href != null) {
                      final url = Uri.parse(href);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                ),
              ),
            ],

            // Published date
            if (updateInfo.publishedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Released: ${_formatDate(updateInfo.publishedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () => _openReleases(context),
          icon: const Icon(Icons.download),
          label: const Text('Update'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openReleases(BuildContext context) async {
    final url = Uri.parse(updateInfo.releaseUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open releases page')),
        );
      }
    }
  }

  /// Shows the update dialog.
  static Future<void> show(
    BuildContext context, {
    required UpdateInfo updateInfo,
    required String currentVersion,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
        onDismiss: onDismiss,
      ),
    );
  }
}
