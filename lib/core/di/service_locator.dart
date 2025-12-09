import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import '../../data/database/database_helper.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/opds_cache_repository_impl.dart';
import '../../data/repositories/reading_progress_repository_impl.dart';
import '../../data/services/book_import_service.dart';
import '../../data/services/kavita_api_service.dart';
import '../../data/services/opds_cache_service.dart';
import '../../data/services/opds_client_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/opds_cache_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../presentation/providers/audio_provider.dart';
import '../../presentation/providers/catalogs_provider.dart';
import '../../presentation/providers/library_provider.dart';
import '../../presentation/providers/reader_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/theme_provider.dart';

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

  // Services
  sl.registerLazySingleton<BookImportService>(() => BookImportService());

  sl.registerLazySingleton<OpdsClientService>(
    () => OpdsClientService(http.Client()),
  );

  sl.registerLazySingleton<KavitaApiService>(
    () => KavitaApiService(http.Client()),
  );

  sl.registerLazySingleton<OpdsCacheService>(
    () => OpdsCacheService(opdsClient: sl(), cacheRepository: sl()),
  );

  // Nextcloud services (from readwhere_nextcloud package)
  sl.registerLazySingleton<CredentialStorage>(() => SecureCredentialStorage());

  sl.registerLazySingleton<NextcloudClient>(
    () => NextcloudClient.create(
      httpClient: http.Client(),
      credentialStorage: sl<CredentialStorage>(),
    ),
  );

  sl.registerLazySingleton<NextcloudProvider>(
    () => NextcloudProvider(sl<NextcloudClient>()),
  );

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
      opdsClientService: sl(),
      cacheService: sl(),
      kavitaApiService: sl(),
      importService: sl(),
      bookRepository: sl(),
      nextcloudProvider: sl(),
      credentialStorage: sl(),
    ),
  );

  sl.registerLazySingleton<ReaderProvider>(
    () => ReaderProvider(
      readingProgressRepository: sl(),
      bookmarkRepository: sl(),
      catalogsProvider: sl(),
    ),
  );
}

/// Resets the service locator (useful for testing).
///
/// This will unregister all dependencies and clear the service locator.
Future<void> resetServiceLocator() async {
  await sl.reset();
}
