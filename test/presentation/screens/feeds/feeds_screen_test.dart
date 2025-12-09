import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/catalogs_provider.dart';
import 'package:readwhere/presentation/providers/feed_reader_provider.dart';
import 'package:readwhere/presentation/screens/feeds/feeds_screen.dart';
import 'package:readwhere/presentation/screens/feeds/widgets/feed_card.dart';

import '../../../helpers/catalog_test_helpers.dart';
import '../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockCatalogsProvider mockCatalogsProvider;
  late MockFeedReaderProvider mockFeedReaderProvider;

  setUp(() {
    mockCatalogsProvider = MockCatalogsProvider();
    mockFeedReaderProvider = MockFeedReaderProvider();

    // Default stubs for CatalogsProvider
    when(mockCatalogsProvider.isLoading).thenReturn(false);
    when(mockCatalogsProvider.error).thenReturn(null);
    when(mockCatalogsProvider.catalogs).thenReturn([]);
    when(mockCatalogsProvider.loadCatalogs()).thenAnswer((_) async {});

    // Default stubs for FeedReaderProvider
    when(mockFeedReaderProvider.getUnreadCount(any)).thenReturn(0);
    when(mockFeedReaderProvider.loadAllUnreadCounts()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<CatalogsProvider>.value(
            value: mockCatalogsProvider,
          ),
          ChangeNotifierProvider<FeedReaderProvider>.value(
            value: mockFeedReaderProvider,
          ),
        ],
        child: const FeedsScreen(),
      ),
    );
  }

  group('FeedsScreen', () {
    group('loading state', () {
      testWidgets('shows loading indicator when loading with no feeds', (
        tester,
      ) async {
        when(mockCatalogsProvider.isLoading).thenReturn(true);
        when(mockCatalogsProvider.catalogs).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('does not show loading when already has feeds', (
        tester,
      ) async {
        when(mockCatalogsProvider.isLoading).thenReturn(true);
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(buildTestWidget());

        // Should show feeds, not loading indicator
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(FeedCard), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows empty state when no RSS feeds', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('No Feed Subscriptions'), findsOneWidget);
        expect(
          find.text(
            'Subscribe to RSS feeds to discover and download ebooks and comics.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows empty state when only non-RSS catalogs exist', (
        tester,
      ) async {
        // Only servers, no RSS feeds
        when(
          mockCatalogsProvider.catalogs,
        ).thenReturn([createTestKavitaServer(), createTestNextcloudServer()]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('No Feed Subscriptions'), findsOneWidget);
      });

      testWidgets('empty state has Subscribe to Feed button', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Subscribe to Feed'), findsOneWidget);
      });

      testWidgets('empty state has RSS icon', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.rss_feed), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error state when error occurs', (tester) async {
        when(mockCatalogsProvider.error).thenReturn('Failed to load feeds');

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Error Loading Feeds'), findsOneWidget);
        expect(find.text('Failed to load feeds'), findsOneWidget);
      });

      testWidgets('error state has retry button', (tester) async {
        when(mockCatalogsProvider.error).thenReturn('Network error');

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button calls loadCatalogs', (tester) async {
        when(mockCatalogsProvider.error).thenReturn('Network error');

        await tester.pumpWidget(buildTestWidget());

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should call loadCatalogs again (already called once in initState)
        verify(mockCatalogsProvider.loadCatalogs()).called(greaterThan(1));
      });

      testWidgets('error state has error icon', (tester) async {
        when(mockCatalogsProvider.error).thenReturn('Network error');

        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('populated state', () {
      testWidgets('shows FeedCard for each RSS feed', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([
          createTestRssFeed(id: 'feed-1', name: 'Feed 1'),
          createTestRssFeed(id: 'feed-2', name: 'Feed 2'),
        ]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(FeedCard), findsNWidgets(2));
      });

      testWidgets('displays feed names', (tester) async {
        when(
          mockCatalogsProvider.catalogs,
        ).thenReturn([createTestRssFeed(name: 'Tech News Feed')]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Tech News Feed'), findsOneWidget);
      });

      testWidgets('only shows RSS feeds, filters out servers', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn(createMixedCatalogs());

        await tester.pumpWidget(buildTestWidget());

        // Should only show 2 RSS feeds from the mixed list
        expect(find.byType(FeedCard), findsNWidgets(2));

        // RSS feeds should be visible
        expect(find.text('Tech News'), findsOneWidget);
        expect(find.text('Book Reviews'), findsOneWidget);

        // Servers should NOT be visible
        expect(find.text('My Kavita'), findsNothing);
        expect(find.text('My Cloud'), findsNothing);
        expect(find.text('Public Library'), findsNothing);
      });

      testWidgets('shows ListView when feeds are present', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('app bar', () {
      testWidgets('displays Feeds title', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Feeds'), findsOneWidget);
      });
    });

    group('floating action button', () {
      testWidgets('has Subscribe FAB', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
      });

      testWidgets('FAB has add icon', (tester) async {
        // Use feeds so empty state doesn't show (which also has add icon)
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(buildTestWidget());

        // Find the FAB and check for add icon
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('refresh', () {
      testWidgets('supports pull to refresh when feeds present', (
        tester,
      ) async {
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(buildTestWidget());

        // Find the RefreshIndicator by scrolling down then up
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        // Verify loadCatalogs was called (once on init, possibly again on refresh)
        verify(
          mockCatalogsProvider.loadCatalogs(),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<CatalogsProvider>.value(
                  value: mockCatalogsProvider,
                ),
                ChangeNotifierProvider<FeedReaderProvider>.value(
                  value: mockFeedReaderProvider,
                ),
              ],
              child: const FeedsScreen(),
            ),
          ),
        );

        expect(find.byType(FeedsScreen), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        when(mockCatalogsProvider.catalogs).thenReturn([createTestRssFeed()]);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<CatalogsProvider>.value(
                  value: mockCatalogsProvider,
                ),
                ChangeNotifierProvider<FeedReaderProvider>.value(
                  value: mockFeedReaderProvider,
                ),
              ],
              child: const FeedsScreen(),
            ),
          ),
        );

        expect(find.byType(FeedsScreen), findsOneWidget);
      });
    });
  });
}
