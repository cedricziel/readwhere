import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/screens/library/widgets/book_card.dart';

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

  group('BookCard', () {
    group('rendering', () {
      testWidgets('displays book title', (tester) async {
        final book = createTestBook(title: 'The Great Gatsby');

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Title appears twice: in placeholder cover and in card info section
        expect(find.text('The Great Gatsby'), findsAtLeast(1));
      });

      testWidgets('displays book author', (tester) async {
        final book = createTestBook(author: 'F. Scott Fitzgerald');

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.text('F. Scott Fitzgerald'), findsOneWidget);
      });

      testWidgets('shows placeholder cover when coverPath is null', (
        tester,
      ) async {
        final book = createTestBook(title: 'Test Book', coverPath: null);

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Placeholder shows book title in the cover area
        // Title appears twice: in cover placeholder and in card info section
        expect(find.text('Test Book'), findsNWidgets(2));
      });

      testWidgets('shows favorite icon when book is favorite', (tester) async {
        final book = createTestFavoriteBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('hides favorite icon when book is not favorite', (
        tester,
      ) async {
        final book = createTestBook(isFavorite: false);

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byIcon(Icons.favorite), findsNothing);
      });

      testWidgets('shows progress bar when readingProgress is set', (
        tester,
      ) async {
        final book = createTestBookWithProgress(progress: 0.5);

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('hides progress bar when readingProgress is null', (
        tester,
      ) async {
        final book = createTestBook(readingProgress: null);

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('is wrapped in Card widget', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has InkWell for tap feedback', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('calls onTap when card is tapped', (tester) async {
        var tapped = false;
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () => tapped = true)),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('shows context menu on long press', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Context menu is a ModalBottomSheet with ListTiles
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Add to Favorites'), findsOneWidget);
        expect(find.text('Book Details'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('context menu has Open option', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Open'), findsOneWidget);
        expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      });

      testWidgets(
        'context menu shows Remove from Favorites when book is favorite',
        (tester) async {
          final book = createTestFavoriteBook();

          await tester.pumpWidget(
            buildTestWidget(BookCard(book: book, onTap: () {})),
          );

          await tester.longPress(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(find.text('Remove from Favorites'), findsOneWidget);
        },
      );

      testWidgets(
        'context menu shows Add to Favorites when book is not favorite',
        (tester) async {
          final book = createTestBook(isFavorite: false);

          await tester.pumpWidget(
            buildTestWidget(BookCard(book: book, onTap: () {})),
          );

          await tester.longPress(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(find.text('Add to Favorites'), findsOneWidget);
        },
      );

      testWidgets('context menu has Book Details option', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Book Details'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('context menu has Delete option', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('context menu actions', () {
      testWidgets('Open option calls onTap and closes menu', (tester) async {
        var tapped = false;
        final book = createTestBook();

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () => tapped = true)),
        );

        // Open context menu
        await tester.longPress(find.byType(InkWell));
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
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(InkWell));
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
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Tap Book Details
        await tester.tap(find.text('Book Details'));
        await tester.pumpAndSettle();

        // Dialog should appear with book details
        // Note: AlertDialog.adaptive may render differently, so check for content
        expect(find.text('Format:'), findsOneWidget); // Unique to dialog
        expect(find.text('My Book'), findsAtLeast(1)); // Title in dialog
        expect(
          find.text('Test Author'),
          findsAtLeast(1),
        ); // Author may appear multiple times
        expect(find.text('EPUB'), findsOneWidget); // Format uppercase
      });

      testWidgets('Delete option shows confirmation dialog', (tester) async {
        final book = createTestBook(title: 'Book To Delete');

        await tester.pumpWidget(
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Open context menu
        await tester.longPress(find.byType(InkWell));
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
          buildTestWidget(BookCard(book: book, onTap: () {})),
        );

        // Open context menu and delete
        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Cancel deletion
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should NOT call deleteBook
        verifyNever(mockLibraryProvider.deleteBook(any));
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
                child: BookCard(book: book, onTap: () {}),
              ),
            ),
          ),
        );

        expect(find.byType(BookCard), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        final book = createTestBook();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ChangeNotifierProvider<LibraryProvider>.value(
                value: mockLibraryProvider,
                child: BookCard(book: book, onTap: () {}),
              ),
            ),
          ),
        );

        expect(find.byType(BookCard), findsOneWidget);
      });
    });
  });
}
