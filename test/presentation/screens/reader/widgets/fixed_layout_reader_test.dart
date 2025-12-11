import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/presentation/providers/reader_provider.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:readwhere/presentation/screens/reader/widgets/fixed_layout_reader.dart';
import 'package:readwhere_cbz_plugin/readwhere_cbz_plugin.dart';
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../../../mocks/mock_repositories.mocks.dart';

/// Mock for CbzReaderController that tracks which page index was requested
class MockCbzReaderController extends Mock implements CbzReaderController {
  final Map<int, Uint8List> _pageData;
  int? lastRequestedPageIndex;

  MockCbzReaderController(this._pageData);

  @override
  Uint8List? getPageBytes(int index) {
    lastRequestedPageIndex = index;
    return _pageData[index];
  }

  @override
  bool get isFixedLayout => true;

  @override
  int get totalChapters => _pageData.length;
}

void main() {
  late MockReaderProvider mockReaderProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockCbzReaderController mockController;

  // Create different page data for each page to verify correct page is shown
  // PNG magic bytes + unique identifier for each page
  final page0Data = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);
  final page1Data = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 1, 1, 1]);
  final page2Data = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 2, 2, 2, 2]);

  setUp(() {
    mockReaderProvider = MockReaderProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockController = MockCbzReaderController({
      0: page0Data,
      1: page1Data,
      2: page2Data,
    });

    // Default setup
    when(mockReaderProvider.hasOpenBook).thenReturn(true);
    when(mockReaderProvider.isLoading).thenReturn(false);
    when(mockReaderProvider.readerController).thenReturn(mockController);
    when(mockReaderProvider.currentChapterIndex).thenReturn(0);
    when(mockReaderProvider.tableOfContents).thenReturn([
      const TocEntry(id: '0', title: 'Page 1', href: '0', level: 0),
      const TocEntry(id: '1', title: 'Page 2', href: '1', level: 0),
      const TocEntry(id: '2', title: 'Page 3', href: '2', level: 0),
    ]);

    // Settings provider setup
    when(mockSettingsProvider.comicPanelModeEnabled).thenReturn(false);
    when(
      mockSettingsProvider.comicReadingDirection,
    ).thenReturn(ReadingDirection.leftToRight);
  });

  Widget buildTestWidget({VoidCallback? onToggleControls}) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<ReaderProvider>.value(
              value: mockReaderProvider,
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider,
            ),
          ],
          child: FixedLayoutReader(onToggleControls: onToggleControls),
        ),
      ),
    );
  }

  group('FixedLayoutReader', () {
    group('page index bug fix', () {
      testWidgets(
        'uses readerProvider.currentChapterIndex for page bytes (not controller)',
        (tester) async {
          // This test verifies the fix for the bug where the comic reader
          // was using controller.currentChapterIndex (always 0) instead of
          // readerProvider.currentChapterIndex for fetching page bytes.

          // Set up provider to report page 2 as current
          when(mockReaderProvider.currentChapterIndex).thenReturn(2);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // Verify that getPageBytes was called with index 2
          // (from readerProvider), not index 0 (from controller)
          expect(
            mockController.lastRequestedPageIndex,
            equals(2),
            reason:
                'Should request page bytes using readerProvider.currentChapterIndex (2), '
                'not controller.currentChapterIndex (0)',
          );
        },
      );

      testWidgets('displays correct page when currentChapterIndex changes', (
        tester,
      ) async {
        // Start at page 0
        when(mockReaderProvider.currentChapterIndex).thenReturn(0);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(mockController.lastRequestedPageIndex, equals(0));

        // Simulate navigation to page 1
        when(mockReaderProvider.currentChapterIndex).thenReturn(1);

        // Trigger rebuild
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          mockController.lastRequestedPageIndex,
          equals(1),
          reason: 'After navigating, should request page 1 bytes',
        );
      });

      testWidgets('renders image when page data is available', (tester) async {
        when(mockReaderProvider.currentChapterIndex).thenReturn(0);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Verify an Image widget is present (the comic page)
        expect(find.byType(Image), findsOneWidget);
      });
    });
  });
}
