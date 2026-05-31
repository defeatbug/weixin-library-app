class ReadingProgress {
  final String bookId;
  final String? currentChapterId;
  final String? currentChapterTitle;
  final int? pageOffset;
  final double percentage;
  final String updatedAt;

  ReadingProgress({
    required this.bookId,
    this.currentChapterId,
    this.currentChapterTitle,
    this.pageOffset,
    required this.percentage,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['bookId'] as String,
      currentChapterId: json['currentChapterId'] as String?,
      currentChapterTitle: json['currentChapterTitle'] as String?,
      pageOffset: json['pageOffset'] as int?,
      percentage: (json['percentage'] as num).toDouble(),
      updatedAt: json['updatedAt'] as String,
    );
  }
}
