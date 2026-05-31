import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';

import '../config/application.dart';
import '../models/current_user.dart';

class Api {
  static GraphQLClient? _client;

  static GraphQLClient get client => _client ??= _createClient();

  static GraphQLClient _createClient() {
    final httpLink = HttpLink(Application.graphQLURL);

    final authLink = AuthLink(
      getToken: () async => CurrentUser.instance.authorization,
    );

    return GraphQLClient(
      cache: GraphQLCache(),
      link: authLink.concat(httpLink),
    );
  }

  static Future<QueryResult> query(
    String document, {
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
  }) async {
    final result = await client.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      debugPrint('❌ [API] Query error: ${result.exception}');
      _checkAuthError(result.exception);
    }

    return result;
  }

  static Future<QueryResult> mutate(
    String document, {
    Map<String, dynamic> variables = const {},
  }) async {
    final result = await client.mutate(
      MutationOptions(
        document: gql(document),
        variables: variables,
      ),
    );

    if (result.hasException) {
      debugPrint('❌ [API] Mutation error: ${result.exception}');
      _checkAuthError(result.exception);
    }

    return result;
  }

  static void _checkAuthError(OperationException? exception) {
    if (exception == null) return;
    final hasAuthError = exception.graphqlErrors.any(
      (e) =>
          e.message.contains('not authorized') ||
          e.message.contains('unauthorized') ||
          e.message.contains('Unauthorized'),
    );
    if (hasAuthError) {
      CurrentUser.instance.logout();
    }
  }
}
