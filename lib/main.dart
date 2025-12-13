import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger.dart';
import 'data/services/background_sync_manager.dart';
import 'presentation/providers/audio_provider.dart';
import 'presentation/providers/catalogs_provider.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/reader_provider.dart';
import 'presentation/providers/feed_reader_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/sync_settings_provider.dart';
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
  // All reader plugins (EPUB, CBZ, CBR) are now registered via
  // UnifiedPluginRegistry in service_locator.dart
  await setupServiceLocator();

  // Initialize providers from service locator
  final themeProvider = sl<ThemeProvider>();
  final settingsProvider = sl<SettingsProvider>();
  final libraryProvider = sl<LibraryProvider>();
  final readerProvider = sl<ReaderProvider>();
  final audioProvider = sl<AudioProvider>();
  final catalogsProvider = sl<CatalogsProvider>();
  final opdsProvider = sl<OpdsProvider>();
  final kavitaProvider = sl<KavitaProvider>();
  final nextcloudProvider = sl<NextcloudProvider>();
  final feedReaderProvider = sl<FeedReaderProvider>();

  // Initialize settings (loads from SharedPreferences)
  await settingsProvider.initialize();

  // Initialize theme based on settings
  await themeProvider.initialize();

  // Initialize sync settings (loads from SharedPreferences)
  final syncSettingsProvider = sl<SyncSettingsProvider>();
  await syncSettingsProvider.initialize();

  // Initialize background sync manager (schedules periodic sync if enabled)
  // Uses unawaited() to avoid blocking app startup
  unawaited(sl.getAsync<BackgroundSyncManager>());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
        ChangeNotifierProvider<ReaderProvider>.value(value: readerProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<CatalogsProvider>.value(value: catalogsProvider),
        ChangeNotifierProvider<OpdsProvider>.value(value: opdsProvider),
        ChangeNotifierProvider<KavitaProvider>.value(value: kavitaProvider),
        ChangeNotifierProvider<NextcloudProvider>.value(
          value: nextcloudProvider,
        ),
        ChangeNotifierProvider<FeedReaderProvider>.value(
          value: feedReaderProvider,
        ),
      ],
      child: const ReadWhereApp(),
    ),
  );
}
