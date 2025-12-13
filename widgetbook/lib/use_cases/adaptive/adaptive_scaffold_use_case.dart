import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/adaptive/adaptive_scaffold.dart';
import 'package:readwhere/presentation/router/routes.dart';

@widgetbook.UseCase(
  name: 'With Navigation',
  type: AdaptiveScaffold,
  path: '[Adaptive]',
)
Widget buildAdaptiveScaffold(BuildContext context) {
  final selectedIndex = context.knobs.int.slider(
    label: 'Selected Index',
    initialValue: 0,
    min: 0,
    max: 3,
  );

  return AdaptiveScaffold(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      debugPrint('Selected destination: $index');
    },
    destinations: AppDestinations.all,
    child: _buildContent(context, selectedIndex),
  );
}

@widgetbook.UseCase(
  name: 'Library Selected',
  type: AdaptiveScaffold,
  path: '[Adaptive]',
)
Widget buildAdaptiveScaffoldLibrary(BuildContext context) {
  return AdaptiveScaffold(
    selectedIndex: 0,
    onDestinationSelected: (index) {
      debugPrint('Selected destination: $index');
    },
    destinations: AppDestinations.all,
    child: _buildContent(context, 0),
  );
}

@widgetbook.UseCase(
  name: 'Catalogs Selected',
  type: AdaptiveScaffold,
  path: '[Adaptive]',
)
Widget buildAdaptiveScaffoldCatalogs(BuildContext context) {
  return AdaptiveScaffold(
    selectedIndex: 1,
    onDestinationSelected: (index) {
      debugPrint('Selected destination: $index');
    },
    destinations: AppDestinations.all,
    child: _buildContent(context, 1),
  );
}

@widgetbook.UseCase(
  name: 'Custom Destinations',
  type: AdaptiveScaffold,
  path: '[Adaptive]',
)
Widget buildAdaptiveScaffoldCustom(BuildContext context) {
  final destinations = [
    const AppNavigationDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/home',
    ),
    const AppNavigationDestination(
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      route: '/search',
    ),
    const AppNavigationDestination(
      label: 'Profile',
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      route: '/profile',
    ),
  ];

  final selectedIndex = context.knobs.int.slider(
    label: 'Selected Index',
    initialValue: 0,
    min: 0,
    max: 2,
  );

  return AdaptiveScaffold(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      debugPrint('Selected destination: $index');
    },
    destinations: destinations,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            destinations[selectedIndex].selectedIcon,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            destinations[selectedIndex].label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    ),
  );
}

Widget _buildContent(BuildContext context, int selectedIndex) {
  final destinations = AppDestinations.all;
  final current = destinations[selectedIndex];
  final theme = Theme.of(context);

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(current.selectedIcon, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(current.label, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Route: ${current.route}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Resize the window to see navigation adapt',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '• Mobile (<600px): Bottom Navigation\n'
          '• Tablet (600-1200px): Collapsed Rail\n'
          '• Desktop (≥1200px): Extended Rail',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    ),
  );
}
