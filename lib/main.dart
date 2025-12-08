import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger.dart';
import 'plugins/plugin_registry.dart';
import 'plugins/epub/readwhere_epub_plugin.dart';
import 'presentation/providers/audio_provider.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/reader_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_provider.dart';

/// The main entry point of the ReadWhere e-reader application.
///
/// This function initializes the app's logging, dependency injection,
/// plugins, database, and starts the Flutter application.
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.initialize(level: Level.INFO);

  // Initialize dependency injection and wait for setup to complete
  await setupServiceLocator();

  // Register EPUB plugin with PluginRegistry
  final pluginRegistry = PluginRegistry();
  pluginRegistry.register(ReadwhereEpubPlugin());

  // Initialize providers from service locator
  final themeProvider = sl<ThemeProvider>();
  final settingsProvider = sl<SettingsProvider>();
  final libraryProvider = sl<LibraryProvider>();
  final readerProvider = sl<ReaderProvider>();
  final audioProvider = sl<AudioProvider>();

  // Initialize settings (loads from SharedPreferences)
  await settingsProvider.initialize();

  // Initialize theme based on settings
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
        ChangeNotifierProvider<ReaderProvider>.value(value: readerProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
      ],
      child: const ReadWhereApp(),
    ),
  );
}
