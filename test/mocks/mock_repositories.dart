import 'package:mockito/annotations.dart';
import 'package:readwhere/domain/repositories/book_repository.dart';
import 'package:readwhere/domain/repositories/bookmark_repository.dart';
import 'package:readwhere/domain/repositories/reading_progress_repository.dart';
import 'package:readwhere/domain/repositories/catalog_repository.dart';
import 'package:readwhere/data/database/database_helper.dart';
import 'package:readwhere/data/services/book_import_service.dart';
import 'package:readwhere/data/services/opds_cache_service.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:readwhere/presentation/providers/catalogs_provider.dart';
import 'package:readwhere/presentation/providers/update_provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([
  // Repositories
  BookRepository,
  BookmarkRepository,
  ReadingProgressRepository,
  CatalogRepository,
  // Database
  DatabaseHelper,
  Database,
  // Services
  BookImportService,
  OpdsCacheService,
  // Plugins
  ReaderPlugin,
  ReaderController,
  // OPDS/Kavita
  OpdsClient,
  KavitaApiClient,
  // Providers (for UI tests)
  LibraryProvider,
  SettingsProvider,
  CatalogsProvider,
  UpdateProvider,
])
void main() {}
