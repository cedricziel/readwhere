import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/themes/app_theme.dart';

// Import generated directories
import 'main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        // Theme switching addon
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Dark', data: AppTheme.darkTheme),
          ],
        ),
        // Viewport addon for testing on different screen sizes
        ViewportAddon(Viewports.all),
        // Text scale addon for accessibility testing
        TextScaleAddon(min: 1.0, max: 2.0),
        // Grid overlay for alignment checking
        GridAddon(),
        // Inspector addon for debugging
        InspectorAddon(),
      ],
      appBuilder: (context, child) {
        // Wrap with any providers or theme overrides if needed
        return child;
      },
    );
  }
}
