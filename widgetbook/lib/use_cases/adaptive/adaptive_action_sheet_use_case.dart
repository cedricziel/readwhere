import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/adaptive/adaptive_action_sheet.dart';
import 'package:readwhere/presentation/widgets/adaptive/adaptive_button.dart';

@widgetbook.UseCase(
  name: 'Basic Actions',
  type: AdaptiveActionSheet,
  path: '[Adaptive]',
)
Widget buildAdaptiveActionSheet(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveFilledButton(
            onPressed: () {
              AdaptiveActionSheet.show(
                context: context,
                title: 'Book Options',
                message: 'Choose an action for this book',
                actions: [
                  AdaptiveActionSheetAction(
                    label: 'Read',
                    icon: Icons.book,
                    onPressed: () => debugPrint('Read selected'),
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Share',
                    icon: Icons.share,
                    onPressed: () => debugPrint('Share selected'),
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Download',
                    icon: Icons.download,
                    onPressed: () => debugPrint('Download selected'),
                  ),
                ],
              );
            },
            child: const Text('Show Action Sheet'),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive action sheet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: Modal Bottom Sheet\n'
            '• Cupertino: CupertinoActionSheet',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'With Destructive Action',
  type: AdaptiveActionSheet,
  path: '[Adaptive]',
)
Widget buildAdaptiveActionSheetDestructive(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveFilledButton(
            onPressed: () {
              AdaptiveActionSheet.show(
                context: context,
                title: 'Delete Book',
                message: 'This action cannot be undone',
                actions: [
                  AdaptiveActionSheetAction(
                    label: 'Delete from Library',
                    icon: Icons.delete,
                    onPressed: () => debugPrint('Delete from library'),
                    isDestructive: true,
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Delete from Device',
                    icon: Icons.delete_forever,
                    onPressed: () => debugPrint('Delete from device'),
                    isDestructive: true,
                  ),
                ],
                cancelAction: AdaptiveActionSheetAction(
                  label: 'Cancel',
                  onPressed: () => debugPrint('Cancelled'),
                ),
              );
            },
            child: const Text('Show Destructive Actions'),
          ),
          const SizedBox(height: 24),
          Text(
            'Action sheet with destructive options',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Destructive actions are shown in red/error color',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'With Default Action',
  type: AdaptiveActionSheet,
  path: '[Adaptive]',
)
Widget buildAdaptiveActionSheetDefault(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveFilledButton(
            onPressed: () {
              AdaptiveActionSheet.show(
                context: context,
                title: 'Export Format',
                message: 'Choose a format to export your notes',
                actions: [
                  AdaptiveActionSheetAction(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf,
                    onPressed: () => debugPrint('PDF selected'),
                    isDefault: true,
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Text',
                    icon: Icons.text_snippet,
                    onPressed: () => debugPrint('Text selected'),
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Markdown',
                    icon: Icons.code,
                    onPressed: () => debugPrint('Markdown selected'),
                  ),
                ],
              );
            },
            child: const Text('Show With Default'),
          ),
          const SizedBox(height: 24),
          Text(
            'Action sheet with default action',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Default action has bold text on iOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Simple (No Title)',
  type: AdaptiveActionSheet,
  path: '[Adaptive]',
)
Widget buildAdaptiveActionSheetSimple(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveFilledButton(
            onPressed: () {
              AdaptiveActionSheet.show(
                context: context,
                actions: [
                  AdaptiveActionSheetAction(
                    label: 'Copy',
                    icon: Icons.copy,
                    onPressed: () => debugPrint('Copy'),
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Paste',
                    icon: Icons.paste,
                    onPressed: () => debugPrint('Paste'),
                  ),
                  AdaptiveActionSheetAction(
                    label: 'Select All',
                    icon: Icons.select_all,
                    onPressed: () => debugPrint('Select All'),
                  ),
                ],
              );
            },
            child: const Text('Show Simple Action Sheet'),
          ),
          const SizedBox(height: 24),
          Text(
            'Action sheet without title or message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}
