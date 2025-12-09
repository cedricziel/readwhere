import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/screens/library/widgets/book_list_tile.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockLibraryProvider mockLibraryProvider;

  setUp(() {
    mockLibraryProvider = MockLibraryProvider();
  });

  Widget buildTestWidget(Widget child, {MockLibraryProvider? provider}) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<LibraryProvider>.value(
          value: provider ?? mockLibraryProvider,
          child: child,
        ),
      ),
    );
  }

  group('BookListTile', () {
    group('rendering', () {
      testWidgets('displays book title', (tester) async {
        final book = createTestBook(title: 'The Great Gatsby');

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Title appears in info section and possibly in placeholder cover
        expect(find.text('The Great Gatsby'), findsAtLeast(1));
      });

      testWidgets('displays book author', (tester) async {
        final book = createTestBook(author: 'F. Scott Fitzgerald');

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.text('F. Scott Fitzgerald'), findsOneWidget);
      });

      testWidgets('displays book format in uppercase', (tester) async {
        final book = createTestBook(format: 'epub');

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.text('EPUB'), findsOneWidget);
      });

      testWidgets('shows placeholder cover when coverPath is null', (
        tester,
      ) async {
        final book = createTestBook(title: 'Test Book', coverPath: null);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Placeholder shows book title in the cover area
        // Title appears twice: in cover placeholder and in info section
        expect(find.text('Test Book'), findsNWidgets(2));
      });

      testWidgets('shows favorite icon when book is favorite', (tester) async {
        final book = createTestFavoriteBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('hides favorite icon when book is not favorite', (
        tester,
      ) async {
        final book = createTestBook(isFavorite: false);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Should not find the favorite icon (only the unfilled one in context menu)
        expect(find.byIcon(Icons.favorite), findsNothing);
      });

      testWidgets('shows progress bar when readingProgress is set', (
        tester,
      ) async {
        final book = createTestBookWithProgress(progress: 0.5);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows progress percentage when readingProgress is set', (
        tester,
      ) async {
        final book = createTestBookWithProgress(progress: 0.5);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.text('50%'), findsOneWidget);
      });

      testWidgets('hides progress bar when readingProgress is null', (
        tester,
      ) async {
        final book = createTestBook(readingProgress: null);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('is wrapped in Card widget', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has InkWell for tap feedback', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // There's an InkWell for the tile and one for the IconButton
        expect(find.byType(InkWell), findsAtLeast(1));
      });

      testWidgets('has more options button', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('displays last read date when lastOpenedAt is set', (
        tester,
      ) async {
        final book = createTestBook(lastOpenedAt: DateTime(2024, 1, 15));

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.textContaining('Last read:'), findsOneWidget);
      });

      testWidgets('hides last read date when lastOpenedAt is null', (
        tester,
      ) async {
        final book = createTestBook(lastOpenedAt: null);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        expect(find.textContaining('Last read:'), findsNothing);
      });
    });

    group('interaction', () {
      testWidgets('calls onTap when tile is tapped', (tester) async {
        var tapped = false;
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () => tapped = true)),
        );

        // Tap on the BookListTile directly
        await tester.tap(find.byType(BookListTile));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('shows context menu on long press', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Long press on the BookListTile
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();

        // Context menu is a ModalBottomSheet with ListTiles
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Add to Favorites'), findsOneWidget);
        expect(find.text('Book Details'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('shows context menu when more options button tapped', (
        tester,
      ) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Context menu should appear
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Book Details'), findsOneWidget);
      });

      testWidgets(
        'context menu shows Remove from Favorites when book is favorite',
        (tester) async {
          final book = createTestFavoriteBook();

          await tester.pumpWidget(
            buildTestWidget(BookListTile(book: book, onTap: () {})),
          );

          await tester.longPress(find.byType(BookListTile));
          await tester.pumpAndSettle();

          expect(find.text('Remove from Favorites'), findsOneWidget);
        },
      );

      testWidgets(
        'context menu shows Add to Favorites when book is not favorite',
        (tester) async {
          final book = createTestBook(isFavorite: false);

          await tester.pumpWidget(
            buildTestWidget(BookListTile(book: book, onTap: () {})),
          );

          await tester.longPress(find.byType(BookListTile));
          await tester.pumpAndSettle();

          expect(find.text('Add to Favorites'), findsOneWidget);
        },
      );
    });

    group('context menu actions', () {
      testWidgets('Open option calls onTap and closes menu', (tester) async {
        var tapped = false;
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () => tapped = true)),
        );

        // Open context menu
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();

        // Tap Open
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
        // Menu should be closed
        expect(find.text('Book Details'), findsNothing);
      });

      testWidgets('Favorite option calls toggleFavorite', (tester) async {
        final book = createTestBook(id: 'book-123', isFavorite: false);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();

        // Tap Add to Favorites
        await tester.tap(find.text('Add to Favorites'));
        await tester.pumpAndSettle();

        verify(mockLibraryProvider.toggleFavorite('book-123')).called(1);
      });

      testWidgets('Book Details opens dialog with book info', (tester) async {
        final book = createTestBook(
          title: 'My Book',
          author: 'Test Author',
          format: 'epub',
        );

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();

        // Tap Book Details
        await tester.tap(find.text('Book Details'));
        await tester.pumpAndSettle();

        // AlertDialog should appear with book details
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('My Book'), findsAtLeast(1));
        expect(find.text('Test Author'), findsAtLeast(1));
        // EPUB appears in both the tile's format chip and the dialog
        expect(find.text('EPUB'), findsAtLeast(1));
      });

      testWidgets('Delete option shows confirmation dialog', (tester) async {
        final book = createTestBook(title: 'Book To Delete');

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();

        // Tap Delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.text('Delete Book'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to delete "Book To Delete"? This action cannot be undone.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('Delete confirmation Cancel does not delete', (tester) async {
        final book = createTestBook(id: 'book-to-delete');

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Open context menu and delete
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Cancel deletion
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should NOT call deleteBook
        verifyNever(mockLibraryProvider.deleteBook(any));
      });

      testWidgets('Delete confirmation Delete calls deleteBook', (
        tester,
      ) async {
        final book = createTestBook(id: 'book-to-delete', title: 'My Book');

        // Stub deleteBook to return a future
        when(mockLibraryProvider.deleteBook(any)).thenAnswer((_) async => true);

        await tester.pumpWidget(
          buildTestWidget(BookListTile(book: book, onTap: () {})),
        );

        // Open context menu and delete
        await tester.longPress(find.byType(BookListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        verify(mockLibraryProvider.deleteBook('book-to-delete')).called(1);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ChangeNotifierProvider<LibraryProvider>.value(
                value: mockLibraryProvider,
                child: BookListTile(book: book, onTap: () {}),
              ),
            ),
          ),
        );

        expect(find.byType(BookListTile), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ChangeNotifierProvider<LibraryProvider>.value(
                value: mockLibraryProvider,
                child: BookListTile(book: book, onTap: () {}),
              ),
            ),
          ),
        );

        expect(find.byType(BookListTile), findsOneWidget);
      });
    });
  });
}
