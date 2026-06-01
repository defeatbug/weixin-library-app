import 'package:graphql/client.dart';

import 'api.dart';

class BookApi {
  static const _booksQuery = '''
    query Books(\$page: Int, \$size: Int, \$sortBy: String, \$sortDir: String) {
      books(page: \$page, size: \$size, sortBy: \$sortBy, sortDir: \$sortDir) {
        items { id title author coverUrl fileUrl fileSizeBytes createdAt averageRating reviewCount description fileType }
        total page size
      }
    }
  ''';

  static const _bookQuery = '''
    query Book(\$id: ID!) {
      book(id: \$id) {
        id title author isbn coverUrl fileUrl fileType description
        publisher publishedAt language fileSizeBytes
        averageRating reviewCount createdAt
      }
    }
  ''';

  static const _searchQuery = '''
    query SearchBooks(\$query: String!, \$page: Int, \$size: Int) {
      searchBooks(query: \$query, page: \$page, size: \$size) {
        items { id title author coverUrl fileUrl fileSizeBytes createdAt averageRating reviewCount description fileType }
        total page size
      }
    }
  ''';

  static const _createBookMutation = '''
    mutation CreateBook(\$input: CreateBookInput!) {
      createBook(input: \$input) {
        id title author fileUrl fileType fileSizeBytes
      }
    }
  ''';

  static Future<QueryResult> getBooks({
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) {
    return Api.query(_booksQuery, variables: {
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDir': sortDir,
    });
  }

  static Future<QueryResult> getBook(String id) {
    return Api.query(_bookQuery, variables: {'id': id});
  }

  static Future<QueryResult> createBook({
    required String title,
    required String author,
    required String fileUrl,
    required String fileType,
    required double fileSizeBytes,
    String? description,
    String? isbn,
    String? coverUrl,
    String? publisher,
    String? publishedAt,
    String? language,
  }) {
    return Api.mutate(_createBookMutation, variables: {
      'input': {
        'title': title,
        'author': author,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileSizeBytes': fileSizeBytes,
        if (description != null) 'description': description,
        if (isbn != null) 'isbn': isbn,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (publisher != null) 'publisher': publisher,
        if (publishedAt != null) 'publishedAt': publishedAt,
        if (language != null) 'language': language,
      },
    });
  }

  static Future<QueryResult> searchBooks({
    required String query,
    int page = 0,
    int size = 20,
  }) {
    return Api.query(_searchQuery, variables: {
      'query': query,
      'page': page,
      'size': size,
    });
  }
}
