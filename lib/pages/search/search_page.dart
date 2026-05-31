import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/book.dart';

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
          result,
          Book.fromJson,
          ['searchBooks', 'items'],
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索书名、作者...',
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('搜索失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _search(_searchController.text),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('搜索你想读的书', style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('没有找到相关图书', style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final book = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 48,
              height: 64,
              color: theme.colorScheme.surfaceContainerHighest,
              child: book.coverUrl != null
                  ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.auto_stories),
            ),
          ),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(book.author, maxLines: 1),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.push('/book/${book.id}'),
        );
      },
    );
  }
}
