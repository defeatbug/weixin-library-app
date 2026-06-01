import 'package:dio/dio.dart';

import '../config/application.dart';
import '../models/current_user.dart';

class UploadApi {
  static Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: Application.apiBaseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
    ));
  }

  static Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileName, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final dio = _createDio();
    final token = CurrentUser.instance.authToken;
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await dio.post(
      '/api/files/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    return response.data as Map<String, dynamic>;
  }
}
