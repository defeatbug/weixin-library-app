import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../config/app_colors.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/wr_coming_soon.dart';
import '../../widgets/wr_search_bar.dart';

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

  static const _categories = ['分类', '榜单', '书单', '会员', '免费'];
  int _activeCategory = 4;
  String? _fileTypeFilter;
  String _sectionTitle = '为你推荐';

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final sort = _sortParams();
      final result = await BookApi.getBooks(
        page: _page,
        size: _pageSize,
        sortBy: sort.$1,
        sortDir: sort.$2,
      );
      if (!mounted) return;

      var items = GraphQLHelper.getItemsFromResult(
        result,
        Book.fromJson,
        ['books', 'items'],
      );
      items = _applyClientFilter(items);

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

  (String, String) _sortParams() {
    switch (_activeCategory) {
      case 1:
        return ('averageRating', 'desc');
      case 2:
        return ('reviewCount', 'desc');
      default:
        return ('createdAt', 'desc');
    }
  }

  List<Book> _applyClientFilter(List<Book> items) {
    var result = List<Book>.from(items);

    if (_fileTypeFilter != null) {
      result = result
          .where((b) => b.fileType.toUpperCase() == _fileTypeFilter)
          .toList();
    }

    switch (_activeCategory) {
      case 1:
        result.sort((a, b) {
          final ra = a.averageRating ?? 0;
          final rb = b.averageRating ?? 0;
          return rb.compareTo(ra);
        });
      case 2:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case 4:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  Future<void> _refresh() async {
    _page = 0;
    _books.clear();
    _hasMore = true;
    await _loadMore();
  }

  void _onCategoryTap(int index) {
    if (index == 0) {
      _showCategorySheet();
      return;
    }
    if (index == 3) {
      showComingSoonSheet(context, title: '会员专区');
      return;
    }

    setState(() {
      _activeCategory = index;
      _fileTypeFilter = null;
      _sectionTitle = switch (index) {
        1 => '热门榜单',
        2 => '热门书单',
        4 => '免费好书',
        _ => '为你推荐',
      };
    });
    _refresh();
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...['全部', 'EPUB', 'TXT'].map((type) {
              final selected = (type == '全部' && _fileTypeFilter == null) ||
                  _fileTypeFilter == type;
              return ListTile(
                title: Text(type),
                trailing: selected
                    ? Icon(Icons.check, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeCategory = 0;
                    _fileTypeFilter = type == '全部' ? null : type;
                    _sectionTitle = _fileTypeFilter == null
                        ? '全部分类'
                        : '$_fileTypeFilter 书籍';
                  });
                  _refresh();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const WrSearchBar(placeholder: '搜索书名、作者'),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    }

    if (_hasError && _books.isEmpty) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildCategoryRow(),
            _buildWeeklyReading(),
            _buildRecommendSection(),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _activeCategory == index;
          return GestureDetector(
            onTap: () => _onCategoryTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categories[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: selected ? AppColors.primary : AppColors.textHint,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyReading() {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateTime.now().weekday - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本周阅读',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  _books.isEmpty ? '0 分钟' : '阅读 ${_books.length.clamp(0, 99)} 本',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final isToday = i == today;
                    return Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.searchBg,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: isToday
                              ? const Icon(Icons.check, size: 8, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 9,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 110,
              child: _books.isEmpty
                  ? _buildPlaceholderCovers()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _books.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return GestureDetector(
                          onTap: () => context.push('/book/${book.id}'),
                          child: BookCover(
                            coverUrl: book.coverUrl,
                            fileUrl: book.fileUrl,
                            fileType: book.fileType,
                            title: book.title,
                            width: 72,
                            height: 96,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCovers() {
    return Row(
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
          child: Container(
            width: 72,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.menu_book, color: AppColors.textHint),
          ),
        );
      }),
    );
  }

  Widget _buildRecommendSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sectionTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_books.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无图书',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.52,
              ),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return GestureDetector(
                  onTap: () => context.push('/book/${book.id}'),
                  child: _RecommendBookCard(book: book),
                );
              },
            ),
          const SizedBox(height: 16),
          if (_books.isNotEmpty)
            GestureDetector(
              onTap: _refresh,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '换一批',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off,
              size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('加载失败'),
          const SizedBox(height: 12),
          TextButton(onPressed: _refresh, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _RecommendBookCard extends StatelessWidget {
  final Book book;

  const _RecommendBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return BookCover(
                coverUrl: book.coverUrl,
                fileUrl: book.fileUrl,
                fileType: book.fileType,
                title: book.title,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                radius: 8,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        if (book.averageRating != null && book.averageRating! > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${book.averageRating!.toStringAsFixed(1)} 分',
            style: TextStyle(fontSize: 12, color: AppColors.iconOrange),
          ),
        ],
      ],
    );
  }
}
