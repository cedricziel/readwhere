import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import '../../../providers/reader_provider.dart';

/// Bottom sheet displaying the table of contents
///
/// Shows a list of all chapters with nested structure and highlighting
/// for the current chapter. Tapping a chapter navigates to it.
class TableOfContentsSheet extends StatelessWidget {
  final ValueChanged<TocEntry> onChapterSelected;

  const TableOfContentsSheet({super.key, required this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, readerProvider, child) {
        final toc = readerProvider.tableOfContents;
        final currentChapterHref = readerProvider.currentChapterHref;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Table of Contents',
                      style: TextStyle(
                        // Use textScaler for accessibility
                        fontSize: MediaQuery.textScalerOf(context).scale(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Table of contents list
              Flexible(
                child: toc.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: toc.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          return _buildTocItem(
                            context,
                            toc[index],
                            currentChapterHref,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No table of contents available',
            style: TextStyle(
              // Use textScaler for accessibility
              fontSize: textScaler.scale(16),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This book may not have chapter information',
            style: TextStyle(
              // Use textScaler for accessibility
              fontSize: textScaler.scale(14),
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Check if the entry's href matches the current chapter href
  bool _isCurrentChapter(TocEntry entry, String? currentChapterHref) {
    if (currentChapterHref == null) return false;

    // Get document href without fragment
    final entryDocHref = entry.href.contains('#')
        ? entry.href.split('#').first
        : entry.href;

    // Check for exact match or suffix match (handles path variations)
    return currentChapterHref == entryDocHref ||
        currentChapterHref.endsWith(entryDocHref) ||
        entryDocHref.endsWith(currentChapterHref);
  }

  Widget _buildTocItem(
    BuildContext context,
    TocEntry entry,
    String? currentChapterHref,
  ) {
    final isCurrentChapter = _isCurrentChapter(entry, currentChapterHref);
    final indentLevel = entry.level;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isCurrentChapter
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onChapterSelected(entry),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0 + (indentLevel * 16.0),
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  // Bullet point for all items
                  if (indentLevel == 0)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isCurrentChapter
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isCurrentChapter
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Chapter title
                  Expanded(
                    child: Text(
                      entry.title,
                      style: TextStyle(
                        // Use textScaler for accessibility
                        fontSize: MediaQuery.textScalerOf(
                          context,
                        ).scale(indentLevel == 0 ? 16 : 14),
                        fontWeight: isCurrentChapter
                            ? FontWeight.w600
                            : (indentLevel == 0
                                  ? FontWeight.w500
                                  : FontWeight.normal),
                        color: isCurrentChapter
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Current chapter indicator
                  if (isCurrentChapter)
                    Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Render nested children recursively
        if (entry.children.isNotEmpty)
          ...entry.children.map(
            (childEntry) =>
                _buildTocItem(context, childEntry, currentChapterHref),
          ),
      ],
    );
  }
}
