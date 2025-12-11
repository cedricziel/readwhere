@Tags(['integration'])
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:test/test.dart';

/// Integration tests for EPUB generation from live fanfiction.de stories.
///
/// These tests fetch real stories and generate EPUBs from them.
/// Run with: dart test --tags=integration
void main() {
  late FanfictionClient client;
  late EpubGenerator epubGenerator;

  setUpAll(() {
    client = FanfictionClient(
      userAgent: 'ReadWhere/1.0 (Integration Tests)',
      timeout: const Duration(seconds: 60),
    );
    epubGenerator = EpubGenerator();
  });

  tearDownAll(() {
    client.close();
  });

  /// Helper to get stories - uses latest stories for reliability
  Future<StoryListResult> getStories() async {
    return client.fetchLatestStories();
  }

  group('EPUB Generation Integration', () {
    test('generates valid EPUB from real story', () async {
      // Get stories from latest listing
      final stories = await getStories();

      // Find a short story (1-3 chapters) to reduce test time
      final shortStory = stories.stories.firstWhere(
        (s) => s.chapterCount >= 1 && s.chapterCount <= 3,
        orElse: () => stories.stories.first,
      );

      // ignore: avoid_print
      print('Testing with story: ${shortStory.title}');
      // ignore: avoid_print
      print('  Chapters: ${shortStory.chapterCount}');

      // Fetch full details
      final storyDetails = await client.fetchStoryDetails(shortStory.id);

      // Fetch all chapters (limit to 3 for test speed)
      final chapters = <Chapter>[];
      final maxChapters = storyDetails.chapterCount.clamp(1, 3);
      for (var i = 1; i <= maxChapters; i++) {
        final chapter = await client.fetchChapter(storyDetails.id, i);
        chapters.add(chapter);
        // ignore: avoid_print
        print('  Fetched chapter $i: ${chapter.title}');
      }

      // Generate EPUB
      final epubBytes = await epubGenerator.generateEpub(
        storyDetails,
        chapters,
      );

      expect(epubBytes, isNotEmpty);
      expect(epubBytes.length, greaterThan(1000)); // At least 1KB

      // Verify it's a valid ZIP
      final archive = ZipDecoder().decodeBytes(epubBytes);
      expect(archive.files, isNotEmpty);

      // Check required EPUB files exist
      final fileNames = archive.files.map((f) => f.name).toList();
      expect(fileNames, contains('mimetype'));
      expect(fileNames, contains('META-INF/container.xml'));
      expect(fileNames, contains('OEBPS/content.opf'));
      expect(fileNames, contains('OEBPS/nav.xhtml'));
      expect(fileNames, contains('OEBPS/toc.ncx'));
      expect(fileNames, contains('OEBPS/styles/main.css'));
      expect(fileNames, contains('OEBPS/text/title.xhtml'));

      // Check chapter files exist
      for (var i = 1; i <= chapters.length; i++) {
        final chapterFile =
            'OEBPS/text/chapter${i.toString().padLeft(3, '0')}.xhtml';
        expect(fileNames, contains(chapterFile));
      }

      // ignore: avoid_print
      print(
          'Generated EPUB: ${epubBytes.length} bytes, ${archive.files.length} files');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('EPUB contains valid content.opf', () async {
      final stories = await getStories();
      final story = stories.stories.first;
      final details = await client.fetchStoryDetails(story.id);

      // Just get first chapter for speed
      final chapter = await client.fetchChapter(details.id, 1);

      final epubBytes = await epubGenerator.generateEpub(
        details,
        [chapter],
      );

      final archive = ZipDecoder().decodeBytes(epubBytes);
      final opfFile = archive.files.firstWhere(
        (f) => f.name == 'OEBPS/content.opf',
      );

      final opfContent = String.fromCharCodes(opfFile.content as List<int>);

      // Verify OPF structure
      expect(opfContent, contains('<?xml version="1.0"'));
      expect(opfContent, contains('<package'));
      expect(opfContent, contains('<metadata'));
      expect(opfContent, contains('<dc:title>'));
      expect(opfContent, contains('<dc:creator>'));
      expect(opfContent, contains('<manifest>'));
      expect(opfContent, contains('<spine'));
      expect(opfContent, contains('fanfiction.de:${details.id}'));
    });

    test('EPUB contains valid nav.xhtml', () async {
      final stories = await getStories();
      final story = stories.stories.first;
      final details = await client.fetchStoryDetails(story.id);
      final chapter = await client.fetchChapter(details.id, 1);

      final epubBytes = await epubGenerator.generateEpub(
        details,
        [chapter],
      );

      final archive = ZipDecoder().decodeBytes(epubBytes);
      final navFile = archive.files.firstWhere(
        (f) => f.name == 'OEBPS/nav.xhtml',
      );

      final navContent = String.fromCharCodes(navFile.content as List<int>);

      // Verify nav structure
      expect(navContent, contains('<!DOCTYPE html>'));
      expect(navContent, contains('epub:type="toc"'));
      expect(navContent, contains('<nav'));
      expect(navContent, contains('Inhaltsverzeichnis'));
    });

    test('chapter content is properly cleaned', () async {
      final stories = await getStories();
      final story = stories.stories.first;
      final details = await client.fetchStoryDetails(story.id);
      final chapter = await client.fetchChapter(details.id, 1);

      final epubBytes = await epubGenerator.generateEpub(
        details,
        [chapter],
      );

      final archive = ZipDecoder().decodeBytes(epubBytes);
      final chapterFile = archive.files.firstWhere(
        (f) => f.name == 'OEBPS/text/chapter001.xhtml',
      );

      final chapterContent =
          String.fromCharCodes(chapterFile.content as List<int>);

      // Should not contain harmful elements
      expect(chapterContent, isNot(contains('<script')));
      expect(chapterContent, isNot(contains('onclick=')));
      expect(chapterContent, isNot(contains('onerror=')));

      // Should have valid XHTML structure
      expect(chapterContent, contains('<?xml version="1.0"'));
      expect(chapterContent, contains('<!DOCTYPE html>'));
      expect(chapterContent, contains('<html'));
      expect(chapterContent, contains('</html>'));
    });

    test('can save EPUB to file and read back', () async {
      final stories = await getStories();
      final story = stories.stories.first;
      final details = await client.fetchStoryDetails(story.id);
      final chapter = await client.fetchChapter(details.id, 1);

      final epubBytes = await epubGenerator.generateEpub(
        details,
        [chapter],
      );

      // Save to temp file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_story_${story.id}.epub');

      try {
        await tempFile.writeAsBytes(epubBytes);

        // Read back and verify
        final readBytes = await tempFile.readAsBytes();
        expect(readBytes.length, equals(epubBytes.length));

        // Can decode as ZIP
        final archive = ZipDecoder().decodeBytes(readBytes);
        expect(archive.files, isNotEmpty);

        // ignore: avoid_print
        print('Saved test EPUB to: ${tempFile.path}');
      } finally {
        // Cleanup
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('handles stories with special characters in title', () async {
      // Search for stories that might have special chars
      final results = await client.search('Herz');

      if (results.stories.isEmpty) {
        // ignore: avoid_print
        print('No search results, skipping special character test');
        return;
      }

      final story = results.stories.first;
      final details = await client.fetchStoryDetails(story.id);
      final chapter = await client.fetchChapter(details.id, 1);

      // Should not throw
      final epubBytes = await epubGenerator.generateEpub(
        details,
        [chapter],
      );

      expect(epubBytes, isNotEmpty);

      // Verify XML is well-formed
      final archive = ZipDecoder().decodeBytes(epubBytes);
      final opfFile = archive.files.firstWhere(
        (f) => f.name == 'OEBPS/content.opf',
      );
      final opfContent = String.fromCharCodes(opfFile.content as List<int>);

      // Should have escaped special chars
      expect(opfContent, isNot(contains('&<>')));
    });
  });

  group('Full Download Flow', () {
    test('simulates complete download flow', () async {
      // 1. Browse categories
      // ignore: avoid_print
      print('Step 1: Fetching categories...');
      final categories = await client.fetchCategories();
      expect(categories, isNotEmpty);
      // ignore: avoid_print
      print('  Found ${categories.length} categories');

      // 2. Get latest stories (most reliable source)
      // ignore: avoid_print
      print('Step 2: Fetching latest stories...');
      final stories = await client.fetchLatestStories();
      expect(stories.stories, isNotEmpty);
      // ignore: avoid_print
      print('  Found ${stories.stories.length} stories');

      // 3. Pick a short story
      final shortStory = stories.stories.firstWhere(
        (s) => s.chapterCount == 1,
        orElse: () => stories.stories.first,
      );
      // ignore: avoid_print
      print('Step 3: Selected story: ${shortStory.title}');

      // 4. Fetch details
      // ignore: avoid_print
      print('Step 4: Fetching story details...');
      final details = await client.fetchStoryDetails(shortStory.id);
      // ignore: avoid_print
      print('  Title: ${details.title}');
      // ignore: avoid_print
      print('  Author: ${details.author.username}');

      // 5. Fetch chapters
      // ignore: avoid_print
      print('Step 5: Fetching chapters...');
      final chapters = <Chapter>[];
      final maxChapters = details.chapterCount.clamp(1, 2); // Limit for test
      for (var i = 1; i <= maxChapters; i++) {
        final chapter = await client.fetchChapter(details.id, i);
        chapters.add(chapter);
        // ignore: avoid_print
        print('  Chapter $i: ${chapter.title}');
      }

      // 6. Generate EPUB
      // ignore: avoid_print
      print('Step 6: Generating EPUB...');
      final epubBytes = await epubGenerator.generateEpub(details, chapters);
      // ignore: avoid_print
      print('  Generated ${epubBytes.length} bytes');

      // 7. Verify
      final archive = ZipDecoder().decodeBytes(epubBytes);
      // ignore: avoid_print
      print('Step 7: Verification complete');
      // ignore: avoid_print
      print('  EPUB contains ${archive.files.length} files');

      expect(epubBytes.length, greaterThan(1000));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
