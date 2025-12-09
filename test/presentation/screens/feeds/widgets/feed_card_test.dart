import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/screens/feeds/widgets/feed_card.dart';

import '../../../../helpers/catalog_test_helpers.dart';

void main() {
  group('FeedCard', () {
    group('rendering', () {
      testWidgets('displays feed name', (tester) async {
        final feed = createTestRssFeed(name: 'My Awesome Feed');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.text('My Awesome Feed'), findsOneWidget);
      });

      testWidgets('displays formatted URL without protocol', (tester) async {
        final feed = createTestRssFeed(url: 'https://example.com/feed.xml');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        // URL should be formatted without https://
        expect(find.text('example.com/feed.xml'), findsOneWidget);
      });

      testWidgets('displays RSS icon', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byIcon(Icons.rss_feed), findsOneWidget);
      });

      testWidgets('displays last accessed time when set', (tester) async {
        final feed = createTestRssFeed(
          lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.textContaining('Last viewed:'), findsOneWidget);
        expect(find.textContaining('2 hours ago'), findsOneWidget);
      });

      testWidgets('does not display last accessed when null', (tester) async {
        final feed = createTestRssFeed(lastAccessedAt: null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.textContaining('Last viewed:'), findsNothing);
      });

      testWidgets('displays "Just now" for very recent access', (tester) async {
        final feed = createTestRssFeed(
          lastAccessedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.textContaining('Just now'), findsOneWidget);
      });

      testWidgets('displays days ago for older access', (tester) async {
        final feed = createTestRssFeed(
          lastAccessedAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.textContaining('3 days ago'), findsOneWidget);
      });

      testWidgets('displays singular "day" for 1 day ago', (tester) async {
        final feed = createTestRssFeed(
          lastAccessedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.textContaining('1 day ago'), findsOneWidget);
      });

      testWidgets('has Card widget', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has more options menu button', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when card is tapped', (tester) async {
        var tapped = false;
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(
                feed: feed,
                onTap: () => tapped = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('shows popup menu when more button is tapped', (
        tester,
      ) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        // Tap the more options button
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Check menu item appears
        expect(find.text('Unsubscribe'), findsOneWidget);
      });

      testWidgets('calls onDelete when Unsubscribe is selected', (
        tester,
      ) async {
        var deleted = false;
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(
                feed: feed,
                onTap: () {},
                onDelete: () => deleted = true,
              ),
            ),
          ),
        );

        // Open menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap Unsubscribe
        await tester.tap(find.text('Unsubscribe'));
        await tester.pumpAndSettle();

        expect(deleted, isTrue);
      });

      testWidgets('menu shows delete icon', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        // Open menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('URL formatting', () {
      testWidgets('removes https:// from URL', (tester) async {
        final feed = createTestRssFeed(url: 'https://example.com/feed');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.text('example.com/feed'), findsOneWidget);
        expect(find.text('https://example.com/feed'), findsNothing);
      });

      testWidgets('removes http:// from URL', (tester) async {
        final feed = createTestRssFeed(url: 'http://example.com/feed');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.text('example.com/feed'), findsOneWidget);
      });

      testWidgets('removes trailing slash from URL', (tester) async {
        final feed = createTestRssFeed(url: 'https://example.com/feed/');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.text('example.com/feed'), findsOneWidget);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byType(FeedCard), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        final feed = createTestRssFeed();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: FeedCard(feed: feed, onTap: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byType(FeedCard), findsOneWidget);
      });
    });
  });
}
