import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/bookshelf_api.dart';
import '../../api/reading_progress_api.dart';
import '../../config/app_colors.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../models/bookshelf_item.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/wr_search_bar.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  List<BookshelfItem>? _items;
  bool _isLoading = true;
  bool _hasError = false;
  int _activeFilter = 0;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final Map<String, double> _progressMap = {};

  static const _filters = ['默认', '更新', '进度', '推荐值', '书名', '分类', '字数'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await BookshelfApi.getMyBookshelf();
      if (!mounted) return;

      final items = GraphQLHelper.getItemsFromResult(
        result,
        BookshelfItem.fromJson,
        ['myBookshelf'],
      );

      if (_activeFilter == 2) {
        await _loadProgress(items);
      }

      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _loadProgress(List<BookshelfItem> items) async {
    _progressMap.clear();
    final results = await Future.wait(
      items.map((item) => ReadingProgressApi.getProgress(item.book.id)),
    );
    for (var i = 0; i < items.length; i++) {
      final progress = results[i].data?['readingProgress'];
      if (progress != null) {
        _progressMap[items[i].book.id] =
            (progress['percentage'] as num?)?.toDouble() ?? 0;
      }
    }
  }

  Future<void> _onFilterTap(int index) async {
    if (_activeFilter == index) return;
    setState(() {
      _activeFilter = index;
      _isLoading = true;
    });
    await _load();
  }

  List<BookshelfItem> _sortedItems(List<BookshelfItem> items) {
    final sorted = List<BookshelfItem>.from(items);

    switch (_activeFilter) {
      case 0:
        sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      case 1:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case 2:
        sorted.sort((a, b) {
          final pa = _progressMap[a.book.id] ?? 0;
          final pb = _progressMap[b.book.id] ?? 0;
          return pb.compareTo(pa);
        });
      case 3:
        sorted.sort((a, b) {
          final ra = a.book.averageRating ?? 0;
          final rb = b.book.averageRating ?? 0;
          return rb.compareTo(ra);
        });
      case 4:
        sorted.sort((a, b) => a.book.title.compareTo(b.book.title));
      case 5:
        sorted.sort((a, b) {
          final typeCmp = a.book.fileType.compareTo(b.book.fileType);
          return typeCmp != 0 ? typeCmp : a.book.title.compareTo(b.book.title);
        });
      case 6:
        sorted.sort((a, b) =>
            b.book.fileSizeBytes.compareTo(a.book.fileSizeBytes));
    }

    return sorted;
  }

  List<BookshelfItem> _filteredItems(List<BookshelfItem> items) {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return items;

    return items.where((item) {
      final book = item.book;
      return book.title.toLowerCase().contains(keyword) ||
          book.author.toLowerCase().contains(keyword);
    }).toList();
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

  void _exitSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isSearching ? _buildSearchField() : _buildSearchBar(),
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : _hasError
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return WrSearchBar(
      placeholder: '搜索书架',
      rightLabel: null,
      onTap: () => setState(() => _isSearching = true),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '搜索书名、作者',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textHint),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          TextButton(
            onPressed: _exitSearch,
            child: Text('取消', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            '书架',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/add-book'),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 4),
                Text(
                  '导入',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final selected = _activeFilter == index;
          return GestureDetector(
            onTap: () => _onFilterTap(index),
            child: Center(
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final items = _items;
    if (items == null || items.isEmpty) {
      return _buildEmptyState();
    }

    final displayItems = _sortedItems(_filteredItems(items));
    if (displayItems.isEmpty) {
      return Center(
        child: Text(
          '未找到相关书籍',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.55,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          final progress = _progressMap[item.book.id];
          return _BookGridCard(
            book: item.book,
            progress: _activeFilter == 2 ? progress : null,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '重拾阅读的习惯',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '为生活埋下微小的信仰',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () => context.go('/discover'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('去书城'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => context.push('/add-book'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('导入书籍'),
                  ),
                ),
              ],
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
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _BookGridCard extends StatelessWidget {
  final Book book;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookGridCard({
    required this.book,
    this.progress,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return BookCover(
                      coverUrl: book.coverUrl,
                      fileUrl: book.fileUrl,
                      fileType: book.fileType,
                      title: book.title,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
                if (progress != null && progress! > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(6),
                      ),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0, 1),
                        minHeight: 3,
                        backgroundColor: Colors.black26,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
