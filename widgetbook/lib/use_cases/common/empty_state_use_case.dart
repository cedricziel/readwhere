import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/common/empty_state.dart';

@widgetbook.UseCase(name: 'Default', type: EmptyState, path: '[Common]')
Widget buildEmptyStateDefault(BuildContext context) {
  final iconOptions = {
    'Library': Icons.library_books_outlined,
    'Folder': Icons.folder_open,
    'Search': Icons.search_off,
    'Offline': Icons.wifi_off,
    'Error': Icons.error_outline,
  };

  final selectedIconName = context.knobs.string(
    label: 'Icon',
    initialValue: 'Library',
  );

  return EmptyState(
    icon: iconOptions[selectedIconName] ?? Icons.library_books_outlined,
    title: context.knobs.string(label: 'Title', initialValue: 'No books yet'),
    subtitle: context.knobs.stringOrNull(
      label: 'Subtitle',
      initialValue: 'Add books to your library to start reading',
    ),
    iconSize: context.knobs.double.slider(
      label: 'Icon Size',
      initialValue: 64,
      min: 32,
      max: 128,
    ),
  );
}

@widgetbook.UseCase(name: 'With Action', type: EmptyState, path: '[Common]')
Widget buildEmptyStateWithAction(BuildContext context) {
  return EmptyState(
    icon: Icons.library_books_outlined,
    title: context.knobs.string(
      label: 'Title',
      initialValue: 'Your library is empty',
    ),
    subtitle: context.knobs.stringOrNull(
      label: 'Subtitle',
      initialValue: 'Add your first book to get started',
    ),
    actionLabel: context.knobs.string(
      label: 'Action Label',
      initialValue: 'Add Book',
    ),
    onAction: () {
      debugPrint('Action pressed!');
    },
  );
}

@widgetbook.UseCase(name: 'Error State', type: EmptyState, path: '[Common]')
Widget buildEmptyStateError(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return EmptyState(
    icon: Icons.error_outline,
    title: 'Something went wrong',
    subtitle: context.knobs.string(
      label: 'Error Message',
      initialValue: 'Could not load content. Please try again.',
    ),
    iconColor: colorScheme.error,
    actionLabel: 'Retry',
    onAction: () {
      debugPrint('Retry pressed!');
    },
  );
}

@widgetbook.UseCase(name: 'Offline State', type: EmptyState, path: '[Common]')
Widget buildEmptyStateOffline(BuildContext context) {
  return const EmptyState(
    icon: Icons.wifi_off,
    title: 'You\'re offline',
    subtitle: 'Connect to the internet to browse catalogs',
  );
}
