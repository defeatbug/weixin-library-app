import '../helpers/api_url_helper.dart';

class BookCoverHelper {
  BookCoverHelper._();

  /// 解析封面 URL：优先 coverUrl，EPUB 则从 fileUrl 推导 /cover 接口
  static String? resolveUrl({
    String? coverUrl,
    String? fileUrl,
    String? fileType,
  }) {
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ApiUrlHelper.resolve(coverUrl);
    }
    if (fileType?.toUpperCase() == 'EPUB' &&
        fileUrl != null &&
        fileUrl.isNotEmpty) {
      final path = ApiUrlHelper.toPath(fileUrl);
      return ApiUrlHelper.resolve('$path/cover');
    }
    return null;
  }

  /// 根据书名生成占位封面背景色
  static int colorForTitle(String title) {
    var hash = 0;
    for (final code in title.runes) {
      hash = code + ((hash << 5) - hash);
    }
    const palette = [
      0xFF5B9BD5,
      0xFF4ECDC4,
      0xFF9B59B6,
      0xFFFF8C42,
      0xFF6B9080,
      0xFFC7922A,
      0xFFE07A5F,
      0xFF3D5A80,
    ];
    return palette[hash.abs() % palette.length];
  }
}
