import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/screens/catalogs/browse/widgets/feed_breadcrumbs.dart';

@widgetbook.UseCase(
  name: 'Short Path',
  type: FeedBreadcrumbs,
  path: '[Catalog]',
)
Widget buildFeedBreadcrumbsShort(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      FeedBreadcrumbs(
        breadcrumbs: const ['Home', 'Fiction'],
        onTap: (index) {
          debugPrint('Tapped breadcrumb at index: $index');
        },
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Long Path', type: FeedBreadcrumbs, path: '[Catalog]')
Widget buildFeedBreadcrumbsLong(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      FeedBreadcrumbs(
        breadcrumbs: const [
          'Standard Ebooks',
          'Fiction',
          'Science Fiction',
          'Space Opera',
          'Isaac Asimov',
        ],
        onTap: (index) {
          debugPrint('Tapped breadcrumb at index: $index');
        },
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'Single Item',
  type: FeedBreadcrumbs,
  path: '[Catalog]',
)
Widget buildFeedBreadcrumbsSingle(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      FeedBreadcrumbs(
        breadcrumbs: const ['Catalog Home'],
        onTap: (index) {
          debugPrint('Tapped breadcrumb at index: $index');
        },
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'Interactive',
  type: FeedBreadcrumbs,
  path: '[Catalog]',
)
Widget buildFeedBreadcrumbsInteractive(BuildContext context) {
  final count = context.knobs.int.slider(
    label: 'Number of Items',
    initialValue: 3,
    min: 1,
    max: 6,
  );

  final items = List.generate(count, (index) => 'Level ${index + 1}');

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      FeedBreadcrumbs(
        breadcrumbs: items,
        onTap: (index) {
          debugPrint('Tapped breadcrumb at index: $index');
        },
      ),
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Tap any item except the last to navigate back',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Empty', type: FeedBreadcrumbs, path: '[Catalog]')
Widget buildFeedBreadcrumbsEmpty(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('(Widget is hidden when empty)'),
      const SizedBox(height: 16),
      FeedBreadcrumbs(breadcrumbs: const [], onTap: (index) {}),
    ],
  );
}
