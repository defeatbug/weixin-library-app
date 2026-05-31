import 'api.dart';

class ReviewApi {
  static const _reviewsByBookQuery = '''
    query ReviewsByBook(\$bookId: ID!, \$page: Int, \$size: Int) {
      reviewsByBook(bookId: \$bookId, page: \$page, size: \$size) {
        items { id user { id displayName avatarUrl } book { id title } rating content createdAt updatedAt }
        total page size
      }
    }
  ''';

  static const _createReviewMutation = '''
    mutation CreateReview(\$bookId: ID!, \$rating: Int!, \$content: String) {
      createReview(bookId: \$bookId, rating: \$rating, content: \$content) {
        id rating content createdAt
      }
    }
  ''';

  static const _updateReviewMutation = '''
    mutation UpdateReview(\$id: ID!, \$rating: Int, \$content: String) {
      updateReview(id: \$id, rating: \$rating, content: \$content) {
        id rating content updatedAt
      }
    }
  ''';

  static const _deleteReviewMutation = '''
    mutation DeleteReview(\$id: ID!) {
      deleteReview(id: \$id)
    }
  ''';

  static Future getReviewsByBook(String bookId, {int page = 0, int size = 20}) {
    return Api.query(_reviewsByBookQuery, variables: {
      'bookId': bookId,
      'page': page,
      'size': size,
    });
  }

  static Future createReview(String bookId, int rating, {String? content}) {
    return Api.mutate(_createReviewMutation, variables: {
      'bookId': bookId,
      'rating': rating,
      'content': content,
    });
  }

  static Future updateReview(String id, {int? rating, String? content}) {
    return Api.mutate(_updateReviewMutation, variables: {
      'id': id,
      'rating': rating,
      'content': content,
    });
  }

  static Future deleteReview(String id) {
    return Api.mutate(_deleteReviewMutation, variables: {'id': id});
  }
}
