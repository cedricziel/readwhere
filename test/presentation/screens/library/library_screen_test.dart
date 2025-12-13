import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/screens/library/library_screen.dart';
import 'package:readwhere/presentation/screens/library/widgets/book_card.dart';
import 'package:readwhere/presentation/screens/library/widgets/book_list_tile.dart';
import 'package:readwhere/presentation/widgets/common/empty_state.dart';
import 'package:readwhere/presentation/widgets/common/loading_indicator.dart';

import '../../../helpers/test_helpers.dart';
import '../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockLibraryProvider mockLibraryProvider;

  setUp(() {
    mockLibraryProvider = MockLibraryProvider();

    // Default stubs
    when(mockLibraryProvider.isLoading).thenReturn(false);
    when(mockLibraryProvider.error).thenReturn(null);
    when(mockLibraryProvider.books).thenReturn([]);
    when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.grid);
    when(
      mockLibraryProvider.sortOrder,
    ).thenReturn(LibrarySortOrder.recentlyAdded);
    when(mockLibraryProvider.loadLibrary()).thenAnswer((_) async {});

    // Facet-related stubs
    when(mockLibraryProvider.selectedFacets).thenReturn({});
    when(mockLibraryProvider.hasFacetFilters).thenReturn(false);
    when(mockLibraryProvider.getAvailableFacetGroups()).thenReturn([]);
    when(mockLibraryProvider.bookCount).thenReturn(0);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<LibraryProvider>.value(
        value: mockLibraryProvider,
        child: const LibraryScreen(),
      ),
    );
  }

  group('LibraryScreen', () {
    group('loading state', () {
      testWidgets('shows loading indicator when loading with no books', (
        tester,
      ) async {
        when(mockLibraryProvider.isLoading).thenReturn(true);
        when(mockLibraryProvider.books).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.text('Loading your library...'), findsOneWidget);
      });

      testWidgets('does not show loading when already has books', (
        tester,
      ) async {
        when(mockLibraryProvider.isLoading).thenReturn(true);
        when(mockLibraryProvider.books).thenReturn([createTestBook()]);

        await tester.pumpWidget(buildTestWidget());

        // Should show books, not loading indicator
        expect(find.byType(LoadingIndicator), findsNothing);
      });
    });

    group('empty state', () {
      testWidgets('shows empty state when no books', (tester) async {
        when(mockLibraryProvider.books).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text('Your library is empty'), findsOneWidget);
        expect(find.text('Add books to start reading'), findsOneWidget);
      });

      testWidgets('empty state has Add Book button', (tester) async {
        when(mockLibraryProvider.books).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Add Book'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error state when error occurs', (tester) async {
        when(mockLibraryProvider.error).thenReturn('Failed to load library');

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Error Loading Library'), findsOneWidget);
        expect(find.text('Failed to load library'), findsOneWidget);
      });

      testWidgets('error state has retry button', (tester) async {
        when(mockLibraryProvider.error).thenReturn('Network error');

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button calls loadLibrary', (tester) async {
        when(mockLibraryProvider.error).thenReturn('Network error');

        await tester.pumpWidget(buildTestWidget());

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should call loadLibrary again (already called once in initState)
        verify(mockLibraryProvider.loadLibrary()).called(greaterThan(1));
      });
    });

    group('populated state', () {
      testWidgets('shows grid view when viewMode is grid', (tester) async {
        when(mockLibraryProvider.books).thenReturn([
          createTestBook(title: 'Book 1'),
          createTestBook(title: 'Book 2'),
        ]);
        when(mockLibraryProvider.bookCount).thenReturn(2);
        when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.grid);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(BookCard), findsNWidgets(2));
      });

      testWidgets('shows list view when viewMode is list', (tester) async {
        when(mockLibraryProvider.books).thenReturn([
          createTestBook(title: 'Book 1'),
          createTestBook(title: 'Book 2'),
        ]);
        when(mockLibraryProvider.bookCount).thenReturn(2);
        when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.list);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(BookListTile), findsNWidgets(2));
      });

      testWidgets('displays book titles', (tester) async {
        when(
          mockLibraryProvider.books,
        ).thenReturn([createTestBook(title: 'The Great Gatsby')]);
        when(mockLibraryProvider.bookCount).thenReturn(1);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('The Great Gatsby'), findsAtLeast(1));
      });
    });

    group('app bar', () {
      testWidgets('displays Library title by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Library'), findsOneWidget);
      });

      testWidgets('has search icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('has view mode toggle icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // In grid mode, shows list icon to switch to list view
        expect(find.byIcon(Icons.view_list), findsOneWidget);
      });

      testWidgets('has sort icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.sort), findsOneWidget);
      });

      testWidgets('search icon toggles search mode', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Tap search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        // Should show close icon and text field
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('view toggle changes icon based on mode', (tester) async {
        when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.list);

        await tester.pumpWidget(buildTestWidget());

        // In list mode, shows grid icon to switch to grid view
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });
    });

    group('view mode toggle', () {
      testWidgets('calls setViewMode when toggled from grid to list', (
        tester,
      ) async {
        when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.grid);

        await tester.pumpWidget(buildTestWidget());

        // Tap view toggle (shows list icon in grid mode)
        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pump();

        verify(mockLibraryProvider.setViewMode(LibraryViewMode.list)).called(1);
      });

      testWidgets('calls setViewMode when toggled from list to grid', (
        tester,
      ) async {
        when(mockLibraryProvider.viewMode).thenReturn(LibraryViewMode.list);

        await tester.pumpWidget(buildTestWidget());

        // Tap view toggle (shows grid icon in list mode)
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pump();

        verify(mockLibraryProvider.setViewMode(LibraryViewMode.grid)).called(1);
      });
    });

    group('sort menu', () {
      testWidgets('opens sort menu when sort icon tapped', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Tap sort icon
        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        // Should show sort options
        expect(find.text('Recently Added'), findsOneWidget);
        expect(find.text('Recently Opened'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Author'), findsOneWidget);
      });

      testWidgets('calls setSortOrder when option selected', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Open sort menu
        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        // Select Title sort
        await tester.tap(find.text('Title'));
        await tester.pumpAndSettle();

        verify(
          mockLibraryProvider.setSortOrder(LibrarySortOrder.title),
        ).called(1);
      });
    });

    group('search', () {
      testWidgets('shows search field when search icon tapped', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Tap search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search books...'), findsOneWidget);
      });

      testWidgets('calls search when text entered', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'gatsby');
        await tester.pump();

        verify(mockLibraryProvider.search('gatsby')).called(1);
      });

      testWidgets('calls clearSearch when search closed', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        // Close search
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        verify(mockLibraryProvider.clearSearch()).called(1);
      });
    });

    group('floating action button', () {
      testWidgets('has floating action button with add icon', (tester) async {
        // Give it some books so empty state doesn't show
        when(mockLibraryProvider.books).thenReturn([createTestBook()]);
        when(mockLibraryProvider.bookCount).thenReturn(1);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // Only the FAB should have add icon when not in empty state
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('refresh', () {
      testWidgets('supports pull to refresh when books present', (
        tester,
      ) async {
        when(mockLibraryProvider.books).thenReturn([createTestBook()]);
        when(mockLibraryProvider.bookCount).thenReturn(1);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('pull to refresh calls refreshAllMetadata', (tester) async {
        when(mockLibraryProvider.books).thenReturn([createTestBook()]);
        when(mockLibraryProvider.bookCount).thenReturn(1);
        when(
          mockLibraryProvider.refreshAllMetadata(
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => 1);

        await tester.pumpWidget(buildTestWidget());

        // Perform pull to refresh gesture on grid view
        await tester.fling(find.byType(GridView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        verify(
          mockLibraryProvider.refreshAllMetadata(
            onProgress: anyNamed('onProgress'),
          ),
        ).called(1);
      });

      testWidgets('pull to refresh shows snackbar with refresh count', (
        tester,
      ) async {
        when(
          mockLibraryProvider.books,
        ).thenReturn([createTestBook(), createTestBook(id: '2')]);
        when(mockLibraryProvider.bookCount).thenReturn(2);
        when(
          mockLibraryProvider.refreshAllMetadata(
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => 2);

        await tester.pumpWidget(buildTestWidget());

        // Perform pull to refresh
        await tester.fling(find.byType(GridView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        expect(
          find.text('Refreshed metadata for 2 of 2 books'),
          findsOneWidget,
        );
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: ChangeNotifierProvider<LibraryProvider>.value(
              value: mockLibraryProvider,
              child: const LibraryScreen(),
            ),
          ),
        );

        expect(find.byType(LibraryScreen), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ChangeNotifierProvider<LibraryProvider>.value(
              value: mockLibraryProvider,
              child: const LibraryScreen(),
            ),
          ),
        );

        expect(find.byType(LibraryScreen), findsOneWidget);
      });
    });
  });
}
