/// Reading progress from Kavita
class KavitaProgress {
  /// The chapter ID
  final int chapterId;

  /// Current page number
  final int pageNum;

  /// Volume ID this chapter belongs to
  final int volumeId;

  /// Series ID this chapter belongs to
  final int seriesId;

  /// Library ID this series belongs to
  final int libraryId;

  /// Scroll position ID for book/webtoon mode
  final String? bookScrollId;

  /// When this progress was last modified
  final DateTime? lastModified;

  /// Creates Kavita progress
  KavitaProgress({
    required this.chapterId,
    required this.pageNum,
    required this.volumeId,
    required this.seriesId,
    required this.libraryId,
    this.bookScrollId,
    this.lastModified,
  });

  /// Creates from JSON response
  factory KavitaProgress.fromJson(Map<String, dynamic> json) {
    return KavitaProgress(
      chapterId: json['chapterId'] as int? ?? 0,
      pageNum: json['pageNum'] as int? ?? 0,
      volumeId: json['volumeId'] as int? ?? 0,
      seriesId: json['seriesId'] as int? ?? 0,
      libraryId: json['libraryId'] as int? ?? 0,
      bookScrollId: json['bookScrollId'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
    );
  }

  /// Converts to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'pageNum': pageNum,
      'volumeId': volumeId,
      'seriesId': seriesId,
      'libraryId': libraryId,
      if (bookScrollId != null) 'bookScrollId': bookScrollId,
    };
  }

  /// Creates a copy with modified fields
  KavitaProgress copyWith({
    int? chapterId,
    int? pageNum,
    int? volumeId,
    int? seriesId,
    int? libraryId,
    String? bookScrollId,
    DateTime? lastModified,
  }) {
    return KavitaProgress(
      chapterId: chapterId ?? this.chapterId,
      pageNum: pageNum ?? this.pageNum,
      volumeId: volumeId ?? this.volumeId,
      seriesId: seriesId ?? this.seriesId,
      libraryId: libraryId ?? this.libraryId,
      bookScrollId: bookScrollId ?? this.bookScrollId,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() =>
      'KavitaProgress(chapter: $chapterId, page: $pageNum, series: $seriesId)';
}
