import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/screens/catalogs/browse/widgets/opds_entry_card.dart';
import 'package:readwhere_opds/readwhere_opds.dart';

// Mock OPDS entries for demonstration
OpdsEntry _createBookEntry({
  String title = 'The Great Gatsby',
  String? author = 'F. Scott Fitzgerald',
  String format = 'epub',
}) {
  return OpdsEntry(
    id: 'book-1',
    title: title,
    author: author,
    summary: 'A classic American novel set in the Jazz Age.',
    updated: DateTime.now(),
    links: [
      OpdsLink(
        href: 'https://example.com/book.epub',
        rel: OpdsLinkRel.acquisitionOpenAccess,
        type: format == 'epub' ? OpdsMimeType.epub : OpdsMimeType.pdf,
      ),
    ],
    publisher: 'Scribner',
    language: 'en',
  );
}

OpdsEntry _createNavigationEntry({String title = 'Science Fiction'}) {
  return OpdsEntry(
    id: 'nav-1',
    title: title,
    updated: DateTime.now(),
    links: [
      const OpdsLink(
        href: 'https://example.com/scifi',
        rel: OpdsLinkRel.subsection,
        type: OpdsMimeType.opdsNavigation,
      ),
    ],
  );
}

OpdsEntry _createUnsupportedEntry() {
  return OpdsEntry(
    id: 'book-unsupported',
    title: 'Unsupported Format Book',
    author: 'Unknown Author',
    updated: DateTime.now(),
    links: [
      const OpdsLink(
        href: 'https://example.com/book.azw',
        rel: OpdsLinkRel.acquisitionOpenAccess,
        type: 'application/x-mobipocket-ebook',
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Book Entry', type: OpdsEntryCard, path: '[Catalog]')
Widget buildOpdsEntryCardBook(BuildContext context) {
  return SizedBox(
    width: 180,
    height: 280,
    child: OpdsEntryCard(
      entry: _createBookEntry(
        title: context.knobs.string(
          label: 'Title',
          initialValue: 'The Great Gatsby',
        ),
        author: context.knobs.stringOrNull(
          label: 'Author',
          initialValue: 'F. Scott Fitzgerald',
        ),
      ),
      isDownloading: context.knobs.boolean(
        label: 'Is Downloading',
        initialValue: false,
      ),
      isDownloaded: context.knobs.boolean(
        label: 'Is Downloaded',
        initialValue: false,
      ),
      downloadProgress: context.knobs.double.slider(
        label: 'Download Progress',
        initialValue: 0,
        min: 0,
        max: 1,
      ),
      onTap: () => debugPrint('Card tapped'),
      onDownload: () => debugPrint('Download pressed'),
      onOpen: () => debugPrint('Open pressed'),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Navigation Entry',
  type: OpdsEntryCard,
  path: '[Catalog]',
)
Widget buildOpdsEntryCardNavigation(BuildContext context) {
  return SizedBox(
    width: 180,
    height: 280,
    child: OpdsEntryCard(
      entry: _createNavigationEntry(
        title: context.knobs.string(
          label: 'Title',
          initialValue: 'Science Fiction',
        ),
      ),
      isDownloading: false,
      isDownloaded: false,
      downloadProgress: 0,
      onTap: () => debugPrint('Navigation tapped'),
      onDownload: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Downloading State',
  type: OpdsEntryCard,
  path: '[Catalog]',
)
Widget buildOpdsEntryCardDownloading(BuildContext context) {
  return SizedBox(
    width: 180,
    height: 280,
    child: OpdsEntryCard(
      entry: _createBookEntry(),
      isDownloading: true,
      isDownloaded: false,
      downloadProgress: context.knobs.double.slider(
        label: 'Progress',
        initialValue: 0.45,
        min: 0,
        max: 1,
      ),
      onTap: () => debugPrint('Card tapped'),
      onDownload: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Downloaded State',
  type: OpdsEntryCard,
  path: '[Catalog]',
)
Widget buildOpdsEntryCardDownloaded(BuildContext context) {
  return SizedBox(
    width: 180,
    height: 280,
    child: OpdsEntryCard(
      entry: _createBookEntry(),
      isDownloading: false,
      isDownloaded: true,
      downloadProgress: 1,
      onTap: () => debugPrint('Card tapped'),
      onDownload: () {},
      onOpen: () => debugPrint('Open in reader'),
    ),
  );
}

@widgetbook.UseCase(name: 'Grid Layout', type: OpdsEntryCard, path: '[Catalog]')
Widget buildOpdsEntryCardGrid(BuildContext context) {
  final entries = [
    _createBookEntry(title: 'Pride and Prejudice', author: 'Jane Austen'),
    _createBookEntry(title: '1984', author: 'George Orwell'),
    _createNavigationEntry(title: 'Fantasy'),
    _createBookEntry(title: 'To Kill a Mockingbird', author: 'Harper Lee'),
    _createNavigationEntry(title: 'Mystery'),
    _createBookEntry(title: 'The Hobbit', author: 'J.R.R. Tolkien'),
  ];

  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 0.65,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      return OpdsEntryCard(
        entry: entry,
        isDownloading: false,
        isDownloaded: index == 1,
        downloadProgress: 0,
        onTap: () => debugPrint('Tapped: ${entry.title}'),
        onDownload: () => debugPrint('Download: ${entry.title}'),
        onOpen: () => debugPrint('Open: ${entry.title}'),
      );
    },
  );
}

// OpdsEntryListTile use cases

@widgetbook.UseCase(
  name: 'Book Entry',
  type: OpdsEntryListTile,
  path: '[Catalog]',
)
Widget buildOpdsEntryListTileBook(BuildContext context) {
  return OpdsEntryListTile(
    entry: _createBookEntry(
      title: context.knobs.string(
        label: 'Title',
        initialValue: 'The Great Gatsby',
      ),
      author: context.knobs.stringOrNull(
        label: 'Author',
        initialValue: 'F. Scott Fitzgerald',
      ),
    ),
    isDownloading: context.knobs.boolean(
      label: 'Is Downloading',
      initialValue: false,
    ),
    isDownloaded: context.knobs.boolean(
      label: 'Is Downloaded',
      initialValue: false,
    ),
    downloadProgress: context.knobs.double.slider(
      label: 'Download Progress',
      initialValue: 0,
      min: 0,
      max: 1,
    ),
    onTap: () => debugPrint('List tile tapped'),
    onDownload: () => debugPrint('Download pressed'),
    onOpen: () => debugPrint('Open pressed'),
  );
}

@widgetbook.UseCase(
  name: 'Navigation Entry',
  type: OpdsEntryListTile,
  path: '[Catalog]',
)
Widget buildOpdsEntryListTileNavigation(BuildContext context) {
  return OpdsEntryListTile(
    entry: _createNavigationEntry(
      title: context.knobs.string(
        label: 'Title',
        initialValue: 'Science Fiction',
      ),
    ),
    isDownloading: false,
    isDownloaded: false,
    downloadProgress: 0,
    onTap: () => debugPrint('Navigation tapped'),
    onDownload: () {},
  );
}

@widgetbook.UseCase(
  name: 'Unsupported Format',
  type: OpdsEntryListTile,
  path: '[Catalog]',
)
Widget buildOpdsEntryListTileUnsupported(BuildContext context) {
  return OpdsEntryListTile(
    entry: _createUnsupportedEntry(),
    isDownloading: false,
    isDownloaded: false,
    downloadProgress: 0,
    onTap: () => debugPrint('Tapped unsupported'),
    onDownload: () {},
  );
}

@widgetbook.UseCase(
  name: 'List View',
  type: OpdsEntryListTile,
  path: '[Catalog]',
)
Widget buildOpdsEntryListTileList(BuildContext context) {
  final entries = [
    _createBookEntry(title: 'Pride and Prejudice', author: 'Jane Austen'),
    _createBookEntry(title: '1984', author: 'George Orwell'),
    _createNavigationEntry(title: 'Fantasy Collection'),
    _createBookEntry(title: 'To Kill a Mockingbird', author: 'Harper Lee'),
    _createUnsupportedEntry(),
    _createBookEntry(title: 'The Hobbit', author: 'J.R.R. Tolkien'),
  ];

  return ListView.builder(
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      return OpdsEntryListTile(
        entry: entry,
        isDownloading: index == 3,
        isDownloaded: index == 1,
        downloadProgress: index == 3 ? 0.6 : 0,
        onTap: () => debugPrint('Tapped: ${entry.title}'),
        onDownload: () => debugPrint('Download: ${entry.title}'),
        onOpen: () => debugPrint('Open: ${entry.title}'),
      );
    },
  );
}
