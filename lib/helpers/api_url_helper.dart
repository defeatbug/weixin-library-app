import '../config/application.dart';

class ApiUrlHelper {
  ApiUrlHelper._();

  /// 将后端返回的绝对/相对 URL 统一解析为当前 API 地址
  static String resolve(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return '${Application.apiBaseURL}$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.isNotEmpty) {
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      return '${Application.apiBaseURL}$path';
    }
    return url;
  }

  /// 提取 API 相对路径，供 Dio 与 baseUrl 配合使用
  static String toPath(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) return url;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.isNotEmpty) {
      return uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    }
    return url;
  }
}
