import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

void main() {
  group('ReadingLocation', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('creates reading location with all fields', () {
        final location = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        expect(location.chapterIndex, equals(5));
        expect(location.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(location.progress, equals(0.75));
        expect(location.timestamp, equals(testTimestamp));
      });

      test('creates reading location with null cfi', () {
        final location = ReadingLocation(
          chapterIndex: 0,
          progress: 0.0,
          timestamp: testTimestamp,
        );

        expect(location.cfi, isNull);
      });

      test('creates reading location with zero progress', () {
        final location = ReadingLocation(
          chapterIndex: 0,
          progress: 0.0,
          timestamp: testTimestamp,
        );

        expect(location.progress, equals(0.0));
      });

      test('creates reading location with full progress', () {
        final location = ReadingLocation(
          chapterIndex: 10,
          progress: 1.0,
          timestamp: testTimestamp,
        );

        expect(location.progress, equals(1.0));
      });

      test('throws assertion error for progress below 0', () {
        expect(
          () => ReadingLocation(
            chapterIndex: 0,
            progress: -0.1,
            timestamp: testTimestamp,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for progress above 1', () {
        expect(
          () => ReadingLocation(
            chapterIndex: 0,
            progress: 1.1,
            timestamp: testTimestamp,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('copyWith', () {
      test('copies with all new values', () {
        final original = ReadingLocation(
          chapterIndex: 5,
          cfi: 'original-cfi',
          progress: 0.5,
          timestamp: testTimestamp,
        );

        final newTimestamp = DateTime(2024, 2, 20);
        final copied = original.copyWith(
          chapterIndex: 10,
          cfi: 'new-cfi',
          progress: 0.8,
          timestamp: newTimestamp,
        );

        expect(copied.chapterIndex, equals(10));
        expect(copied.cfi, equals('new-cfi'));
        expect(copied.progress, equals(0.8));
        expect(copied.timestamp, equals(newTimestamp));
      });

      test('preserves original values when not specified', () {
        final original = ReadingLocation(
          chapterIndex: 5,
          cfi: 'original-cfi',
          progress: 0.5,
          timestamp: testTimestamp,
        );

        final copied = original.copyWith();

        expect(copied.chapterIndex, equals(original.chapterIndex));
        expect(copied.cfi, equals(original.cfi));
        expect(copied.progress, equals(original.progress));
        expect(copied.timestamp, equals(original.timestamp));
      });

      test('copies with partial new values', () {
        final original = ReadingLocation(
          chapterIndex: 5,
          cfi: 'original-cfi',
          progress: 0.5,
          timestamp: testTimestamp,
        );

        final copied = original.copyWith(progress: 0.9);

        expect(copied.chapterIndex, equals(original.chapterIndex));
        expect(copied.cfi, equals(original.cfi));
        expect(copied.progress, equals(0.9));
        expect(copied.timestamp, equals(original.timestamp));
      });
    });

    group('equatable', () {
      test('two locations with same values are equal', () {
        final location1 = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        final location2 = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        expect(location1, equals(location2));
      });

      test('two locations with different values are not equal', () {
        final location1 = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        final location2 = ReadingLocation(
          chapterIndex: 6,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        expect(location1, isNot(equals(location2)));
      });

      test('props includes all fields', () {
        final location = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        expect(location.props, contains(5));
        expect(location.props, contains('epubcfi(/6/4!/4/2/1:0)'));
        expect(location.props, contains(0.75));
        expect(location.props, contains(testTimestamp));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final location = ReadingLocation(
          chapterIndex: 5,
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          timestamp: testTimestamp,
        );

        final str = location.toString();

        expect(str, contains('ReadingLocation'));
        expect(str, contains('chapter: 5'));
        expect(str, contains('cfi: epubcfi(/6/4!/4/2/1:0)'));
        expect(str, contains('progress: 0.75'));
      });

      test('formats progress with two decimal places', () {
        final location = ReadingLocation(
          chapterIndex: 0,
          progress: 0.123456789,
          timestamp: testTimestamp,
        );

        expect(location.toString(), contains('progress: 0.12'));
      });

      test('handles null cfi in string', () {
        final location = ReadingLocation(
          chapterIndex: 0,
          progress: 0.5,
          timestamp: testTimestamp,
        );

        expect(location.toString(), contains('cfi: null'));
      });
    });
  });
}
