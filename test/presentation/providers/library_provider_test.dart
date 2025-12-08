import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('LibraryProvider', () {
    late MockBookRepository mockBookRepository;
    late MockBookImportService mockImportService;
    late LibraryProvider provider;

    final testAddedAt = DateTime(2024, 1, 15, 10, 30);
    final testLastOpenedAt = DateTime(2024, 1, 20, 15, 45);

    final testBook1 = Book(
      id: 'book-1',
      title: 'Book One',
      author: 'Author A',
      filePath: '/path/to/book1.epub',
      coverPath: '/path/to/cover1.jpg',
      format: 'epub',
      fileSize: 1024000,
      addedAt: testAddedAt,
      lastOpenedAt: testLastOpenedAt,
      isFavorite: false,
    );

    final testBook2 = Book(
      id: 'book-2',
      title: 'Book Two',
      author: 'Author B',
      filePath: '/path/to/book2.epub',
      coverPath: '/path/to/cover2.jpg',
      format: 'epub',
      fileSize: 2048000,
      addedAt: testAddedAt.add(const Duration(days: 1)),
      lastOpenedAt: null,
      isFavorite: true,
    );

    setUp(() {
      mockBookRepository = MockBookRepository();
      mockImportService = MockBookImportService();
      provider = LibraryProvider(
        bookRepository: mockBookRepository,
        importService: mockImportService,
      );
    });

    group('initial state', () {
      test('has empty books list', () {
        expect(provider.books, isEmpty);
      });

      test('is not loading', () {
        expect(provider.isLoading, isFalse);
      });

      test('has no error', () {
        expect(provider.error, isNull);
      });

      test('has default sort order', () {
        expect(provider.sortOrder, equals(LibrarySortOrder.recentlyAdded));
      });

      test('has default view mode', () {
        expect(provider.viewMode, equals(LibraryViewMode.grid));
      });

      test('has empty search query', () {
        expect(provider.searchQuery, isEmpty);
      });

      test('has zero book count', () {
        expect(provider.bookCount, equals(0));
      });

      test('has zero favorite count', () {
        expect(provider.favoriteCount, equals(0));
      });
    });

    group('loadBooks', () {
      test('loads books from repository', () async {
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [testBook1, testBook2]);

        await provider.loadBooks();

        expect(provider.books, hasLength(2));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during load', () async {
        when(mockBookRepository.getAll()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return [testBook1];
        });

        final future = provider.loadBooks();
        expect(provider.isLoading, isTrue);
        await future;
        expect(provider.isLoading, isFalse);
      });

      test('handles empty library', () async {
        when(mockBookRepository.getAll()).thenAnswer((_) async => []);

        await provider.loadBooks();

        expect(provider.books, isEmpty);
        expect(provider.error, isNull);
      });

      test('handles repository error', () async {
        when(
          mockBookRepository.getAll(),
        ).thenThrow(Exception('Database error'));

        await provider.loadBooks();

        expect(provider.books, isEmpty);
        expect(provider.error, contains('Failed to load books'));
        expect(provider.isLoading, isFalse);
      });

      test('updates book count after load', () async {
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [testBook1, testBook2]);

        await provider.loadBooks();

        expect(provider.bookCount, equals(2));
      });

      test('updates favorite count after load', () async {
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [testBook1, testBook2]);

        await provider.loadBooks();

        expect(provider.favoriteCount, equals(1)); // testBook2 is favorite
      });
    });

    group('loadLibrary', () {
      test('is alias for loadBooks', () async {
        when(mockBookRepository.getAll()).thenAnswer((_) async => [testBook1]);

        await provider.loadLibrary();

        expect(provider.books, hasLength(1));
        verify(mockBookRepository.getAll()).called(1);
      });
    });

    group('importBook', () {
      test('imports book and returns it', () async {
        when(
          mockImportService.importBook('/path/to/new.epub'),
        ).thenAnswer((_) async => testBook1);
        when(
          mockBookRepository.insert(testBook1),
        ).thenAnswer((_) async => testBook1);
        when(mockBookRepository.getAll()).thenAnswer((_) async => [testBook1]);

        final result = await provider.importBook('/path/to/new.epub');

        expect(result, equals(testBook1));
        verify(mockImportService.importBook('/path/to/new.epub')).called(1);
        verify(mockBookRepository.insert(testBook1)).called(1);
      });

      test('sets loading state during import', () async {
        when(mockImportService.importBook(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return testBook1;
        });
        when(mockBookRepository.insert(any)).thenAnswer((_) async => testBook1);
        when(mockBookRepository.getAll()).thenAnswer((_) async => [testBook1]);

        final future = provider.importBook('/path/to/new.epub');
        expect(provider.isLoading, isTrue);
        await future;
        expect(provider.isLoading, isFalse);
      });

      test('returns null on import error', () async {
        when(
          mockImportService.importBook(any),
        ).thenThrow(Exception('Invalid file'));

        final result = await provider.importBook('/path/to/invalid.epub');

        expect(result, isNull);
        expect(provider.error, contains('Failed to import book'));
      });
    });

    group('deleteBook', () {
      test('deletes book from repository and local list', () async {
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [testBook1, testBook2]);
        when(mockBookRepository.delete('book-1')).thenAnswer((_) async => true);

        await provider.loadBooks();
        final result = await provider.deleteBook('book-1');

        expect(result, isTrue);
        expect(provider.books, hasLength(1));
        expect(provider.books.first.id, equals('book-2'));
      });

      test('returns false when book not found', () async {
        when(
          mockBookRepository.delete('non-existent'),
        ).thenAnswer((_) async => false);

        final result = await provider.deleteBook('non-existent');

        expect(result, isFalse);
      });

      test('handles delete error', () async {
        when(
          mockBookRepository.delete(any),
        ).thenThrow(Exception('Delete failed'));

        final result = await provider.deleteBook('book-1');

        expect(result, isFalse);
        expect(provider.error, contains('Failed to delete book'));
      });
    });

    group('toggleFavorite', () {
      test('toggles favorite status', () async {
        final updatedBook = testBook1.copyWith(isFavorite: true);
        when(mockBookRepository.getAll()).thenAnswer((_) async => [testBook1]);
        when(
          mockBookRepository.toggleFavorite('book-1'),
        ).thenAnswer((_) async => updatedBook);

        await provider.loadBooks();
        await provider.toggleFavorite('book-1');

        expect(provider.books.first.isFavorite, isTrue);
      });

      test('handles toggle error', () async {
        when(mockBookRepository.getAll()).thenAnswer((_) async => [testBook1]);
        when(
          mockBookRepository.toggleFavorite('book-1'),
        ).thenThrow(Exception('Toggle failed'));

        await provider.loadBooks();
        await provider.toggleFavorite('book-1');

        expect(provider.error, contains('Failed to toggle favorite'));
      });
    });

    group('setSortOrder', () {
      test('changes sort order', () {
        provider.setSortOrder(LibrarySortOrder.title);

        expect(provider.sortOrder, equals(LibrarySortOrder.title));
      });

      test('does not notify if same order', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setSortOrder(LibrarySortOrder.recentlyAdded);

        expect(notifyCount, equals(0));
      });

      test('sorts by title alphabetically', () async {
        final bookZ = testBook1.copyWith(id: 'z', title: 'Zebra Book');
        final bookA = testBook2.copyWith(id: 'a', title: 'Alpha Book');
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [bookZ, bookA]);

        await provider.loadBooks();
        provider.setSortOrder(LibrarySortOrder.title);

        expect(provider.books.first.title, equals('Alpha Book'));
        expect(provider.books.last.title, equals('Zebra Book'));
      });

      test('sorts by author alphabetically', () async {
        final bookZ = testBook1.copyWith(id: 'z', author: 'Zack');
        final bookA = testBook2.copyWith(id: 'a', author: 'Alice');
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [bookZ, bookA]);

        await provider.loadBooks();
        provider.setSortOrder(LibrarySortOrder.author);

        expect(provider.books.first.author, equals('Alice'));
        expect(provider.books.last.author, equals('Zack'));
      });

      test('sorts by recently added', () async {
        final olderBook = testBook1.copyWith(
          id: 'old',
          addedAt: DateTime(2024, 1, 1),
        );
        final newerBook = testBook2.copyWith(
          id: 'new',
          addedAt: DateTime(2024, 1, 15),
        );
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [olderBook, newerBook]);

        await provider.loadBooks();
        provider.setSortOrder(LibrarySortOrder.recentlyAdded);

        expect(provider.books.first.id, equals('new'));
      });

      test('sorts by recently opened', () async {
        final olderOpened = testBook1.copyWith(
          id: 'old',
          lastOpenedAt: DateTime(2024, 1, 1),
        );
        final newerOpened = testBook2.copyWith(
          id: 'new',
          lastOpenedAt: DateTime(2024, 1, 15),
        );
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [olderOpened, newerOpened]);

        await provider.loadBooks();
        provider.setSortOrder(LibrarySortOrder.recentlyOpened);

        expect(provider.books.first.id, equals('new'));
      });
    });

    group('setViewMode', () {
      test('changes view mode', () {
        provider.setViewMode(LibraryViewMode.list);

        expect(provider.viewMode, equals(LibraryViewMode.list));
      });

      test('does not notify if same mode', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setViewMode(LibraryViewMode.grid);

        expect(notifyCount, equals(0));
      });
    });

    group('searchBooks', () {
      test('searches books by title', () async {
        when(
          mockBookRepository.search('One'),
        ).thenAnswer((_) async => [testBook1]);

        await provider.searchBooks('One');

        expect(provider.books, hasLength(1));
        expect(provider.books.first.title, equals('Book One'));
        expect(provider.searchQuery, equals('One'));
      });

      test('clears filtered books on empty query', () async {
        when(
          mockBookRepository.search('One'),
        ).thenAnswer((_) async => [testBook1]);

        await provider.searchBooks('One');
        await provider.searchBooks('');

        expect(provider.searchQuery, isEmpty);
      });

      test('handles search error', () async {
        when(
          mockBookRepository.search(any),
        ).thenThrow(Exception('Search failed'));

        await provider.searchBooks('test');

        expect(provider.error, contains('Search failed'));
      });
    });

    group('search', () {
      test('is alias for searchBooks', () async {
        when(
          mockBookRepository.search('test'),
        ).thenAnswer((_) async => [testBook1]);

        await provider.search('test');

        verify(mockBookRepository.search('test')).called(1);
      });
    });

    group('clearSearch', () {
      test('clears search query and filtered books', () async {
        when(
          mockBookRepository.search('One'),
        ).thenAnswer((_) async => [testBook1]);

        await provider.searchBooks('One');
        provider.clearSearch();

        expect(provider.searchQuery, isEmpty);
      });
    });

    group('getFilteredBooks', () {
      test('returns same as books getter', () async {
        when(
          mockBookRepository.getAll(),
        ).thenAnswer((_) async => [testBook1, testBook2]);

        await provider.loadBooks();

        expect(provider.getFilteredBooks(), equals(provider.books));
      });
    });

    group('enums', () {
      test('LibrarySortOrder has correct values', () {
        expect(LibrarySortOrder.values, hasLength(4));
        expect(
          LibrarySortOrder.values,
          contains(LibrarySortOrder.recentlyAdded),
        );
        expect(
          LibrarySortOrder.values,
          contains(LibrarySortOrder.recentlyOpened),
        );
        expect(LibrarySortOrder.values, contains(LibrarySortOrder.title));
        expect(LibrarySortOrder.values, contains(LibrarySortOrder.author));
      });

      test('LibraryViewMode has correct values', () {
        expect(LibraryViewMode.values, hasLength(2));
        expect(LibraryViewMode.values, contains(LibraryViewMode.grid));
        expect(LibraryViewMode.values, contains(LibraryViewMode.list));
      });
    });
  });
}
