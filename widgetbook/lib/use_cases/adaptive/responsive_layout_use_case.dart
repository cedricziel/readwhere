import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/core/extensions/context_extensions.dart';
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

@widgetbook.UseCase(
  name: 'Orientation Helpers',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildOrientationHelpers(BuildContext context) {
  final theme = Theme.of(context);
  final size = MediaQuery.of(context).size;

  return Container(
    color: theme.colorScheme.surface,
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orientation Helpers', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildOrientationRow(
                context,
                'Screen Size',
                '${size.width.toInt()} × ${size.height.toInt()}',
              ),
              _buildOrientationRow(
                context,
                'isLandscape',
                '${context.isLandscape}',
                context.isLandscape ? Colors.green : null,
              ),
              _buildOrientationRow(
                context,
                'isPhoneLandscape',
                '${context.isPhoneLandscape}',
                context.isPhoneLandscape ? Colors.green : null,
              ),
              _buildOrientationRow(
                context,
                'shouldUseLandscapeLayout',
                '${context.shouldUseLandscapeLayout}',
                context.shouldUseLandscapeLayout ? Colors.green : null,
              ),
              _buildOrientationRow(
                context,
                'effectiveWidth',
                '${context.effectiveWidth.toInt()}px',
              ),
              const SizedBox(height: 16),
              Text('Use cases:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                '• isPhoneLandscape: Phone in landscape mode (height < 600px)\n'
                '• shouldUseLandscapeLayout: Use specialized landscape layouts\n'
                '• effectiveWidth: Screen height in phone landscape, width otherwise',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildOrientationRow(
  BuildContext context,
  String label,
  String value, [
  Color? valueColor,
]) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Responsive Spacing',
  type: ResponsiveLayout,
  path: '[Adaptive]',
)
Widget buildResponsiveSpacing(BuildContext context) {
  final theme = Theme.of(context);

  return Container(
    color: theme.colorScheme.surface,
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Responsive Spacing', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Values scale based on device type: Mobile → Tablet → Desktop',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _buildSpacingItem(context, 'spacingXS', context.spacingXS, '4/6/8'),
          _buildSpacingItem(context, 'spacingS', context.spacingS, '8/12/16'),
          _buildSpacingItem(context, 'spacingM', context.spacingM, '12/16/24'),
          _buildSpacingItem(context, 'spacingL', context.spacingL, '16/24/32'),
          _buildSpacingItem(
            context,
            'spacingXL',
            context.spacingXL,
            '24/32/48',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(context.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example: Card with spacingM padding',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: context.spacingS),
                  Text(
                    'Current spacingM value: ${context.spacingM}px\n'
                    'Current spacingS value: ${context.spacingS}px',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSpacingItem(
  BuildContext context,
  String name,
  double value,
  String scale,
) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(name, style: theme.textTheme.bodyMedium),
        ),
        Container(
          width: value,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${value.toInt()}px',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($scale)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    ),
  );
}
