import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/common/loading_indicator.dart';

@widgetbook.UseCase(name: 'Full Page', type: LoadingIndicator, path: '[Common]')
Widget buildLoadingIndicatorFullPage(BuildContext context) {
  return LoadingIndicator(
    message: context.knobs.stringOrNull(
      label: 'Message',
      initialValue: 'Loading...',
    ),
    size: context.knobs.doubleOrNull.slider(
      label: 'Size',
      initialValue: null,
      min: 24,
      max: 80,
    ),
  );
}

@widgetbook.UseCase(
  name: 'With Message',
  type: LoadingIndicator,
  path: '[Common]',
)
Widget buildLoadingIndicatorWithMessage(BuildContext context) {
  return LoadingIndicator(
    message: context.knobs.string(
      label: 'Message',
      initialValue: 'Parsing book metadata...',
    ),
  );
}

@widgetbook.UseCase(
  name: 'Custom Size',
  type: LoadingIndicator,
  path: '[Common]',
)
Widget buildLoadingIndicatorCustomSize(BuildContext context) {
  return LoadingIndicator(
    size: context.knobs.double.slider(
      label: 'Size',
      initialValue: 48,
      min: 24,
      max: 80,
    ),
    message: 'Loading catalog...',
  );
}

@widgetbook.UseCase(
  name: 'Default',
  type: CompactLoadingIndicator,
  path: '[Common]',
)
Widget buildCompactLoadingIndicator(BuildContext context) {
  return Center(
    child: CompactLoadingIndicator(
      size: context.knobs.doubleOrNull.slider(
        label: 'Size',
        initialValue: 16,
        min: 12,
        max: 32,
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'In Button Context',
  type: CompactLoadingIndicator,
  path: '[Common]',
)
Widget buildCompactLoadingIndicatorInButton(BuildContext context) {
  return Center(
    child: FilledButton(
      onPressed: null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompactLoadingIndicator(
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 8),
          const Text('Saving...'),
        ],
      ),
    ),
  );
}
