import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:readwhere/presentation/providers/catalogs_provider.dart';

/// Extension on WidgetTester to simplify widget pumping with providers
extension PumpAppExtension on WidgetTester {
  /// Pumps a widget wrapped in MaterialApp with optional providers
  ///
  /// This is a convenience method for testing widgets that depend on
  /// providers. Pass mock providers as needed.
  Future<void> pumpApp(
    Widget widget, {
    LibraryProvider? libraryProvider,
    SettingsProvider? settingsProvider,
    CatalogsProvider? catalogsProvider,
    ThemeData? theme,
    GoRouter? router,
    Size? screenSize,
  }) async {
    final providers = <SingleChildWidget>[];

    if (libraryProvider != null) {
      providers.add(
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
      );
    }

    if (settingsProvider != null) {
      providers.add(
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      );
    }

    if (catalogsProvider != null) {
      providers.add(
        ChangeNotifierProvider<CatalogsProvider>.value(value: catalogsProvider),
      );
    }

    Widget app;

    if (router != null) {
      app = MaterialApp.router(
        theme: theme ?? ThemeData.light(),
        routerConfig: router,
      );
    } else {
      app = MaterialApp(theme: theme ?? ThemeData.light(), home: widget);
    }

    Widget wrappedWidget;
    if (providers.isNotEmpty) {
      wrappedWidget = MultiProvider(providers: providers, child: app);
    } else {
      wrappedWidget = app;
    }

    if (screenSize != null) {
      await binding.setSurfaceSize(screenSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await pumpWidget(wrappedWidget);
  }

  /// Pumps a widget with a scaffold wrapper
  ///
  /// Useful for testing widgets that need to be in a Scaffold context.
  Future<void> pumpWidgetWithScaffold(
    Widget widget, {
    ThemeData? theme,
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      await binding.setSurfaceSize(screenSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(body: widget),
      ),
    );
  }

  /// Pumps a widget wrapped in MaterialApp only
  ///
  /// Simplest wrapper for widgets that only need MaterialApp context.
  Future<void> pumpMaterialApp(
    Widget widget, {
    ThemeData? theme,
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      await binding.setSurfaceSize(screenSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await pumpWidget(
      MaterialApp(theme: theme ?? ThemeData.light(), home: widget),
    );
  }

  /// Pumps a widget with dark theme
  Future<void> pumpDarkTheme(Widget widget) async {
    await pumpWidget(MaterialApp(theme: ThemeData.dark(), home: widget));
  }
}

/// Helper to create a minimal provider wrapper for testing
Widget wrapWithProviders(
  Widget child, {
  LibraryProvider? libraryProvider,
  SettingsProvider? settingsProvider,
  CatalogsProvider? catalogsProvider,
}) {
  final providers = <SingleChildWidget>[];

  if (libraryProvider != null) {
    providers.add(
      ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
    );
  }

  if (settingsProvider != null) {
    providers.add(
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
    );
  }

  if (catalogsProvider != null) {
    providers.add(
      ChangeNotifierProvider<CatalogsProvider>.value(value: catalogsProvider),
    );
  }

  if (providers.isEmpty) {
    return child;
  }

  return MultiProvider(providers: providers, child: child);
}
