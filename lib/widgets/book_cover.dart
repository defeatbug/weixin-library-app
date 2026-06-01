import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../helpers/book_cover_helper.dart';

class BookCover extends StatelessWidget {
  final String? coverUrl;
  final String? fileUrl;
  final String? fileType;
  final String? title;
  final double width;
  final double height;
  final double radius;

  const BookCover({
    super.key,
    this.coverUrl,
    this.fileUrl,
    this.fileType,
    this.title,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final url = BookCoverHelper.resolveUrl(
      coverUrl: coverUrl,
      fileUrl: fileUrl,
      fileType: fileType,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildLoading();
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: AppColors.searchBg,
      alignment: Alignment.center,
      child: SizedBox(
        width: width * 0.25,
        height: width * 0.25,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final displayTitle = title?.trim();
    if (displayTitle != null && displayTitle.isNotEmpty) {
      final bgColor = Color(BookCoverHelper.colorForTitle(displayTitle));
      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayTitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.searchBg,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book, color: AppColors.textHint, size: width * 0.35),
    );
  }
}
