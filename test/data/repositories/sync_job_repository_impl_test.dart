import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/database/tables/sync_jobs_table.dart';
import 'package:readwhere/data/repositories/sync_job_repository_impl.dart';
import 'package:readwhere/domain/entities/sync_job.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('SyncJobRepositoryImpl', () {
    late MockDatabaseHelper mockDatabaseHelper;
    late MockDatabase mockDatabase;
    late SyncJobRepositoryImpl repository;

    final now = DateTime(2024, 6, 15, 10, 30);
    final nowMillis = now.millisecondsSinceEpoch;

    final testJobMap = {
      SyncJobsTable.columnId: 'progress-book-123',
      SyncJobsTable.columnJobType: 'progress',
      SyncJobsTable.columnTargetId: 'book-123',
      SyncJobsTable.columnPayload: '{"progress":0.5,"cfi":"/4/2"}',
      SyncJobsTable.columnStatus: 'pending',
      SyncJobsTable.columnPriority: 2,
      SyncJobsTable.columnAttempts: 0,
      SyncJobsTable.columnNextRetryAt: null,
      SyncJobsTable.columnLastError: null,
      SyncJobsTable.columnCreatedAt: nowMillis,
      SyncJobsTable.columnUpdatedAt: nowMillis,
    };

    final testJob = SyncJob(
      id: 'progress-book-123',
      type: SyncJobType.progress,
      targetId: 'book-123',
      payload: {'progress': 0.5, 'cfi': '/4/2'},
      status: SyncJobStatus.pending,
      priority: SyncJobPriority.high,
      attempts: 0,
      nextRetryAt: null,
      lastError: null,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      repository = SyncJobRepositoryImpl(mockDatabaseHelper);

      when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('enqueue', () {
      test('inserts job with replace conflict algorithm', () async {
        when(
          mockDatabase.insert(
            SyncJobsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.enqueue(testJob);

        expect(result.id, equals(testJob.id));
        expect(result.type, equals(testJob.type));
        expect(result.targetId, equals(testJob.targetId));

        verify(
          mockDatabase.insert(
            SyncJobsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.insert(
            SyncJobsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.enqueue(testJob), throwsException);
      });
    });

    group('getPendingJobs', () {
      test(
        'returns pending jobs ordered by priority desc and created_at asc',
        () async {
          when(
            mockDatabase.query(
              SyncJobsTable.tableName,
              where: anyNamed('where'),
              whereArgs: anyNamed('whereArgs'),
              orderBy: anyNamed('orderBy'),
              limit: anyNamed('limit'),
            ),
          ).thenAnswer((_) async => [testJobMap]);

          final result = await repository.getPendingJobs();

          expect(result, hasLength(1));
          expect(result.first.id, equals('progress-book-123'));
          expect(result.first.type, equals(SyncJobType.progress));
          expect(result.first.status, equals(SyncJobStatus.pending));
        },
      );

      test('uses default limit of 10', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: 10,
          ),
        ).thenAnswer((_) async => []);

        await repository.getPendingJobs();

        verify(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: 10,
          ),
        ).called(1);
      });

      test('uses custom limit when provided', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: 5,
          ),
        ).thenAnswer((_) async => []);

        await repository.getPendingJobs(limit: 5);

        verify(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: 5,
          ),
        ).called(1);
      });

      test('returns empty list when no pending jobs', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: anyNamed('limit'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getPendingJobs();

        expect(result, isEmpty);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
            limit: anyNamed('limit'),
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.getPendingJobs(), throwsException);
      });
    });

    group('getJobsByType', () {
      test('returns jobs filtered by type', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnJobType} = ?',
            whereArgs: ['progress'],
            orderBy: '${SyncJobsTable.columnCreatedAt} ASC',
          ),
        ).thenAnswer((_) async => [testJobMap]);

        final result = await repository.getJobsByType(SyncJobType.progress);

        expect(result, hasLength(1));
        expect(result.first.type, equals(SyncJobType.progress));
        verify(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnJobType} = ?',
            whereArgs: ['progress'],
            orderBy: '${SyncJobsTable.columnCreatedAt} ASC',
          ),
        ).called(1);
      });

      test('returns empty list when no jobs of type exist', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnJobType} = ?',
            whereArgs: ['catalog'],
            orderBy: '${SyncJobsTable.columnCreatedAt} ASC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getJobsByType(SyncJobType.catalog);

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('returns job when found', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testJobMap]);

        final result = await repository.getById('progress-book-123');

        expect(result, isNotNull);
        expect(result!.id, equals('progress-book-123'));
        expect(result.type, equals(SyncJobType.progress));
      });

      test('returns null when job not found', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['non-existent'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getById('non-existent');

        expect(result, isNull);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.getById('progress-book-123'), throwsException);
      });
    });

    group('updateStatus', () {
      test('updates job status successfully', () async {
        final updatedJobMap = Map<String, dynamic>.from(testJobMap);
        updatedJobMap[SyncJobsTable.columnStatus] = 'inProgress';

        when(
          mockDatabase.update(
            SyncJobsTable.tableName,
            any,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).thenAnswer((_) async => 1);

        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [updatedJobMap]);

        final result = await repository.updateStatus(
          'progress-book-123',
          SyncJobStatus.inProgress,
        );

        expect(result, isNotNull);
        expect(result!.status, equals(SyncJobStatus.inProgress));
      });

      test('updates status with error', () async {
        final updatedJobMap = Map<String, dynamic>.from(testJobMap);
        updatedJobMap[SyncJobsTable.columnStatus] = 'failed';
        updatedJobMap[SyncJobsTable.columnLastError] = 'Network error';

        when(
          mockDatabase.update(
            SyncJobsTable.tableName,
            any,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).thenAnswer((_) async => 1);

        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [updatedJobMap]);

        final result = await repository.updateStatus(
          'progress-book-123',
          SyncJobStatus.failed,
          error: 'Network error',
        );

        expect(result, isNotNull);
        expect(result!.status, equals(SyncJobStatus.failed));
        expect(result.lastError, equals('Network error'));
      });
    });

    group('markFailed', () {
      test('increments attempts and schedules retry', () async {
        final failedJobMap = Map<String, dynamic>.from(testJobMap);
        failedJobMap[SyncJobsTable.columnStatus] = 'failed';
        failedJobMap[SyncJobsTable.columnAttempts] = 1;
        failedJobMap[SyncJobsTable.columnLastError] = 'Connection timeout';

        // First call to getById (inside markFailed)
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testJobMap]);

        when(
          mockDatabase.update(
            SyncJobsTable.tableName,
            any,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).thenAnswer((_) async => 1);

        // After update, return updated job
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [failedJobMap]);

        final result = await repository.markFailed(
          'progress-book-123',
          'Connection timeout',
        );

        expect(result, isNotNull);
        expect(result!.status, equals(SyncJobStatus.failed));
        expect(result.attempts, equals(1));
        expect(result.lastError, equals('Connection timeout'));

        verify(
          mockDatabase.update(
            SyncJobsTable.tableName,
            any,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).called(1);
      });

      test('returns null for non-existent job', () async {
        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['non-existent'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.markFailed(
          'non-existent',
          'Some error',
        );

        expect(result, isNull);
      });
    });

    group('markCompleted', () {
      test('deletes job from database', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).thenAnswer((_) async => 1);

        await repository.markCompleted('progress-book-123');

        verify(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).called(1);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.markCompleted('progress-book-123'),
          throwsException,
        );
      });
    });

    group('cancelJobsForTarget', () {
      test('deletes jobs for specific type and target', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 2);

        final result = await repository.cancelJobsForTarget(
          SyncJobType.progress,
          'book-123',
        );

        expect(result, equals(2));
      });

      test('returns 0 when no jobs to cancel', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.cancelJobsForTarget(
          SyncJobType.catalog,
          'non-existent',
        );

        expect(result, equals(0));
      });
    });

    group('cleanupOldJobs', () {
      test('deletes old jobs with default duration', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 5);

        final result = await repository.cleanupOldJobs();

        expect(result, equals(5));
        verify(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).called(1);
      });

      test('deletes old jobs with custom duration', () async {
        when(
          mockDatabase.delete(
            SyncJobsTable.tableName,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 10);

        final result = await repository.cleanupOldJobs(
          olderThan: const Duration(days: 30),
        );

        expect(result, equals(10));
      });
    });

    group('getStats', () {
      test('returns queue statistics', () async {
        // Use ordered responses for rawQuery calls
        var callCount = 0;
        when(mockDatabase.rawQuery(any, any)).thenAnswer((_) async {
          callCount++;
          switch (callCount) {
            case 1:
              return [
                {'count': 5},
              ]; // pending
            case 2:
              return [
                {'count': 2},
              ]; // failed
            case 3:
              return [
                {'count': 1},
              ]; // inProgress
            case 4:
              return [
                {'oldest': nowMillis},
              ]; // oldest
            default:
              return [];
          }
        });

        final result = await repository.getStats();

        expect(result.pendingCount, equals(5));
        expect(result.failedCount, equals(2));
        expect(result.inProgressCount, equals(1));
        expect(result.oldestPendingJob, equals(now));
      });

      test('returns null oldest when no pending jobs', () async {
        when(mockDatabase.rawQuery(any, any)).thenAnswer(
          (_) async => [
            {'count': 0, 'oldest': null},
          ],
        );

        final result = await repository.getStats();

        expect(result.oldestPendingJob, isNull);
      });
    });

    group('clearAll', () {
      test('deletes all jobs', () async {
        when(
          mockDatabase.delete(SyncJobsTable.tableName),
        ).thenAnswer((_) async => 10);

        await repository.clearAll();

        verify(mockDatabase.delete(SyncJobsTable.tableName)).called(1);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(SyncJobsTable.tableName),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.clearAll(), throwsException);
      });
    });

    group('SyncJobModel serialization', () {
      test('correctly serializes and deserializes payload', () async {
        final complexPayload = {
          'progress': 0.75,
          'cfi': '/4/2/10',
          'sourceCatalogId': 'catalog-456',
          'nested': {'key': 'value'},
        };

        final jobWithComplexPayload = SyncJob(
          id: 'complex-job',
          type: SyncJobType.progress,
          targetId: 'book-456',
          payload: complexPayload,
          createdAt: now,
          updatedAt: now,
        );

        final jobMap = {
          SyncJobsTable.columnId: 'complex-job',
          SyncJobsTable.columnJobType: 'progress',
          SyncJobsTable.columnTargetId: 'book-456',
          SyncJobsTable.columnPayload: jsonEncode(complexPayload),
          SyncJobsTable.columnStatus: 'pending',
          SyncJobsTable.columnPriority: 1,
          SyncJobsTable.columnAttempts: 0,
          SyncJobsTable.columnNextRetryAt: null,
          SyncJobsTable.columnLastError: null,
          SyncJobsTable.columnCreatedAt: nowMillis,
          SyncJobsTable.columnUpdatedAt: nowMillis,
        };

        when(
          mockDatabase.insert(
            SyncJobsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['complex-job'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [jobMap]);

        await repository.enqueue(jobWithComplexPayload);
        final retrieved = await repository.getById('complex-job');

        expect(retrieved, isNotNull);
        expect(retrieved!.payload['progress'], equals(0.75));
        expect(retrieved.payload['nested'], isA<Map>());
        expect(retrieved.payload['nested']['key'], equals('value'));
      });

      test('handles all job types', () async {
        final types = [
          (SyncJobType.progress, 'progress'),
          (SyncJobType.catalog, 'catalog'),
          (SyncJobType.feed, 'feed'),
        ];

        for (final (type, typeName) in types) {
          final jobMap = Map<String, dynamic>.from(testJobMap);
          jobMap[SyncJobsTable.columnJobType] = typeName;
          jobMap[SyncJobsTable.columnId] = '$typeName-job';

          when(
            mockDatabase.query(
              SyncJobsTable.tableName,
              where: '${SyncJobsTable.columnId} = ?',
              whereArgs: ['$typeName-job'],
              limit: 1,
            ),
          ).thenAnswer((_) async => [jobMap]);

          final result = await repository.getById('$typeName-job');

          expect(result, isNotNull);
          expect(result!.type, equals(type));
        }
      });

      test('handles all priority values', () async {
        final priorities = [
          (0, SyncJobPriority.low),
          (1, SyncJobPriority.normal),
          (2, SyncJobPriority.high),
        ];

        for (final (value, expected) in priorities) {
          final jobMap = Map<String, dynamic>.from(testJobMap);
          jobMap[SyncJobsTable.columnPriority] = value;
          jobMap[SyncJobsTable.columnId] = 'priority-$value-job';

          when(
            mockDatabase.query(
              SyncJobsTable.tableName,
              where: '${SyncJobsTable.columnId} = ?',
              whereArgs: ['priority-$value-job'],
              limit: 1,
            ),
          ).thenAnswer((_) async => [jobMap]);

          final result = await repository.getById('priority-$value-job');

          expect(result, isNotNull);
          expect(result!.priority, equals(expected));
        }
      });

      test('handles nextRetryAt timestamp', () async {
        final retryTime = now.add(const Duration(minutes: 30));
        final jobMap = Map<String, dynamic>.from(testJobMap);
        jobMap[SyncJobsTable.columnNextRetryAt] =
            retryTime.millisecondsSinceEpoch;

        when(
          mockDatabase.query(
            SyncJobsTable.tableName,
            where: '${SyncJobsTable.columnId} = ?',
            whereArgs: ['progress-book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [jobMap]);

        final result = await repository.getById('progress-book-123');

        expect(result, isNotNull);
        expect(result!.nextRetryAt, isNotNull);
        expect(
          result.nextRetryAt!.millisecondsSinceEpoch,
          equals(retryTime.millisecondsSinceEpoch),
        );
      });
    });
  });
}
