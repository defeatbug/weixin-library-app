import 'package:graphql/client.dart';

import 'api.dart';

class AuthApi {
  static const _loginMutation = '''
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        user { id email displayName avatarUrl }
        authToken
      }
    }
  ''';

  static const _registerMutation = '''
    mutation Register(\$email: String!, \$password: String!, \$displayName: String!) {
      register(email: \$email, password: \$password, displayName: \$displayName) {
        user { id email displayName avatarUrl }
        authToken
      }
    }
  ''';

  static Future<QueryResult> login({
    required String email,
    required String password,
  }) {
    return Api.mutate(_loginMutation, variables: {
      'email': email,
      'password': password,
    });
  }

  static Future<QueryResult> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return Api.mutate(_registerMutation, variables: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
  }
}
