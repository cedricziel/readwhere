import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere/domain/entities/reading_settings.dart';
import 'package:readwhere/presentation/providers/audio_provider.dart';
import 'package:readwhere/presentation/providers/library_provider.dart';
import 'package:readwhere/presentation/providers/reader_provider.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:readwhere/presentation/screens/reader/reader_screen.dart';
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';

import '../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockReaderProvider mockReaderProvider;
  late MockAudioProvider mockAudioProvider;
  late MockLibraryProvider mockLibraryProvider;
  late MockSettingsProvider mockSettingsProvider;

  final testBook = Book(
    id: 'test-book-id',
    title: 'Test Book',
    author: 'Test Author',
    filePath: '/path/to/book.epub',
    format: 'epub',
    fileSize: 1000,
    addedAt: DateTime.now(),
  );

  setUp(() {
    mockReaderProvider = MockReaderProvider();
    mockAudioProvider = MockAudioProvider();
    mockLibraryProvider = MockLibraryProvider();
    mockSettingsProvider = MockSettingsProvider();

    // Setup default mock responses for ReaderProvider
    when(mockReaderProvider.hasOpenBook).thenReturn(true);
    when(mockReaderProvider.isLoading).thenReturn(false);
    when(mockReaderProvider.error).thenReturn(null);
    when(
      mockReaderProvider.currentChapterHtml,
    ).thenReturn('<p>Test content</p>');
    when(mockReaderProvider.currentChapterCss).thenReturn('');
    when(mockReaderProvider.currentChapterIndex).thenReturn(0);
    when(mockReaderProvider.currentChapterHref).thenReturn('chapter1.xhtml');
    when(mockReaderProvider.currentChapterImages).thenReturn({});
    when(mockReaderProvider.currentBook).thenReturn(testBook);
    when(mockReaderProvider.tableOfContents).thenReturn([]);
    when(mockReaderProvider.progressPercentage).thenReturn(0.0);
    when(mockReaderProvider.readerController).thenReturn(null);
    when(mockReaderProvider.settings).thenReturn(ReadingSettings.defaults());
    when(mockReaderProvider.openBook(any)).thenAnswer((_) async {});
    when(mockReaderProvider.saveProgress()).thenAnswer((_) async {});
    when(mockReaderProvider.closeBook()).thenAnswer((_) async {});
    when(mockReaderProvider.nextChapter()).thenAnswer((_) async {});
    when(mockReaderProvider.previousChapter()).thenAnswer((_) async {});
    when(mockReaderProvider.goToTocEntry(any)).thenAnswer((_) async {});

    // Setup default mock responses for AudioProvider
    when(mockAudioProvider.highlightedElementId).thenReturn(null);
    when(mockAudioProvider.hasMediaOverlay).thenReturn(false);
    when(mockAudioProvider.isPlaying).thenReturn(false);
    when(mockAudioProvider.position).thenReturn(Duration.zero);
    when(mockAudioProvider.duration).thenReturn(Duration.zero);
    when(mockAudioProvider.progress).thenReturn(0.0);
    when(mockAudioProvider.playbackSpeed).thenReturn(1.0);
    when(mockAudioProvider.reset()).thenAnswer((_) async {});

    // Setup default mock responses for LibraryProvider
    when(mockLibraryProvider.books).thenReturn([testBook]);

    // Setup default mock responses for SettingsProvider
    when(mockSettingsProvider.comicPanelModeEnabled).thenReturn(false);
    when(
      mockSettingsProvider.comicReadingDirection,
    ).thenReturn(ReadingDirection.leftToRight);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ReaderProvider>.value(
            value: mockReaderProvider,
          ),
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<LibraryProvider>.value(
            value: mockLibraryProvider,
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider,
          ),
        ],
        child: const ReaderScreen(bookId: 'test-book-id'),
      ),
    );
  }

  group('ReaderScreen', () {
    group('keyboard shortcuts', () {
      testWidgets('ESC key closes the reader', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Verify the reader screen is displayed
        expect(find.byType(ReaderScreen), findsOneWidget);

        // Simulate pressing ESC key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify that closeBook was called
        verify(mockAudioProvider.reset()).called(1);
        verify(mockReaderProvider.saveProgress()).called(1);
        verify(mockReaderProvider.closeBook()).called(1);
      });

      testWidgets('ESC key triggers navigation pop', (tester) async {
        var didPop = false;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ReaderProvider>.value(
                  value: mockReaderProvider,
                ),
                ChangeNotifierProvider<AudioProvider>.value(
                  value: mockAudioProvider,
                ),
                ChangeNotifierProvider<LibraryProvider>.value(
                  value: mockLibraryProvider,
                ),
                ChangeNotifierProvider<SettingsProvider>.value(
                  value: mockSettingsProvider,
                ),
              ],
              child: Navigator(
                onDidRemovePage: (page) {
                  didPop = true;
                },
                pages: const [
                  MaterialPage(child: Scaffold(body: Text('Library'))),
                  MaterialPage(child: ReaderScreen(bookId: 'test-book-id')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Simulate pressing ESC key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(didPop, isTrue);
      });

      testWidgets('other keys do not close the reader', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Simulate pressing other keys
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Verify that closeBook was NOT called
        verifyNever(mockReaderProvider.closeBook());
      });

      testWidgets('Arrow Right key navigates to next chapter', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Simulate pressing Arrow Right
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Verify nextChapter was called
        verify(mockReaderProvider.nextChapter()).called(1);
      });

      testWidgets('Arrow Left key navigates to previous chapter', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Simulate pressing Arrow Left
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Verify previousChapter was called
        verify(mockReaderProvider.previousChapter()).called(1);
      });
    });
  });
}
