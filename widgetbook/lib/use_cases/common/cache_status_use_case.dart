import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/common/cache_status_indicator.dart';

@widgetbook.UseCase(
  name: 'Fresh Cache',
  type: CacheStatusIndicator,
  path: '[Common]',
)
Widget buildCacheStatusFresh(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      CacheStatusIndicator(
        isFromCache: true,
        isFresh: true,
        cacheAgeText: context.knobs.string(
          label: 'Cache Age Text',
          initialValue: 'Cached 5 minutes ago',
        ),
        isRefreshing: context.knobs.boolean(
          label: 'Is Refreshing',
          initialValue: false,
        ),
        onRefresh: () {
          debugPrint('Refresh pressed!');
        },
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'Stale Cache',
  type: CacheStatusIndicator,
  path: '[Common]',
)
Widget buildCacheStatusStale(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      CacheStatusIndicator(
        isFromCache: true,
        isFresh: false,
        cacheAgeText: context.knobs.string(
          label: 'Cache Age Text',
          initialValue: 'Cached 2 hours ago (stale)',
        ),
        isRefreshing: context.knobs.boolean(
          label: 'Is Refreshing',
          initialValue: false,
        ),
        onRefresh: () {
          debugPrint('Refresh pressed!');
        },
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'Refreshing',
  type: CacheStatusIndicator,
  path: '[Common]',
)
Widget buildCacheStatusRefreshing(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      CacheStatusIndicator(
        isFromCache: true,
        isFresh: context.knobs.boolean(label: 'Is Fresh', initialValue: false),
        cacheAgeText: 'Refreshing...',
        isRefreshing: true,
        onRefresh: () {},
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'Not From Cache',
  type: CacheStatusIndicator,
  path: '[Common]',
)
Widget buildCacheStatusNotCached(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('(Widget is hidden when not from cache)'),
      const SizedBox(height: 16),
      CacheStatusIndicator(
        isFromCache: false,
        isFresh: true,
        cacheAgeText: 'This should not be visible',
        onRefresh: () {},
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Fresh', type: CacheStatusChip, path: '[Common]')
Widget buildCacheStatusChipFresh(BuildContext context) {
  return Center(
    child: CacheStatusChip(
      isFromCache: true,
      isFresh: true,
      cacheAgeText: context.knobs.string(
        label: 'Cache Age',
        initialValue: '5m ago',
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Stale', type: CacheStatusChip, path: '[Common]')
Widget buildCacheStatusChipStale(BuildContext context) {
  return Center(
    child: CacheStatusChip(
      isFromCache: true,
      isFresh: false,
      cacheAgeText: context.knobs.string(
        label: 'Cache Age',
        initialValue: '2h ago',
      ),
    ),
  );
}
