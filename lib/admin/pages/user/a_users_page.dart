import 'package:flutter/material.dart';

import '../../api/api_admin.dart';
import '../../../helpers/graphql_helper.dart';

class AUsersPage extends StatefulWidget {
  const AUsersPage({super.key});

  @override
  State<AUsersPage> createState() => _AUsersPageState();
}

class _AUsersPageState extends State<AUsersPage> {
  List<Map<String, dynamic>> _users = [];
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
      final result = await ApiAdmin.getAdminUsers(
        page: _page, size: _pageSize, search: _search,
      );
      if (!mounted) return;
      final items = GraphQLHelper.getItemsFromResult(
        result, (m) => m, ['adminUsers', 'items'],
      );
      setState(() {
        _users = items.cast<Map<String, dynamic>>();
        _total = (result.data?['adminUsers']?['total'] as num?)?.toInt() ?? 0;
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
      appBar: AppBar(title: const Text('用户管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索邮箱或昵称...',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('暂无用户'))
                    : _buildTable(theme),
          ),
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
            DataColumn(label: Text('邮箱')),
            DataColumn(label: Text('昵称')),
            DataColumn(label: Text('角色')),
            DataColumn(label: Text('书架')),
            DataColumn(label: Text('评价')),
          ],
          rows: _users.map((user) {
            final role = user['role'] as String? ?? 'USER';
            return DataRow(cells: [
              DataCell(Text(user['email'] as String? ?? '')),
              DataCell(Text(user['displayName'] as String? ?? '')),
              DataCell(Chip(
                label: Text(role, style: const TextStyle(fontSize: 12)),
                backgroundColor: role == 'ADMIN'
                    ? Colors.amber.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
              )),
              DataCell(Text('${user['bookshelfCount'] ?? 0}')),
              DataCell(Text('${user['reviewCount'] ?? 0}')),
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
}
