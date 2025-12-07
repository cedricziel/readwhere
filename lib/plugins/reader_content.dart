import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents the content of a chapter for rendering
class ReaderContent extends Equatable {
  /// Unique identifier for the chapter
  final String chapterId;

  /// Title of the chapter
  final String chapterTitle;

  /// HTML content of the chapter
  final String htmlContent;

  /// CSS styling for the chapter
  final String cssContent;

  /// Embedded images referenced in the chapter (key: image path/id, value: image data)
  final Map<String, Uint8List> images;

  const ReaderContent({
    required this.chapterId,
    required this.chapterTitle,
    required this.htmlContent,
    this.cssContent = '',
    this.images = const {},
  });

  /// Creates a copy of this ReaderContent with the given fields replaced
  ReaderContent copyWith({
    String? chapterId,
    String? chapterTitle,
    String? htmlContent,
    String? cssContent,
    Map<String, Uint8List>? images,
  }) {
    return ReaderContent(
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      htmlContent: htmlContent ?? this.htmlContent,
      cssContent: cssContent ?? this.cssContent,
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        chapterId,
        chapterTitle,
        htmlContent,
        cssContent,
        images,
      ];

  @override
  String toString() {
    return 'ReaderContent(chapterId: $chapterId, chapterTitle: $chapterTitle, '
        'htmlLength: ${htmlContent.length}, cssLength: ${cssContent.length}, '
        'imageCount: ${images.length})';
  }
}
