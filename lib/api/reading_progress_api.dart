import 'api.dart';

class ReadingProgressApi {
  static const _readingProgressQuery = '''
    query ReadingProgress(\$bookId: ID!) {
      readingProgress(bookId: \$bookId) {
        bookId currentChapterId currentChapterTitle pageOffset percentage updatedAt
      }
    }
  ''';

  static const _saveReadingProgressMutation = '''
    mutation SaveReadingProgress(
      \$bookId: ID!,
      \$chapterId: String,
      \$chapterTitle: String,
      \$pageOffset: Int,
      \$percentage: Float!
    ) {
      saveReadingProgress(
        bookId: \$bookId,
        chapterId: \$chapterId,
        chapterTitle: \$chapterTitle,
        pageOffset: \$pageOffset,
        percentage: \$percentage
      ) {
        bookId currentChapterId currentChapterTitle pageOffset percentage updatedAt
      }
    }
  ''';

  static Future getProgress(String bookId) {
    return Api.query(_readingProgressQuery, variables: {'bookId': bookId});
  }

  static Future saveProgress({
    required String bookId,
    String? chapterId,
    String? chapterTitle,
    int? pageOffset,
    required double percentage,
  }) {
    return Api.mutate(_saveReadingProgressMutation, variables: {
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'pageOffset': pageOffset,
      'percentage': percentage,
    });
  }
}
