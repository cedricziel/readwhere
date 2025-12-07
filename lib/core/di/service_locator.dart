import 'package:get_it/get_it.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/reading_progress_repository_impl.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/services/book_import_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
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
  sl.registerLazySingletonAsync<DatabaseHelper>(
    () async {
      final dbHelper = DatabaseHelper();
      await dbHelper.database; // Ensure database is initialized
      return dbHelper;
    },
  );

  // Wait for DatabaseHelper to be ready before registering repositories
  await sl.isReady<DatabaseHelper>();

  // Repositories
  sl.registerLazySingleton<BookRepository>(
    () => BookRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ReadingProgressRepository>(
    () => ReadingProgressRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<BookImportService>(
    () => BookImportService(),
  );

  // Providers
  sl.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(),
  );

  sl.registerLazySingleton<SettingsProvider>(
    () => SettingsProvider(),
  );

  sl.registerLazySingleton<LibraryProvider>(
    () => LibraryProvider(
      bookRepository: sl(),
      importService: sl(),
    ),
  );

  sl.registerLazySingleton<ReaderProvider>(
    () => ReaderProvider(
      readingProgressRepository: sl(),
      bookmarkRepository: sl(),
    ),
  );
}

/// Resets the service locator (useful for testing).
///
/// This will unregister all dependencies and clear the service locator.
Future<void> resetServiceLocator() async {
  await sl.reset();
}
