import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../config/app_colors.dart';
import '../../api/api_admin.dart';
import '../../../helpers/graphql_helper.dart';
import '../../../models/book.dart';
import '../../../widgets/book_cover.dart';
import '../../../widgets/wr_card.dart';
import '../../../widgets/wr_text_field.dart';

class ABooksPage extends StatefulWidget {
  const ABooksPage({super.key});

  @override
  State<ABooksPage> createState() => _ABooksPageState();
}

class _ABooksPageState extends State<ABooksPage> {
  final List<Book> _books = [];
  bool _isLoading = true;
  int _total = 0;
  int _page = 0;
  String? _search;
  final _searchController = TextEditingController();
  static const _pageSize = 20;

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
      final result = await ApiAdmin.getAdminBooks(
        page: _page,
        size: _pageSize,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _books.clear();
        _books.addAll(GraphQLHelper.getItemsFromResult(
          result,
          Book.fromJson,
          ['adminBooks', 'items'],
        ));
        _total = (result.data?['adminBooks']?['total'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String value) {
    _search = value.isEmpty ? null : value;
    _page = 0;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('图书管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加图书',
            onPressed: () => context.push('/add-book'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: WrTextField(
              controller: _searchController,
              hint: '搜索书名或作者',
              icon: Icons.search,
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _books.isEmpty
                    ? Center(
                        child: Text(
                          '暂无图书',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: _books.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final book = _books[index];
                            return WrCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BookCover(
                                    coverUrl: book.coverUrl,
                                    fileUrl: book.fileUrl,
                                    fileType: book.fileType,
                                    title: book.title,
                                    width: 48,
                                    height: 64,
                                  ),
                                  const SizedBox(width: 12),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          book.author,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _Tag(text: book.fileType),
                                            if (book.averageRating != null &&
                                                book.averageRating! > 0) ...[
                                              const SizedBox(width: 8),
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
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined,
                                            size: 20, color: AppColors.primary),
                                        onPressed: () => _showEditDialog(book),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            size: 20, color: AppColors.iconCoral),
                                        onPressed: () => _confirmDelete(book),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _pageSize).ceil().clamp(1, 9999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 0
                ? () {
                    _page--;
                    _load();
                  }
                : null,
            child: const Text('上一页'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${_page + 1} / $totalPages · $_total 条',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: (_page + 1) < totalPages
                ? () {
                    _page++;
                    _load();
                  }
                : null,
            child: const Text('下一页'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Book book) {
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);
    final descCtrl = TextEditingController(text: book.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑图书'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '书名'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: '作者'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '简介'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await ApiAdmin.updateBook(book.id, {
                'title': titleCtrl.text.trim(),
                'author': authorCtrl.text.trim(),
                if (descCtrl.text.trim().isNotEmpty)
                  'description': descCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除图书'),
        content: Text('确定删除《${book.title}》吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.iconCoral),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Api.mutate('mutation { deleteBook(id: "${book.id}") }');
      _load();
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppColors.primary),
      ),
    );
  }
}
