import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../api/api_admin.dart';
import '../../../helpers/graphql_helper.dart';
import '../../../widgets/wr_card.dart';
import '../../../widgets/wr_text_field.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiAdmin.getAdminUsers(
        page: _page,
        size: _pageSize,
        search: _search,
      );
      if (!mounted) return;
      final items = GraphQLHelper.getItemsFromResult(
        result,
        (m) => m,
        ['adminUsers', 'items'],
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('用户管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: WrTextField(
              controller: _searchController,
              hint: '搜索邮箱或昵称',
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
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          '暂无用户',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final role = user['role'] as String? ?? 'USER';
                            final isAdmin = role == 'ADMIN';
                            return WrCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isAdmin
                                        ? AppColors.vipBg
                                        : AppColors.primaryLight,
                                    child: Text(
                                      (user['displayName'] as String? ?? '?')
                                          .characters
                                          .first
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isAdmin
                                            ? AppColors.vipGold
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user['displayName'] as String? ??
                                                    '未命名',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            _RoleBadge(role: role),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['email'] as String? ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _StatChip(
                                              icon: Icons.library_books_outlined,
                                              label: '书架 ${user['bookshelfCount'] ?? 0}',
                                            ),
                                            const SizedBox(width: 12),
                                            _StatChip(
                                              icon: Icons.rate_review_outlined,
                                              label: '评价 ${user['reviewCount'] ?? 0}',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'ADMIN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.vipBg : AppColors.searchBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAdmin ? '管理员' : '用户',
        style: TextStyle(
          fontSize: 11,
          color: isAdmin ? AppColors.vipGold : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}
