import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../api/bookshelf_api.dart';
import '../../api/review_api.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../models/current_user.dart';
import '../../models/review.dart';

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
        results[0],
        Book.fromJson,
        ['book'],
      );
      _reviews = GraphQLHelper.getItemsFromResult(
        results[1],
        Review.fromJson,
        ['reviewsByBook', 'items'],
      );
      final shelfItems = GraphQLHelper.getItemsFromResult(
        results[2],
        (m) => m['book']['id'] as String,
        ['myBookshelf'],
      );
      _isOnShelf = (shelfItems as List).contains(widget.bookId);
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
                      color: Colors.amber[700],
                      size: 36,
                    ),
                    onPressed: () => setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '写下你的想法...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('delete'),
                child: Text('删除',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final book = _book;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('图书不存在')),
      );
    }

    final myReview = _myReview();

    return Scaffold(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover & Info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 120,
                      height: 180,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: book.coverUrl != null
                          ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.auto_stories, size: 40),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(book.author,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        if (book.publisher != null) ...[
                          const SizedBox(height: 4),
                          Text(book.publisher!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                        if (book.averageRating != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Icon(Icons.star, size: 20, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${book.averageRating!.toStringAsFixed(1)} (${book.reviewCount})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/reader/${book.id}'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('开始阅读'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _shelfLoading ? null : _toggleShelf,
                  child: Text(_isOnShelf ? '已在书架' : '加入书架'),
                ),
              ]),
            ),

            // Description
            if (book.description != null && book.description!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('内容简介',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(book.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.6)),
                  ],
                ),
              ),
            ],

            const Divider(height: 32),

            // Reviews section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('读者评论 (${book.reviewCount})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _showReviewDialog(existing: myReview),
                    icon: Icon(myReview != null ? Icons.edit : Icons.add),
                    label: Text(myReview != null ? '编辑我的评价' : '写评价'),
                  ),
                ],
              ),
            ),
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('暂无评论，来写第一条吧',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...List.generate(_reviews.length, (index) {
                final review = _reviews[index];
                final isMine = review.user.id == CurrentUser.instance.userId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      review.user.displayName.isNotEmpty
                          ? review.user.displayName[0]
                          : '?',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  title: Row(children: [
                    Text(review.user.displayName,
                        style: theme.textTheme.bodyMedium),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Text('(我)',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary)),
                    ],
                  ]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber[700],
                        );
                      })),
                      if (review.content != null) ...[
                        const SizedBox(height: 4),
                        Text(review.content!, maxLines: 3),
                      ],
                    ],
                  ),
                  onTap: isMine
                      ? () => _showReviewDialog(existing: review)
                      : null,
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
