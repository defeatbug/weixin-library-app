import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../api/api_admin.dart';
import '../../../helpers/graphql_helper.dart';
import '../../../models/book.dart';

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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiAdmin.getAdminBooks(
        page: _page, size: _pageSize, search: _search,
      );
      if (!mounted) return;
      setState(() {
        _books.clear();
        _books.addAll(GraphQLHelper.getItemsFromResult(
          result, Book.fromJson, ['adminBooks', 'items'],
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
    final theme = Theme.of(context);

    return Scaffold(
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索书名或作者...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? const Center(child: Text('暂无图书'))
                    : _buildTable(theme),
          ),

          // Pagination
          _buildPagination(theme),
        ],
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('书名')),
            DataColumn(label: Text('作者')),
            DataColumn(label: Text('格式')),
            DataColumn(label: Text('评分')),
            DataColumn(label: Text('操作')),
          ],
          rows: _books.map((book) {
            return DataRow(cells: [
              DataCell(Text(book.title, overflow: TextOverflow.ellipsis)),
              DataCell(Text(book.author)),
              DataCell(Text(book.fileType)),
              DataCell(Text(book.averageRating?.toStringAsFixed(1) ?? '-')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _showEditDialog(book),
                    child: const Text('编辑'),
                  ),
                  TextButton(
                    onPressed: () => _confirmDelete(book),
                    child: Text('删除', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    final totalPages = (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 0 ? () { _page--; _load(); } : null,
            child: const Text('上一页'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('第 ${_page + 1} 页 / 共 $totalPages 页 (${_total}条)'),
          ),
          TextButton(
            onPressed: (_page + 1) < totalPages ? () { _page++; _load(); } : null,
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
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '书名')),
              const SizedBox(height: 8),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: '作者')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '简介'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            await ApiAdmin.updateBook(book.id, {
              'title': titleCtrl.text.trim(),
              'author': authorCtrl.text.trim(),
              if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          }, child: const Text('保存')),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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
