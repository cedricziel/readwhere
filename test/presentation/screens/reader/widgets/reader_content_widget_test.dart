import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/reader_provider.dart';
import 'package:readwhere/presentation/providers/audio_provider.dart';
import 'package:readwhere/presentation/screens/reader/widgets/reader_content.dart';

import '../../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockReaderProvider mockReaderProvider;
  late MockAudioProvider mockAudioProvider;

  setUp(() {
    mockReaderProvider = MockReaderProvider();
    mockAudioProvider = MockAudioProvider();

    // Setup default mock responses for ReaderProvider
    when(mockReaderProvider.hasOpenBook).thenReturn(true);
    when(mockReaderProvider.isLoading).thenReturn(false);
    when(
      mockReaderProvider.currentChapterHtml,
    ).thenReturn('<p>Test content</p>');
    when(mockReaderProvider.currentChapterCss).thenReturn('');
    when(mockReaderProvider.currentChapterIndex).thenReturn(0);
    when(mockReaderProvider.currentChapterImages).thenReturn({});
    when(mockReaderProvider.currentBook).thenReturn(null);

    // Setup default mock responses for AudioProvider
    when(mockAudioProvider.highlightedElementId).thenReturn(null);
  });

  Widget buildTestWidget({
    VoidCallback? onToggleControls,
    VoidCallback? onNextChapter,
    VoidCallback? onPreviousChapter,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<ReaderProvider>.value(
              value: mockReaderProvider,
            ),
            ChangeNotifierProvider<AudioProvider>.value(
              value: mockAudioProvider,
            ),
          ],
          child: ReaderContentWidget(
            scrollController: ScrollController(),
            onToggleControls: onToggleControls,
            onNextChapter: onNextChapter,
            onPreviousChapter: onPreviousChapter,
          ),
        ),
      ),
    );
  }

  /// Helper to perform a proper tap gesture at a relative X position
  /// This uses TestGesture to simulate pointer down/up events for the Listener widget
  Future<void> tapAtRelativeX(WidgetTester tester, double relativeX) async {
    // Find the Listener widget that is a descendant of ReaderContentWidget
    // This avoids finding Listeners from MaterialApp or Scaffold
    // Use .first because there are multiple Listeners (from ScrollView, etc.)
    // Our Listener is the outermost one with [down, up] listeners
    final readerContentFinder = find.byType(ReaderContentWidget);
    expect(readerContentFinder, findsOneWidget);

    final listenerFinder = find
        .descendant(of: readerContentFinder, matching: find.byType(Listener))
        .first;

    // Get the widget's render box to find its size and position
    final renderBox = tester.renderObject<RenderBox>(listenerFinder);
    final size = renderBox.size;
    final topLeft = renderBox.localToGlobal(Offset.zero);

    // Calculate tap position: relativeX (0.0-1.0) across the width
    final tapX = topLeft.dx + (size.width * relativeX);
    final tapY = topLeft.dy + (size.height / 2); // Center vertically
    final tapPosition = Offset(tapX, tapY);

    // Use TestGesture to simulate pointer down/up which triggers Listener's
    // onPointerDown and onPointerUp callbacks
    final gesture = await tester.startGesture(tapPosition);
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  group('ReaderContentWidget', () {
    group('tap zone navigation', () {
      testWidgets('tap on left third calls onPreviousChapter', (tester) async {
        var previousChapterCalled = false;
        var nextChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPreviousChapter: () => previousChapterCalled = true,
            onNextChapter: () => nextChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at 10% from left (left third)
        await tapAtRelativeX(tester, 0.10);

        expect(
          previousChapterCalled,
          isTrue,
          reason: 'Left third should call onPreviousChapter',
        );
        expect(nextChapterCalled, isFalse);
        expect(toggleControlsCalled, isFalse);
      });

      testWidgets('tap on right third calls onNextChapter', (tester) async {
        var previousChapterCalled = false;
        var nextChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPreviousChapter: () => previousChapterCalled = true,
            onNextChapter: () => nextChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at 90% from left (right third)
        await tapAtRelativeX(tester, 0.90);

        expect(previousChapterCalled, isFalse);
        expect(
          nextChapterCalled,
          isTrue,
          reason: 'Right third should call onNextChapter',
        );
        expect(toggleControlsCalled, isFalse);
      });

      testWidgets('tap on center third calls onToggleControls', (tester) async {
        var previousChapterCalled = false;
        var nextChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPreviousChapter: () => previousChapterCalled = true,
            onNextChapter: () => nextChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at 50% from left (center third)
        await tapAtRelativeX(tester, 0.50);

        expect(previousChapterCalled, isFalse);
        expect(nextChapterCalled, isFalse);
        expect(
          toggleControlsCalled,
          isTrue,
          reason: 'Center third should call onToggleControls',
        );
      });

      testWidgets('tap at boundary (just under 1/3) goes to previous', (
        tester,
      ) async {
        var previousChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPreviousChapter: () => previousChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at ~32% (just under 1/3)
        await tapAtRelativeX(tester, 0.32);

        expect(
          previousChapterCalled,
          isTrue,
          reason: 'Just under 1/3 should call onPreviousChapter',
        );
        expect(toggleControlsCalled, isFalse);
      });

      testWidgets('tap at boundary (just over 1/3) goes to controls', (
        tester,
      ) async {
        var previousChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPreviousChapter: () => previousChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at ~35% (just over 1/3)
        await tapAtRelativeX(tester, 0.35);

        expect(previousChapterCalled, isFalse);
        expect(
          toggleControlsCalled,
          isTrue,
          reason: 'Just over 1/3 should call onToggleControls',
        );
      });

      testWidgets('tap at boundary (just under 2/3) goes to controls', (
        tester,
      ) async {
        var nextChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onNextChapter: () => nextChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at ~65% (just under 2/3)
        await tapAtRelativeX(tester, 0.65);

        expect(
          toggleControlsCalled,
          isTrue,
          reason: 'Just under 2/3 should call onToggleControls',
        );
        expect(nextChapterCalled, isFalse);
      });

      testWidgets('tap at boundary (just over 2/3) goes to next', (
        tester,
      ) async {
        var nextChapterCalled = false;
        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            onNextChapter: () => nextChapterCalled = true,
            onToggleControls: () => toggleControlsCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap at ~68% (just over 2/3)
        await tapAtRelativeX(tester, 0.68);

        expect(
          nextChapterCalled,
          isTrue,
          reason: 'Just over 2/3 should call onNextChapter',
        );
        expect(toggleControlsCalled, isFalse);
      });
    });

    group('callback handling', () {
      testWidgets('handles null onPreviousChapter callback gracefully', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(onPreviousChapter: null));
        await tester.pumpAndSettle();

        // Tap on left third - should not throw
        await tapAtRelativeX(tester, 0.10);

        // No exception should be thrown
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles null onNextChapter callback gracefully', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(onNextChapter: null));
        await tester.pumpAndSettle();

        // Tap on right third - should not throw
        await tapAtRelativeX(tester, 0.90);

        // No exception should be thrown
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles null onToggleControls callback gracefully', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(onToggleControls: null));
        await tester.pumpAndSettle();

        // Tap on center - should not throw
        await tapAtRelativeX(tester, 0.50);

        // No exception should be thrown
        expect(tester.takeException(), isNull);
      });
    });

    group('loading state', () {
      testWidgets('shows placeholder when loading', (tester) async {
        when(mockReaderProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('No content available'), findsOneWidget);
        expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      });

      testWidgets('shows placeholder when no book is open', (tester) async {
        when(mockReaderProvider.hasOpenBook).thenReturn(false);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('No content available'), findsOneWidget);
      });
    });

    group('content rendering', () {
      testWidgets('renders HTML content when book is open', (tester) async {
        when(
          mockReaderProvider.currentChapterHtml,
        ).thenReturn('<p>Chapter content here</p>');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // The HTML widget should render the paragraph text
        expect(find.text('Chapter content here'), findsOneWidget);
      });

      testWidgets('taps work even with minimal HTML content', (tester) async {
        // Simulate minimal content like a copyright page with mostly boilerplate
        when(mockReaderProvider.currentChapterHtml).thenReturn(
          '<!DOCTYPE html><html><head><title>Copyright</title></head>'
          '<body><p>©</p></body></html>',
        );

        var toggleControlsCalled = false;

        await tester.pumpWidget(
          buildTestWidget(onToggleControls: () => toggleControlsCalled = true),
        );
        await tester.pumpAndSettle();

        // Tap center of screen - should still work due to SizedBox.expand
        await tapAtRelativeX(tester, 0.50);

        expect(
          toggleControlsCalled,
          isTrue,
          reason:
              'Tap should work even with minimal content (SizedBox.expand fix)',
        );
      });
    });
  });
}
