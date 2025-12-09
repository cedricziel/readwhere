import 'package:mockito/annotations.dart';
import 'package:readwhere/domain/repositories/book_repository.dart';
import 'package:readwhere/domain/repositories/bookmark_repository.dart';
import 'package:readwhere/domain/repositories/reading_progress_repository.dart';
import 'package:readwhere/data/database/database_helper.dart';
import 'package:readwhere/data/services/book_import_service.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([
  BookRepository,
  BookmarkRepository,
  ReadingProgressRepository,
  DatabaseHelper,
  BookImportService,
  ReaderPlugin,
  ReaderController,
  Database,
])
void main() {}
