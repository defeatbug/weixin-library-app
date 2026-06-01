import 'package:dio/dio.dart';

import '../config/application.dart';
import '../helpers/api_url_helper.dart';
import '../models/current_user.dart';

class FileApi {
  static Dio _dio() {
    final dio = Dio(BaseOptions(
      baseUrl: Application.apiBaseURL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ));
    final token = CurrentUser.instance.authToken;
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  static Future<String> fetchText(String fileUrl, {required bool isEpub}) async {
    final path = ApiUrlHelper.toPath(fileUrl);
    final requestPath = isEpub ? '$path/text' : path;
    final response = await _dio().get<String>(requestPath);
    return response.data ?? '';
  }

  static Future<List<String>> fetchToc(String fileUrl) async {
    final path = ApiUrlHelper.toPath(fileUrl);
    final response = await _dio().get<Map<String, dynamic>>('$path/toc');
    final chapters = response.data?['chapters'] as List<dynamic>?;
    if (chapters == null) return [];
    return chapters
        .map((c) {
          if (c is Map) return (c['title'] as String?) ?? '';
          return c.toString();
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
