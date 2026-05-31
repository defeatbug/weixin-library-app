import '../../api/api.dart';

class ApiAdmin {
  static const _adminBooksQuery = '''
    query AdminBooks(\$page: Int, \$size: Int, \$search: String) {
      adminBooks(page: \$page, size: \$size, search: \$search) {
        items {
          id title author isbn coverUrl fileUrl fileType fileSizeBytes
          description publisher language averageRating reviewCount createdAt
        }
        total page size
      }
    }
  ''';

  static const _adminUpdateBookMutation = '''
    mutation UpdateBook(\$id: ID!, \$input: UpdateBookInput!) {
      updateBook(id: \$id, input: \$input) { id title author }
    }
  ''';

  static const _adminUsersQuery = '''
    query AdminUsers(\$page: Int, \$size: Int, \$search: String) {
      adminUsers(page: \$page, size: \$size, search: \$search) {
        items {
          id email displayName avatarUrl role
          bookshelfCount reviewCount
        }
        total page size
      }
    }
  ''';

  static Future getAdminBooks({
    int page = 0, int size = 20, String? search,
  }) {
    return Api.query(_adminBooksQuery, variables: {
      'page': page,
      'size': size,
      'search': search,
    });
  }

  static Future updateBook(String id, Map<String, dynamic> input) {
    return Api.mutate(_adminUpdateBookMutation, variables: {
      'id': id,
      'input': input,
    });
  }

  static Future getAdminUsers({
    int page = 0, int size = 20, String? search,
  }) {
    return Api.query(_adminUsersQuery, variables: {
      'page': page,
      'size': size,
      'search': search,
    });
  }
}
