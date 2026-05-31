import 'api.dart';

class BookshelfApi {
  static const _myBookshelfQuery = '''
    query MyBookshelf {
      myBookshelf {
        id book { id title author coverUrl fileUrl fileSizeBytes createdAt averageRating reviewCount fileType description }
        addedAt sortOrder
      }
    }
  ''';

  static const _addToBookshelfMutation = '''
    mutation AddToBookshelf(\$bookId: ID!) {
      addToBookshelf(bookId: \$bookId) {
        id book { id title author coverUrl }
        addedAt sortOrder
      }
    }
  ''';

  static const _removeFromBookshelfMutation = '''
    mutation RemoveFromBookshelf(\$bookId: ID!) {
      removeFromBookshelf(bookId: \$bookId)
    }
  ''';

  static Future getMyBookshelf() {
    return Api.query(_myBookshelfQuery);
  }

  static Future addToBookshelf(String bookId) {
    return Api.mutate(_addToBookshelfMutation, variables: {'bookId': bookId});
  }

  static Future removeFromBookshelf(String bookId) {
    return Api.mutate(_removeFromBookshelfMutation, variables: {
      'bookId': bookId,
    });
  }
}
