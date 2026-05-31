import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final List<Book> _books = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  bool _hasError = false;
  int _page = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await BookApi.getBooks(page: _page, size: _pageSize);
      if (!mounted) return;

      final items = GraphQLHelper.getItemsFromResult(
        result,
        Book.fromJson,
        ['books', 'items'],
      );
      final total = result.data?['books']?['total'] as num? ?? 0;

      setState(() {
        _books.addAll(items);
        _page++;
        _hasMore = _books.length < total;
        _isLoading = false;
        _isInitialLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refresh() async {
    _page = 0;
    _books.clear();
    _hasMore = true;
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Initial loading
    if (_isInitialLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _SkeletonCard(),
      );
    }

    // Error state
    if (_hasError && _books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _refresh,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('暂无图书', style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: _books.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _books.length) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final book = _books[index];
            return _BookCard(
              book: book,
              onTap: () => context.push('/book/${book.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 12, width: 100,
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 4),
        Container(height: 10, width: 60,
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4))),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                image: book.coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(book.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: book.coverUrl == null
                  ? Center(
                      child: Icon(Icons.auto_stories, size: 40,
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (book.averageRating != null && book.averageRating! > 0) ...[
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.star, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(book.averageRating!.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.amber[700])),
            ]),
          ],
        ],
      ),
    );
  }
}
