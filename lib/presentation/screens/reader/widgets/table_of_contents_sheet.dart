import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/toc_entry.dart';
import '../../../providers/reader_provider.dart';

/// Bottom sheet displaying the table of contents
///
/// Shows a list of all chapters with nested structure and highlighting
/// for the current chapter. Tapping a chapter navigates to it.
class TableOfContentsSheet extends StatelessWidget {
  final ValueChanged<int> onChapterSelected;

  const TableOfContentsSheet({super.key, required this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, readerProvider, child) {
        final toc = readerProvider.tableOfContents;
        final currentChapter = readerProvider.currentChapterIndex;

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
                    const Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 20,
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
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: toc.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          return _buildTocItem(
                            context,
                            toc[index],
                            index,
                            currentChapter,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No table of contents available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'This book may not have chapter information',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTocItem(
    BuildContext context,
    TocEntry entry,
    int index,
    int currentChapter,
  ) {
    final isCurrentChapter = index == currentChapter;
    final indentLevel = entry.level;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isCurrentChapter
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onChapterSelected(index),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0 + (indentLevel * 16.0),
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  // Chapter number or bullet point
                  if (indentLevel == 0)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isCurrentChapter
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCurrentChapter
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
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
                        fontSize: indentLevel == 0 ? 16 : 14,
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
            (childEntry) => _buildTocItem(
              context,
              childEntry,
              // Note: This is simplified - in a real implementation,
              // you'd need to track the actual index across nested items
              index,
              currentChapter,
            ),
          ),
      ],
    );
  }
}
