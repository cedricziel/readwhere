import 'package:html/parser.dart' as html_parser;

import '../entities/chapter.dart';

/// Parses chapter content from fanfiction.de story pages.
class ChapterParser {
  const ChapterParser();

  /// Parse chapter content from a story chapter page.
  ///
  /// Returns a [Chapter] with the HTML content extracted.
  Chapter parseChapter(String html, int chapterNumber) {
    final document = html_parser.parse(html);

    // Get chapter title from the chapter select
    var title = 'Chapter $chapterNumber';
    final chapterSelect = document.querySelector('select[name="k"]');
    if (chapterSelect != null) {
      final selectedOption = chapterSelect.querySelector('option[selected]') ??
          chapterSelect
              .querySelectorAll('option')
              .where((o) => o.attributes['value'] == '$chapterNumber')
              .firstOrNull;
      if (selectedOption != null) {
        final optionText = selectedOption.text.trim();
        // Parse "1. Chapter Title" format
        final match = RegExp(r'^\d+\.\s*(.+)$').firstMatch(optionText);
        title = match?.group(1) ?? optionText;
      }
    }

    // Get chapter content
    final storyText =
        document.querySelector('#storytext .user-formatted-inner');
    final htmlContent = storyText?.innerHtml ?? '';

    // Get word count for this chapter
    int? wordCount;
    final wordCountElement =
        document.querySelector('.chapterinfo .titled-icon[title*="Wörter"]');
    if (wordCountElement != null) {
      final sibling = wordCountElement.nextElementSibling;
      if (sibling != null) {
        final text = sibling.text.replaceAll(RegExp(r'[^\d]'), '');
        wordCount = int.tryParse(text);
      }
    }

    // Get chapter creation date
    DateTime? publishedAt;
    final dateElement =
        document.querySelector('.chapterinfo .titled-icon[title*="erstellt"]');
    if (dateElement != null) {
      // Get the next sibling element's text
      final nextSibling = dateElement.nextElementSibling;
      final dateText = nextSibling?.text.trim() ?? '';
      publishedAt = _parseGermanDate(dateText);
    }

    return Chapter(
      number: chapterNumber,
      title: title,
      htmlContent: htmlContent,
      wordCount: wordCount,
      publishedAt: publishedAt,
    );
  }

  /// Extract and clean chapter content for EPUB generation.
  ///
  /// This removes site-specific elements and cleans up the HTML.
  String cleanChapterHtml(String rawHtml) {
    final document = html_parser.parseFragment(rawHtml);

    // Convert to clean HTML
    final buffer = StringBuffer();
    _processNode(document, buffer);

    return buffer.toString().trim();
  }

  void _processNode(dynamic node, StringBuffer buffer) {
    if (node.nodeType == 3) {
      // Text node
      buffer.write(_escapeHtml(node.text ?? ''));
    } else if (node.nodeType == 1) {
      // Element node
      final element = node;
      final tagName = element.localName?.toLowerCase() ?? '';

      // Handle specific elements
      switch (tagName) {
        case 'br':
          buffer.write('<br/>');
          break;
        case 'p':
          buffer.write('<p>');
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
          buffer.write('</p>');
          break;
        case 'span':
          // Check for formatting classes
          final classes = element.classes;
          if (classes.contains('user_bold')) {
            buffer.write('<strong>');
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
            buffer.write('</strong>');
          } else if (classes.contains('user_italic')) {
            buffer.write('<em>');
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
            buffer.write('</em>');
          } else if (classes.contains('user_underlined')) {
            buffer.write('<u>');
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
            buffer.write('</u>');
          } else {
            // Plain span, just process children
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
          }
          break;
        case 'a':
          final href = element.attributes['href'];
          if (href != null && href.isNotEmpty) {
            buffer.write('<a href="${_escapeHtml(href)}">');
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
            buffer.write('</a>');
          } else {
            for (final child in element.nodes) {
              _processNode(child, buffer);
            }
          }
          break;
        case 'strong':
        case 'b':
          buffer.write('<strong>');
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
          buffer.write('</strong>');
          break;
        case 'em':
        case 'i':
          buffer.write('<em>');
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
          buffer.write('</em>');
          break;
        case 'u':
          buffer.write('<u>');
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
          buffer.write('</u>');
          break;
        case 'hr':
          buffer.write('<hr/>');
          break;
        case 'div':
          buffer.write('<div>');
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
          buffer.write('</div>');
          break;
        default:
          // For unknown elements, just process children
          for (final child in element.nodes) {
            _processNode(child, buffer);
          }
      }
    } else {
      // Other node types (comments, etc.) - process children if any
      if (node.nodes != null) {
        for (final child in node.nodes) {
          _processNode(child, buffer);
        }
      }
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Parse a German date string (DD.MM.YYYY).
  DateTime? _parseGermanDate(String text) {
    final match = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(text);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    return DateTime(year, month, day);
  }
}
