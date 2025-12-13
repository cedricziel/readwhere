import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/adaptive/responsive_layout.dart';

@widgetbook.UseCase(
  name: 'With Separate Builders',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildResponsiveLayoutSeparate(BuildContext context) {
  return ResponsiveLayout(
    mobile: (context) => _buildLayoutPreview(
      context,
      'Mobile Layout',
      Icons.phone_android,
      Colors.blue,
    ),
    tablet: (context) => _buildLayoutPreview(
      context,
      'Tablet Layout',
      Icons.tablet_android,
      Colors.green,
    ),
    desktop: (context) => _buildLayoutPreview(
      context,
      'Desktop Layout',
      Icons.desktop_windows,
      Colors.purple,
    ),
  );
}

@widgetbook.UseCase(
  name: 'With Builder Pattern',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildResponsiveLayoutBuilder(BuildContext context) {
  return ResponsiveLayout.builder(
    builder: (context, deviceType) {
      final String label;
      final IconData icon;
      final Color color;

      switch (deviceType) {
        case DeviceType.mobile:
          label = 'Mobile';
          icon = Icons.phone_android;
          color = Colors.blue;
        case DeviceType.tablet:
          label = 'Tablet';
          icon = Icons.tablet_android;
          color = Colors.green;
        case DeviceType.desktop:
          label = 'Desktop';
          icon = Icons.desktop_windows;
          color = Colors.purple;
      }

      return _buildLayoutPreview(context, label, icon, color);
    },
  );
}

@widgetbook.UseCase(
  name: 'With Value Pattern',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildResponsiveLayoutValue(BuildContext context) {
  return ResponsiveLayout.withValue<double>(
    mobile: 8.0,
    tablet: 16.0,
    desktop: 32.0,
    builder: (context, padding) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Responsive Padding',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Padding: ${padding.toInt()}px',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Content with responsive padding'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

@widgetbook.UseCase(
  name: 'Grid Columns Example',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildResponsiveLayoutGrid(BuildContext context) {
  return ResponsiveLayout.withValue<int>(
    mobile: 2,
    tablet: 3,
    desktop: 4,
    builder: (context, columns) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Grid with $columns columns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return Card(child: Center(child: Text('Item ${index + 1}')));
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildLayoutPreview(
  BuildContext context,
  String label,
  IconData icon,
  Color color,
) {
  final theme = Theme.of(context);

  return Container(
    color: theme.colorScheme.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            'Device Type: ${DeviceType.fromContext(context).name}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Width: ${MediaQuery.of(context).size.width.toInt()}px',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
