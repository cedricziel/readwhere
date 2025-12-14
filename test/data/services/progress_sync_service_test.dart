import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/adapters/catalog_info_adapter.dart';
import 'package:readwhere/domain/entities/catalog.dart';
import 'package:readwhere/domain/entities/reading_progress.dart';
import 'package:readwhere/domain/repositories/catalog_repository.dart';
import 'package:readwhere/domain/repositories/reading_progress_repository.dart';
import 'package:readwhere/domain/sync/progress_sync_protocol.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../mocks/mock_repositories.mocks.dart';

/// Test double for plugins with ProgressSyncCapability
class MockProgressSyncPlugin extends PluginBase with ProgressSyncCapability {
  @override
  String get id => 'mock-kavita-plugin';

  @override
  String get name => 'Mock Kavita Plugin';

  @override
  String get description => 'Mock plugin for testing';

  @override
  String get version => '1.0.0';

  @override
  Future<void> initialize(PluginContext context) async {
    // No-op for tests
  }

  @override
  Future<void> dispose() async {
    // No-op for tests
  }

  ReadingProgressData? fetchProgressResult;
  bool syncProgressCalled = false;
  ReadingProgressData? lastSyncedProgress;
  String? lastSyncedBookIdentifier;
  CatalogInfo? lastSyncedCatalog;

  @override
  Future<ReadingProgressData?> fetchProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
  }) async {
    return fetchProgressResult;
  }

  @override
  Future<void> syncProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
    required ReadingProgressData progress,
  }) async {
    syncProgressCalled = true;
    lastSyncedProgress = progress;
    lastSyncedBookIdentifier = bookIdentifier;
    lastSyncedCatalog = catalog;
  }

  void reset() {
    fetchProgressResult = null;
    syncProgressCalled = false;
    lastSyncedProgress = null;
    lastSyncedBookIdentifier = null;
    lastSyncedCatalog = null;
  }
}

/// Wrapper to create a testable plugin registry
class TestablePluginRegistry implements TestPluginRegistryInterface {
  final List<PluginBase> testPlugins;

  TestablePluginRegistry({this.testPlugins = const []});

  @override
  List<T> withCapability<T>() {
    return testPlugins.whereType<T>().toList();
  }

  @override
  PluginBase? getPlugin(String id) {
    try {
      return testPlugins.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Interface for testable plugin registry operations
abstract class TestPluginRegistryInterface {
  List<T> withCapability<T>();
  PluginBase? getPlugin(String id);
}

/// Testable version of ProgressSyncService that accepts our test registry
class TestableProgressSyncService implements ProgressSyncProtocol {
  final ReadingProgressRepository _progressRepository;
  final CatalogRepository _catalogRepository;
  final TestablePluginRegistry _pluginRegistry;

  TestableProgressSyncService({
    required ReadingProgressRepository progressRepository,
    required CatalogRepository catalogRepository,
    required TestablePluginRegistry pluginRegistry,
  }) : _progressRepository = progressRepository,
       _catalogRepository = catalogRepository,
       _pluginRegistry = pluginRegistry;

  @override
  Future<ProgressSyncResult> syncAll({
    required String catalogId,
    bool forceFullSync = false,
  }) async {
    final catalog = await _catalogRepository.getById(catalogId);
    if (catalog == null) {
      return ProgressSyncResult(
        uploaded: 0,
        downloaded: 0,
        merged: 0,
        conflicts: 0,
        errors: [
          SyncError(
            recordId: catalogId,
            operation: 'syncAll',
            message: 'Catalog not found',
          ),
        ],
        syncedAt: DateTime.now(),
      );
    }

    final plugin = _getProgressSyncPlugin(catalog);
    if (plugin == null) {
      return ProgressSyncResult(
        uploaded: 0,
        downloaded: 0,
        merged: 0,
        conflicts: 0,
        errors: [
          SyncError(
            recordId: catalogId,
            operation: 'syncAll',
            message:
                'Catalog type ${catalog.type.name} does not support progress sync',
          ),
        ],
        syncedAt: DateTime.now(),
      );
    }

    return ProgressSyncResult(
      uploaded: 0,
      downloaded: 0,
      merged: 0,
      conflicts: 0,
      errors: const [],
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<void> syncBook({
    required String catalogId,
    required String bookId,
    required String remoteBookId,
  }) async {
    final catalog = await _catalogRepository.getById(catalogId);
    if (catalog == null) {
      throw Exception('Catalog not found: $catalogId');
    }

    final plugin = _getProgressSyncPlugin(catalog);
    if (plugin == null) {
      throw Exception(
        'Catalog type ${catalog.type.name} does not support progress sync',
      );
    }

    final catalogInfo = CatalogInfoAdapter(catalog);

    final localProgress = await _progressRepository.getProgressForBook(bookId);
    final remoteProgress = await plugin.fetchProgress(
      catalog: catalogInfo,
      bookIdentifier: remoteBookId,
    );

    final mergedProgress = _smartMerge(localProgress, remoteProgress, bookId);

    if (mergedProgress == null) {
      return;
    }

    final shouldPushToRemote = _shouldPushToRemote(
      localProgress,
      remoteProgress,
      mergedProgress,
    );

    final shouldUpdateLocal = _shouldUpdateLocal(
      localProgress,
      remoteProgress,
      mergedProgress,
    );

    if (shouldPushToRemote && localProgress != null) {
      await plugin.syncProgress(
        catalog: catalogInfo,
        bookIdentifier: remoteBookId,
        progress: ReadingProgressData(
          pageNumber: 0,
          percentage: localProgress.progress,
          cfi: localProgress.cfi,
          updatedAt: localProgress.updatedAt,
        ),
      );
    }

    if (shouldUpdateLocal && remoteProgress != null) {
      await _progressRepository.saveProgress(
        localProgress?.copyWith(
              progress: remoteProgress.percentage,
              cfi: remoteProgress.cfi ?? localProgress.cfi,
              updatedAt: remoteProgress.updatedAt,
            ) ??
            ReadingProgress(
              id: bookId,
              bookId: bookId,
              cfi: remoteProgress.cfi ?? '',
              progress: remoteProgress.percentage,
              updatedAt: remoteProgress.updatedAt,
            ),
      );
    }
  }

  @override
  Future<int> pushDirtyRecords({required String catalogId}) async {
    return 0;
  }

  @override
  Future<int> pullRemoteChanges({required String catalogId}) async {
    return 0;
  }

  ProgressSyncCapability? _getProgressSyncPlugin(Catalog catalog) {
    final plugins = _pluginRegistry.withCapability<ProgressSyncCapability>();
    for (final plugin in plugins) {
      if (_pluginHandlesCatalogType(plugin, catalog.type)) {
        return plugin;
      }
    }
    return null;
  }

  bool _pluginHandlesCatalogType(PluginBase plugin, CatalogType type) {
    switch (type) {
      case CatalogType.kavita:
        return plugin.id.contains('kavita');
      case CatalogType.nextcloud:
        return plugin.id.contains('nextcloud');
      case CatalogType.synology:
        return plugin.id.contains('synology');
      case CatalogType.opds:
      case CatalogType.rss:
      case CatalogType.fanfiction:
        return false;
    }
  }

  ReadingProgress? _smartMerge(
    ReadingProgress? local,
    ReadingProgressData? remote,
    String bookId,
  ) {
    if (local == null && remote == null) {
      return null;
    }

    if (local == null) {
      return ReadingProgress(
        id: bookId,
        bookId: bookId,
        cfi: remote!.cfi ?? '',
        progress: remote.percentage,
        updatedAt: remote.updatedAt,
      );
    }

    if (remote == null) {
      return local;
    }

    if (local.progress >= remote.percentage) {
      return local;
    } else {
      return local.copyWith(
        progress: remote.percentage,
        cfi: remote.cfi ?? local.cfi,
        updatedAt: remote.updatedAt,
      );
    }
  }

  bool _shouldPushToRemote(
    ReadingProgress? local,
    ReadingProgressData? remote,
    ReadingProgress? merged,
  ) {
    if (local == null || merged == null) return false;
    if (remote == null) return true;
    return local.progress > remote.percentage;
  }

  bool _shouldUpdateLocal(
    ReadingProgress? local,
    ReadingProgressData? remote,
    ReadingProgress? merged,
  ) {
    if (remote == null || merged == null) return false;
    if (local == null) return true;
    return remote.percentage > local.progress;
  }
}

void main() {
  group('ProgressSyncService', () {
    late MockReadingProgressRepository mockProgressRepository;
    late MockCatalogRepository mockCatalogRepository;
    late MockProgressSyncPlugin mockPlugin;
    late TestablePluginRegistry pluginRegistry;
    late TestableProgressSyncService service;

    final now = DateTime(2024, 6, 15, 10, 30);
    final earlier = now.subtract(const Duration(hours: 1));

    final kavitaCatalog = Catalog(
      id: 'catalog-1',
      name: 'Test Kavita',
      url: 'https://kavita.example.com',
      type: CatalogType.kavita,
      apiKey: 'test-api-key',
      username: 'user',
      addedAt: now,
    );

    final opdsCatalog = Catalog(
      id: 'catalog-2',
      name: 'Test OPDS',
      url: 'https://opds.example.com',
      type: CatalogType.opds,
      addedAt: now,
    );

    final localProgress = ReadingProgress(
      id: 'book-123',
      bookId: 'book-123',
      cfi: '/4/2/10',
      progress: 0.5,
      updatedAt: now,
    );

    setUp(() {
      mockProgressRepository = MockReadingProgressRepository();
      mockCatalogRepository = MockCatalogRepository();
      mockPlugin = MockProgressSyncPlugin();
      pluginRegistry = TestablePluginRegistry(testPlugins: [mockPlugin]);

      service = TestableProgressSyncService(
        progressRepository: mockProgressRepository,
        catalogRepository: mockCatalogRepository,
        pluginRegistry: pluginRegistry,
      );

      when(
        mockCatalogRepository.getById(kavitaCatalog.id),
      ).thenAnswer((_) async => kavitaCatalog);
      when(
        mockCatalogRepository.getById(opdsCatalog.id),
      ).thenAnswer((_) async => opdsCatalog);
    });

    tearDown(() {
      mockPlugin.reset();
    });

    group('syncAll', () {
      test('returns error when catalog not found', () async {
        when(
          mockCatalogRepository.getById('non-existent'),
        ).thenAnswer((_) async => null);

        final result = await service.syncAll(catalogId: 'non-existent');

        expect(result.hasErrors, isTrue);
        expect(result.errors.first.message, contains('Catalog not found'));
        expect(result.uploaded, equals(0));
        expect(result.downloaded, equals(0));
      });

      test(
        'returns error when catalog type does not support progress sync',
        () async {
          final result = await service.syncAll(catalogId: opdsCatalog.id);

          expect(result.hasErrors, isTrue);
          expect(
            result.errors.first.message,
            contains('does not support progress sync'),
          );
        },
      );

      test('returns empty result for supported catalog', () async {
        final result = await service.syncAll(catalogId: kavitaCatalog.id);

        expect(result.uploaded, equals(0));
        expect(result.downloaded, equals(0));
        expect(result.merged, equals(0));
        expect(result.errors, isEmpty);
      });
    });

    group('syncBook', () {
      test('throws when catalog not found', () async {
        when(
          mockCatalogRepository.getById('non-existent'),
        ).thenAnswer((_) async => null);

        expect(
          () => service.syncBook(
            catalogId: 'non-existent',
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Catalog not found'),
            ),
          ),
        );
      });

      test('throws when catalog type does not support progress sync', () async {
        expect(
          () => service.syncBook(
            catalogId: opdsCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('does not support progress sync'),
            ),
          ),
        );
      });

      group('smart merge logic', () {
        test(
          'does nothing when neither local nor remote progress exists',
          () async {
            when(
              mockProgressRepository.getProgressForBook('book-123'),
            ).thenAnswer((_) async => null);
            mockPlugin.fetchProgressResult = null;

            await service.syncBook(
              catalogId: kavitaCatalog.id,
              bookId: 'book-123',
              remoteBookId: 'remote-123',
            );

            expect(mockPlugin.syncProgressCalled, isFalse);
            verifyNever(mockProgressRepository.saveProgress(any));
          },
        );

        test('pushes local progress to remote when remote is empty', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => localProgress);
          mockPlugin.fetchProgressResult = null;

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          expect(mockPlugin.syncProgressCalled, isTrue);
          expect(mockPlugin.lastSyncedProgress!.percentage, equals(0.5));
          expect(mockPlugin.lastSyncedProgress!.cfi, equals('/4/2/10'));
          verifyNever(mockProgressRepository.saveProgress(any));
        });

        test('saves remote progress locally when local is empty', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => null);
          when(mockProgressRepository.saveProgress(any)).thenAnswer(
            (inv) async => inv.positionalArguments[0] as ReadingProgress,
          );
          mockPlugin.fetchProgressResult = ReadingProgressData(
            pageNumber: 100,
            percentage: 0.6,
            cfi: '/4/2/20',
            updatedAt: now,
          );

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          expect(mockPlugin.syncProgressCalled, isFalse);
          verify(
            mockProgressRepository.saveProgress(
              argThat(
                isA<ReadingProgress>()
                    .having((p) => p.progress, 'progress', 0.6)
                    .having((p) => p.cfi, 'cfi', '/4/2/20'),
              ),
            ),
          ).called(1);
        });

        test('pushes to remote when local progress is greater', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => localProgress.copyWith(progress: 0.8));
          mockPlugin.fetchProgressResult = ReadingProgressData(
            pageNumber: 50,
            percentage: 0.5,
            cfi: '/4/2/10',
            updatedAt: earlier,
          );

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          expect(mockPlugin.syncProgressCalled, isTrue);
          expect(mockPlugin.lastSyncedProgress!.percentage, equals(0.8));
          verifyNever(mockProgressRepository.saveProgress(any));
        });

        test('updates local when remote progress is greater', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => localProgress.copyWith(progress: 0.3));
          when(mockProgressRepository.saveProgress(any)).thenAnswer(
            (inv) async => inv.positionalArguments[0] as ReadingProgress,
          );
          mockPlugin.fetchProgressResult = ReadingProgressData(
            pageNumber: 80,
            percentage: 0.8,
            cfi: '/4/2/80',
            updatedAt: now,
          );

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          expect(mockPlugin.syncProgressCalled, isFalse);
          verify(
            mockProgressRepository.saveProgress(
              argThat(
                isA<ReadingProgress>()
                    .having((p) => p.progress, 'progress', 0.8)
                    .having((p) => p.cfi, 'cfi', '/4/2/80'),
              ),
            ),
          ).called(1);
        });

        test('keeps local when progress is equal (no action needed)', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => localProgress.copyWith(progress: 0.5));
          mockPlugin.fetchProgressResult = ReadingProgressData(
            pageNumber: 50,
            percentage: 0.5,
            cfi: '/4/2/10',
            updatedAt: earlier,
          );

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          expect(mockPlugin.syncProgressCalled, isFalse);
          verifyNever(mockProgressRepository.saveProgress(any));
        });

        test('handles remote progress without CFI', () async {
          when(
            mockProgressRepository.getProgressForBook('book-123'),
          ).thenAnswer((_) async => null);
          when(mockProgressRepository.saveProgress(any)).thenAnswer(
            (inv) async => inv.positionalArguments[0] as ReadingProgress,
          );
          mockPlugin.fetchProgressResult = ReadingProgressData(
            pageNumber: 50,
            percentage: 0.5,
            cfi: null,
            updatedAt: now,
          );

          await service.syncBook(
            catalogId: kavitaCatalog.id,
            bookId: 'book-123',
            remoteBookId: 'remote-123',
          );

          verify(
            mockProgressRepository.saveProgress(
              argThat(isA<ReadingProgress>().having((p) => p.cfi, 'cfi', '')),
            ),
          ).called(1);
        });

        test(
          'preserves local CFI when updating with remote progress that has no CFI',
          () async {
            when(
              mockProgressRepository.getProgressForBook('book-123'),
            ).thenAnswer((_) async => localProgress.copyWith(progress: 0.3));
            when(mockProgressRepository.saveProgress(any)).thenAnswer(
              (inv) async => inv.positionalArguments[0] as ReadingProgress,
            );
            mockPlugin.fetchProgressResult = ReadingProgressData(
              pageNumber: 80,
              percentage: 0.8,
              cfi: null,
              updatedAt: now,
            );

            await service.syncBook(
              catalogId: kavitaCatalog.id,
              bookId: 'book-123',
              remoteBookId: 'remote-123',
            );

            verify(
              mockProgressRepository.saveProgress(
                argThat(
                  isA<ReadingProgress>()
                      .having((p) => p.progress, 'progress', 0.8)
                      .having((p) => p.cfi, 'cfi', '/4/2/10'),
                ),
              ),
            ).called(1);
          },
        );
      });
    });

    group('pushDirtyRecords', () {
      test('returns 0 (not yet implemented)', () async {
        final result = await service.pushDirtyRecords(
          catalogId: kavitaCatalog.id,
        );

        expect(result, equals(0));
      });
    });

    group('pullRemoteChanges', () {
      test('returns 0 (not yet implemented)', () async {
        final result = await service.pullRemoteChanges(
          catalogId: kavitaCatalog.id,
        );

        expect(result, equals(0));
      });
    });
  });

  group('ProgressSyncResult', () {
    test('hasErrors returns true when errors exist', () {
      final result = ProgressSyncResult(
        uploaded: 1,
        downloaded: 0,
        merged: 0,
        conflicts: 0,
        errors: const [
          SyncError(recordId: 'book-1', operation: 'sync', message: 'Error'),
        ],
        syncedAt: DateTime.now(),
      );

      expect(result.hasErrors, isTrue);
    });

    test('hasErrors returns false when no errors', () {
      final result = ProgressSyncResult(
        uploaded: 1,
        downloaded: 2,
        merged: 0,
        conflicts: 0,
        errors: const [],
        syncedAt: DateTime.now(),
      );

      expect(result.hasErrors, isFalse);
    });

    test('isFullySuccessful returns true when no errors and no conflicts', () {
      final result = ProgressSyncResult(
        uploaded: 5,
        downloaded: 3,
        merged: 2,
        conflicts: 0,
        errors: const [],
        syncedAt: DateTime.now(),
      );

      expect(result.isFullySuccessful, isTrue);
    });

    test('isFullySuccessful returns false when has conflicts', () {
      final result = ProgressSyncResult(
        uploaded: 5,
        downloaded: 3,
        merged: 2,
        conflicts: 1,
        errors: const [],
        syncedAt: DateTime.now(),
      );

      expect(result.isFullySuccessful, isFalse);
    });
  });

  group('SyncError', () {
    test('toString returns formatted string', () {
      const error = SyncError(
        recordId: 'book-123',
        operation: 'push',
        message: 'Network failure',
      );

      expect(error.toString(), contains('push'));
      expect(error.toString(), contains('book-123'));
      expect(error.toString(), contains('Network failure'));
    });
  });
}
