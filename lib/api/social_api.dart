import 'api.dart';

class SocialApi {
  static const _recentReviewsQuery = '''
    query RecentReviews(\$page: Int, \$size: Int) {
      recentReviews(page: \$page, size: \$size) {
        items {
          id
          user { id displayName avatarUrl }
          book { id title coverUrl }
          rating content createdAt updatedAt
        }
        total page size
      }
    }
  ''';

  static const _myStatsQuery = '''
    query MyStats {
      myStats {
        bookshelfCount reviewCount booksReadingCount
      }
    }
  ''';

  static Future getRecentReviews({int page = 0, int size = 20}) {
    return Api.query(_recentReviewsQuery, variables: {
      'page': page,
      'size': size,
    });
  }

  static Future getMyStats() {
    return Api.query(_myStatsQuery);
  }
}
