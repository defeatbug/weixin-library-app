import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../api/bookshelf_api.dart';
import '../../api/review_api.dart';
import '../../config/app_colors.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../models/current_user.dart';
import '../../models/review.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/wr_card.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  Book? _book;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isOnShelf = false;
  bool _shelfLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      BookApi.getBook(widget.bookId),
      ReviewApi.getReviewsByBook(widget.bookId, size: 20),
      BookshelfApi.getMyBookshelf(),
    ]);

    if (!mounted) return;

    setState(() {
      _book = GraphQLHelper.getItemFromResult(
        results[0], Book.fromJson, ['book'],
      );
      _reviews = GraphQLHelper.getItemsFromResult(
        results[1], Review.fromJson, ['reviewsByBook', 'items'],
      );
      final shelfItems = GraphQLHelper.getItemsFromResult(
        results[2],
        (m) => m['book']['id'] as String,
        ['myBookshelf'],
      );
      _isOnShelf = shelfItems.contains(widget.bookId);
      _isLoading = false;
    });
  }

  Future<void> _toggleShelf() async {
    setState(() => _shelfLoading = true);
    if (_isOnShelf) {
      await BookshelfApi.removeFromBookshelf(widget.bookId);
    } else {
      await BookshelfApi.addToBookshelf(widget.bookId);
    }
    if (!mounted) return;
    setState(() {
      _isOnShelf = !_isOnShelf;
      _shelfLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isOnShelf ? '已加入书架' : '已从书架移除')),
    );
  }

  Future<void> _showReviewDialog({Review? existing}) async {
    int rating = existing?.rating ?? 5;
    final controller = TextEditingController(text: existing?.content ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? '编辑评价' : '写评价'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: AppColors.iconOrange,
                      size: 36,
                    ),
                    onPressed: () => setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '写下你的想法...',
                  filled: true,
                  fillColor: AppColors.searchBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('delete'),
                child: Text('删除', style: TextStyle(color: AppColors.iconCoral)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              child: Text(existing != null ? '保存' : '发布'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'delete') {
      await ReviewApi.deleteReview(existing!.id);
    } else if (result == 'save') {
      final content = controller.text.trim();
      if (existing != null) {
        await ReviewApi.updateReview(existing.id,
            rating: rating, content: content.isNotEmpty ? content : null);
      } else {
        await ReviewApi.createReview(widget.bookId, rating,
            content: content.isNotEmpty ? content : null);
      }
    }
    _load();
  }

  Review? _myReview() {
    final uid = CurrentUser.instance.userId;
    if (uid == null) return null;
    try {
      return _reviews.firstWhere((r) => r.user.id == uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final book = _book;
    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('图书不存在')),
      );
    }

    final myReview = _myReview();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isOnShelf ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _shelfLoading ? null : _toggleShelf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    coverUrl: book.coverUrl,
                    fileUrl: book.fileUrl,
                    fileType: book.fileType,
                    title: book.title,
                    width: 110,
                    height: 154,
                    radius: 8,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (book.publisher != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            book.publisher!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                        if (book.averageRating != null &&
                            book.averageRating! > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 18, color: AppColors.iconOrange),
                              const SizedBox(width: 4),
                              Text(
                                '${book.averageRating!.toStringAsFixed(1)} 推荐值',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.iconOrange,
                                ),
                              ),
                              Text(
                                ' · ${book.reviewCount} 人点评',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/reader/${book.id}'),
                        icon: const Icon(Icons.menu_book, size: 20),
                        label: const Text('开始阅读'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _shelfLoading ? null : _toggleShelf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(_isOnShelf ? '已在书架' : '加入书架'),
                    ),
                  ),
                ],
              ),
            ),
            if (book.description != null && book.description!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: WrCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '内容简介',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '读者评论 (${book.reviewCount})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showReviewDialog(existing: myReview),
                    icon: Icon(myReview != null ? Icons.edit : Icons.add,
                        size: 18),
                    label: Text(myReview != null ? '编辑评价' : '写评价'),
                  ),
                ],
              ),
            ),
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '暂无评论，来写第一条吧',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...List.generate(_reviews.length, (index) {
                final review = _reviews[index];
                final isMine = review.user.id == CurrentUser.instance.userId;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: WrCard(
                    padding: const EdgeInsets.all(14),
                    onTap: isMine
                        ? () => _showReviewDialog(existing: review)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                review.user.displayName.isNotEmpty
                                    ? review.user.displayName[0]
                                    : '?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                review.user.displayName +
                                    (isMine ? ' (我)' : ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: AppColors.iconOrange,
                                );
                              }),
                            ),
                          ],
                        ),
                        if (review.content != null &&
                            review.content!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            review.content!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
