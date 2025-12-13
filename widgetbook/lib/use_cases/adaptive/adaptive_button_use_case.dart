import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/adaptive/adaptive_button.dart';

@widgetbook.UseCase(
  name: 'Filled Button',
  type: AdaptiveFilledButton,
  path: '[Adaptive]',
)
Widget buildAdaptiveFilledButton(BuildContext context) {
  final isLoading = context.knobs.boolean(
    label: 'Loading',
    initialValue: false,
  );

  final isDisabled = context.knobs.boolean(
    label: 'Disabled',
    initialValue: false,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveFilledButton(
            onPressed: isDisabled ? null : () => debugPrint('Pressed!'),
            isLoading: isLoading,
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive filled button',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: FilledButton\n'
            '• Cupertino: CupertinoButton.filled',
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
  name: 'Text Button',
  type: AdaptiveTextButton,
  path: '[Adaptive]',
)
Widget buildAdaptiveTextButton(BuildContext context) {
  final isDestructive = context.knobs.boolean(
    label: 'Destructive',
    initialValue: false,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveTextButton(
            onPressed: () => debugPrint('Pressed!'),
            isDestructive: isDestructive,
            child: Text(isDestructive ? 'Delete' : 'Cancel'),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive text button',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: TextButton\n'
            '• Cupertino: CupertinoButton',
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
  name: 'Outlined Button',
  type: AdaptiveOutlinedButton,
  path: '[Adaptive]',
)
Widget buildAdaptiveOutlinedButton(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveOutlinedButton(
            onPressed: () => debugPrint('Pressed!'),
            child: const Text('Show More'),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive outlined button',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: OutlinedButton\n'
            '• Cupertino: CupertinoButton with border',
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
  name: 'Icon Button',
  type: AdaptiveIconButton,
  path: '[Adaptive]',
)
Widget buildAdaptiveIconButton(BuildContext context) {
  final showTooltip = context.knobs.boolean(
    label: 'Show Tooltip',
    initialValue: true,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveIconButton(
                icon: Icons.close,
                onPressed: () => debugPrint('Close pressed!'),
                tooltip: showTooltip ? 'Close' : null,
              ),
              const SizedBox(width: 16),
              AdaptiveIconButton(
                icon: Icons.share,
                onPressed: () => debugPrint('Share pressed!'),
                tooltip: showTooltip ? 'Share' : null,
              ),
              const SizedBox(width: 16),
              AdaptiveIconButton(
                icon: Icons.more_vert,
                onPressed: () => debugPrint('More pressed!'),
                tooltip: showTooltip ? 'More options' : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive icon button',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: IconButton\n'
            '• Cupertino: CupertinoButton with Icon',
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
  name: 'Button Gallery',
  type: AdaptiveFilledButton,
  path: '[Adaptive]',
)
Widget buildAdaptiveButtonGallery(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Button Gallery', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          AdaptiveFilledButton(
            onPressed: () => debugPrint('Primary pressed!'),
            child: const Text('Primary Action'),
          ),
          const SizedBox(height: 16),
          AdaptiveOutlinedButton(
            onPressed: () => debugPrint('Secondary pressed!'),
            child: const Text('Secondary Action'),
          ),
          const SizedBox(height: 16),
          AdaptiveTextButton(
            onPressed: () => debugPrint('Tertiary pressed!'),
            child: const Text('Tertiary Action'),
          ),
          const SizedBox(height: 16),
          AdaptiveTextButton(
            onPressed: () => debugPrint('Destructive pressed!'),
            isDestructive: true,
            child: const Text('Destructive Action'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveIconButton(
                icon: Icons.edit,
                onPressed: () => debugPrint('Edit pressed!'),
                tooltip: 'Edit',
              ),
              AdaptiveIconButton(
                icon: Icons.delete,
                onPressed: () => debugPrint('Delete pressed!'),
                tooltip: 'Delete',
                color: Theme.of(context).colorScheme.error,
              ),
              AdaptiveIconButton(
                icon: Icons.share,
                onPressed: () => debugPrint('Share pressed!'),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
