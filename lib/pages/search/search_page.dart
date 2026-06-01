import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../config/app_colors.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';
import '../../widgets/book_cover.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Book> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _hasError = false;
    });

    try {
      final result = await BookApi.searchBooks(query: query.trim());
      if (!mounted) return;

      setState(() {
        _results = GraphQLHelper.getItemsFromResult(
          result, Book.fromJson, ['searchBooks', 'items'],
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.searchBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '搜索书名、作者...',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textHint),
            ),
            onSubmitted: _search,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_searchController.text),
            child: const Text('搜索'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_hasError) {
      return _emptyState(
        icon: Icons.cloud_off,
        title: '搜索失败',
        action: TextButton(
          onPressed: () => _search(_searchController.text),
          child: const Text('重试'),
        ),
      );
    }

    if (!_hasSearched) {
      return _emptyState(
        icon: Icons.search,
        title: '搜索你想读的书',
      );
    }

    if (_results.isEmpty) {
      return _emptyState(
        icon: Icons.search_off,
        title: '没有找到相关图书',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = _results[index];
        return _SearchResultCard(
          book: book,
          onTap: () => context.push('/book/${book.id}'),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppColors.textSecondary)),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _SearchResultCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            BookCover(
              coverUrl: book.coverUrl,
              fileUrl: book.fileUrl,
              fileType: book.fileType,
              title: book.title,
              width: 52,
              height: 72,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (book.averageRating != null && book.averageRating! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${book.averageRating!.toStringAsFixed(1)} 分',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.iconOrange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
