import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';

class GraphQLHelper {
  static List<T> getItemsFromResult<T>(
    QueryResult result,
    T Function(Map<String, dynamic>) fromJson,
    List<String> keys,
  ) {
    if (result.hasException || result.data == null) return [];

    try {
      dynamic data = result.data;
      for (final key in keys) {
        if (data == null) return [];
        data = data[key];
      }
      if (data is! List) return [];
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('GraphQLHelper.getItemsFromResult error: $e');
      return [];
    }
  }

  static T? getItemFromResult<T>(
    QueryResult result,
    T Function(Map<String, dynamic>) fromJson,
    List<String> keys,
  ) {
    if (result.hasException || result.data == null) return null;

    try {
      dynamic data = result.data;
      for (final key in keys) {
        if (data == null) return null;
        data = data[key];
      }
      if (data is! Map<String, dynamic>) return null;
      return fromJson(data);
    } catch (e) {
      debugPrint('GraphQLHelper.getItemFromResult error: $e');
      return null;
    }
  }
}
