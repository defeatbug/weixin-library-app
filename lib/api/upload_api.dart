import 'package:dio/dio.dart';

import '../config/application.dart';

class UploadApi {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: Application.apiBaseURL,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 120),
  ));

  static Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileName, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post(
      '/api/files/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    return response.data as Map<String, dynamic>;
  }
}
