import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:readwhere_rss_plugin/readwhere_rss_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database_helper.dart';
import 'plugin_context_factory.dart';
import 'plugin_storage_impl.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/opds_cache_repository_impl.dart';
import '../../data/repositories/reading_progress_repository_impl.dart';
import '../../data/services/book_import_service.dart';
import '../../data/services/opds_cache_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/opds_cache_repository.dart';
import '../../domain/repositories/feed_item_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../data/repositories/feed_item_repository_impl.dart';
import '../../presentation/providers/audio_provider.dart';
import '../../presentation/providers/feed_reader_provider.dart';
import '../../presentation/providers/catalogs_provider.dart';
import '../../presentation/providers/library_provider.dart';
import '../../presentation/providers/reader_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/update_provider.dart';
import '../services/update_service.dart';

/// Global service locator instance for dependency injection.
///
/// Uses GetIt package to manage dependencies throughout the app.
/// All dependencies are registered as lazy singletons to ensure
/// single instances and lazy initialization.
final GetIt sl = GetIt.instance;

/// Initializes all dependencies and registers them with the service locator.
///
/// This should be called once at app startup before runApp().
/// Dependencies are registered in order:
/// 1. Core services (database)
/// 2. Repositories
/// 3. Providers
Future<void> setupServiceLocator() async {
  // Core Services
  // DatabaseHelper is registered as async singleton to handle initialization
  sl.registerLazySingletonAsync<DatabaseHelper>(() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Ensure database is initialized
    return dbHelper;
  });

  // Wait for DatabaseHelper to be ready before registering repositories
  await sl.isReady<DatabaseHelper>();

  // ===== Unified Plugin System =====

  // SharedPreferences (for plugin settings)
  sl.registerLazySingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });
  await sl.isReady<SharedPreferences>();

  // FlutterSecureStorage (for plugin credentials)
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  // PluginStorageFactory
  sl.registerLazySingleton<PluginStorageFactory>(
    () => PluginStorageFactoryImpl(
      prefs: sl<SharedPreferences>(),
      secureStorage: sl<FlutterSecureStorage>(),
      dbHelper: sl<DatabaseHelper>(),
    ),
  );

  // PluginContextFactory
  sl.registerLazySingleton<PluginContextFactory>(
    () => PluginContextFactoryImpl(
      appConfig: PluginAppConfigBuilder.fromPlatform(
        appVersion: '1.0.0', // TODO: Get from package_info_plus
        isDarkMode: false, // TODO: Get from theme provider
      ),
    ),
  );

  // UnifiedPluginRegistry - register all plugins
  sl.registerLazySingletonAsync<UnifiedPluginRegistry>(() async {
    final registry = UnifiedPluginRegistry();
    final storageFactory = sl<PluginStorageFactory>();
    final contextFactory = sl<PluginContextFactory>();

    // Register EPUB plugin
    await registry.register(
      ReadwhereEpubPlugin(),
      storageFactory: storageFactory,
      contextFactory: contextFactory,
    );

    // Additional plugins will be registered here as they're migrated
    // await registry.register(CbzPlugin(), ...);
    // await registry.register(CbrPlugin(), ...);

    return registry;
  });
  await sl.isReady<UnifiedPluginRegistry>();

  // Repositories
  sl.registerLazySingleton<BookRepository>(() => BookRepositoryImpl(sl()));

  sl.registerLazySingleton<ReadingProgressRepository>(
    () => ReadingProgressRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<OpdsCacheRepository>(
    () => OpdsCacheRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<FeedItemRepository>(
    () => FeedItemRepositoryImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<BookImportService>(() => BookImportService());

  sl.registerLazySingleton<OpdsClient>(() => OpdsClient(http.Client()));

  sl.registerLazySingleton<RssClient>(() => RssClient(http.Client()));

  sl.registerLazySingleton<KavitaApiClient>(
    () => KavitaApiClient(http.Client()),
  );

  sl.registerLazySingleton<OpdsCacheService>(
    () => OpdsCacheService(opdsClient: sl(), cacheRepository: sl()),
  );

  // Nextcloud services (from readwhere_nextcloud package)
  sl.registerLazySingleton<NextcloudCredentialStorage>(
    () => SecureCredentialStorage(),
  );

  sl.registerLazySingleton<OcsApiService>(() => OcsApiService(http.Client()));

  sl.registerLazySingleton<NextcloudClient>(
    () => NextcloudClient.create(
      httpClient: http.Client(),
      credentialStorage: sl<NextcloudCredentialStorage>(),
    ),
  );

  sl.registerLazySingleton<NextcloudProvider>(
    () => NextcloudProvider(sl<NextcloudClient>()),
  );

  // OPDS Provider (state management for OPDS browsing)
  sl.registerLazySingleton<OpdsProvider>(
    () => OpdsProvider(
      opdsClient: sl<OpdsClient>(),
      cache: sl<OpdsCacheService>(),
      importBook: (filePath, {sourceCatalogId, sourceEntryId}) async {
        final book = await sl<BookImportService>().importBook(filePath);
        final bookWithSource = book.copyWith(
          sourceCatalogId: sourceCatalogId,
          sourceEntryId: sourceEntryId,
        );
        final savedBook = await sl<BookRepository>().insert(bookWithSource);
        return savedBook.id;
      },
    ),
  );

  // Kavita Provider (state management for Kavita browsing + progress sync)
  sl.registerLazySingleton<KavitaProvider>(
    () => KavitaProvider(
      kavitaClient: sl<KavitaApiClient>(),
      opdsProvider: sl<OpdsProvider>(),
      catalogLookup: (catalogId) async {
        final catalog = await sl<CatalogRepository>().getById(catalogId);
        if (catalog == null) return null;
        return KavitaCatalogInfo(
          id: catalog.id,
          url: catalog.url,
          apiKey: catalog.apiKey,
        );
      },
    ),
  );

  // Catalog Provider Registry (plugin system)
  sl.registerLazySingleton<CatalogProviderRegistry>(() {
    final registry = CatalogProviderRegistry();

    // OPDS Provider (for generic OPDS catalogs)
    // Uses package providers with injectable cache
    registry.register(
      OpdsCatalogProvider(sl<OpdsClient>(), cache: sl<OpdsCacheService>()),
      accountProvider: OpdsAccountProvider(),
    );

    // Kavita Provider (OPDS + Kavita API for progress sync)
    // Uses package providers with injectable cache
    registry.register(
      KavitaCatalogProvider(
        sl<KavitaApiClient>(),
        sl<OpdsClient>(),
        cache: sl<OpdsCacheService>(),
      ),
      accountProvider: KavitaAccountProvider(sl<KavitaApiClient>()),
    );

    // Nextcloud Provider (WebDAV file access)
    registry.register(
      NextcloudCatalogProvider(sl<NextcloudClient>()),
      accountProvider: NextcloudAccountProvider(sl<OcsApiService>()),
    );

    // RSS Provider (RSS/Atom feeds)
    registry.register(
      RssCatalogProvider(sl<RssClient>()),
      accountProvider: RssAccountProvider(),
    );

    return registry;
  });

  // Providers
  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());

  sl.registerLazySingleton<SettingsProvider>(() => SettingsProvider());

  sl.registerLazySingleton<LibraryProvider>(
    () => LibraryProvider(bookRepository: sl(), importService: sl()),
  );

  sl.registerLazySingleton<AudioProvider>(() => AudioProvider());

  sl.registerLazySingleton<CatalogsProvider>(
    () => CatalogsProvider(
      catalogRepository: sl(),
      opdsClient: sl(),
      kavitaApiClient: sl(),
      rssClient: sl(),
      nextcloudProvider: sl(),
      credentialStorage: sl(),
    ),
  );

  sl.registerLazySingleton<ReaderProvider>(
    () => ReaderProvider(
      readingProgressRepository: sl(),
      bookmarkRepository: sl(),
      kavitaProvider: sl(),
    ),
  );

  sl.registerLazySingleton<FeedReaderProvider>(
    () => FeedReaderProvider(feedItemRepository: sl(), rssClient: sl()),
  );

  // Update Service
  sl.registerLazySingleton<UpdateService>(
    () => UpdateService(httpClient: http.Client()),
  );

  sl.registerLazySingleton<UpdateProvider>(
    () => UpdateProvider(updateService: sl()),
  );
}

/// Resets the service locator (useful for testing).
///
/// This will unregister all dependencies and clear the service locator.
Future<void> resetServiceLocator() async {
  await sl.reset();
}
