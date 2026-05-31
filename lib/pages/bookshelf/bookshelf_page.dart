import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/bookshelf_api.dart';
import '../../api/social_api.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../models/bookshelf_item.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage>
    with SingleTickerProviderStateMixin {
  List<BookshelfItem>? _items;
  bool _isLoading = true;
  bool _hasError = false;
  int _bookshelfCount = 0;
  int _reviewCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        BookshelfApi.getMyBookshelf(),
        SocialApi.getMyStats(),
      ]);

      if (!mounted) return;

      setState(() {
        _items = GraphQLHelper.getItemsFromResult(
          results[0], BookshelfItem.fromJson, ['myBookshelf'],
        );
        final stats = results[1].data?['myStats'];
        if (stats != null) {
          _bookshelfCount = (stats['bookshelfCount'] as num?)?.toInt() ?? 0;
          _reviewCount = (stats['reviewCount'] as num?)?.toInt() ?? 0;
        }
        _hasError = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBook(String bookId) async {
    await BookshelfApi.removeFromBookshelf(bookId);
    _load();
  }

  Future<bool> _confirmRemove(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移出书架'),
        content: Text('确定将《$title》移出书架吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加图书',
            onPressed: () => context.push('/add-book'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton(theme)
          : _hasError
              ? _buildError(theme)
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(child: _buildHeader(theme)),
                    SliverToBoxAdapter(child: _buildStatsRow(theme)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: '在读'),
                            Tab(text: '读完'),
                          ],
                          labelColor: theme.colorScheme.onSurface,
                          unselectedLabelColor:
                              theme.colorScheme.onSurfaceVariant,
                          indicatorColor: theme.colorScheme.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookGrid(theme),
                      _buildFinishedGrid(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final items = _items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          // Reading time & ranking
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('本月阅读',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('0 分钟',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber[700], size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('读书排行',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('第 1 名',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Empty state
          if (items == null || items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.library_books_outlined, size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('重拾阅读的习惯',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('为生活埋下微小的信仰',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/discover'),
                        child: const Text('去书城'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/add-book'),
                        child: const Text('导入书籍'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final count = _items?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Text('在读 $count · 读完 0  笔记 $_reviewCount',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildBookGrid(ThemeData theme) {
    final items = _items;
    if (items == null || items.isEmpty) {
      return Center(child: _emptyState(theme, '暂无在读的书'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _BookGridCard(
            book: item.book,
            onTap: () => context.push('/book/${item.book.id}'),
            onLongPress: () async {
              final confirmed = await _confirmRemove(item.book.title);
              if (confirmed) _removeBook(item.book.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildFinishedGrid(ThemeData theme) {
    return Center(child: _emptyState(theme, '暂无读完的书'));
  }

  Widget _emptyState(ThemeData theme, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_outlined, size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          )),
          const SizedBox(height: 6),
          Container(height: 10, width: 60,
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('加载失败', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _BookGridCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookGridCard({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                      child: Icon(Icons.auto_stories, size: 32,
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
