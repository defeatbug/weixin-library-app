import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/social_api.dart';
import '../../models/current_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _bookshelfCount = 0;
  int _reviewCount = 0;
  int _booksReadingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final result = await SocialApi.getMyStats();
      final stats = result.data?['myStats'];
      if (stats != null && mounted) {
        setState(() {
          _bookshelfCount = (stats['bookshelfCount'] as num?)?.toInt() ?? 0;
          _reviewCount = (stats['reviewCount'] as num?)?.toInt() ?? 0;
          _booksReadingCount =
              (stats['booksReadingCount'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {
      // Stats are optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = CurrentUser.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('我')),
      body: ListView(
        children: [
          // ── User info card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user.displayName ?? '?')[0],
                    style: TextStyle(
                        fontSize: 22, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? '用户',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),

          // ── Membership card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8C56D).withValues(alpha: 0.3),
                    const Color(0xFFF5DEB3).withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Color(0xFFC7922A), size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('成为付费会员',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('首月特惠 9 元/月',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC7922A),
                    ),
                    child: const Text('开通'),
                  ),
                ],
              ),
            ),
          ),

          // ── Assets bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                _assetItem(theme, '充值币', '0'),
                _assetItem(theme, '福利', '0'),
                _assetItem(theme, '余额', '0.00'),
                _assetItem(theme, '赠币', '0.00'),
              ],
            ),
          ),

          const Divider(),

          // ── Reading stats ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: Colors.amber[700], size: 22),
                    const SizedBox(width: 8),
                    Text('读书排行榜 · 第 1 名',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),

          // Reading time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 分钟',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('本月 3 分钟',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // ── In Reading / Finished ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _sectionBlock(theme, '在读', '$_booksReadingCount 本'),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outlineVariant),
                Expanded(
                  child: _sectionBlock(theme, '读完', '0 本'),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Menu items ──
          _menuTile(theme, Icons.edit_note, '笔记',
              _reviewCount > 0 ? '$_reviewCount 条' : '尚未留下笔记'),
          _menuTile(theme, Icons.subscriptions_outlined, '订阅', '尚未上架'),
          _menuTile(
              theme, Icons.collections_bookmark_outlined, '书单', '$_bookshelfCount 个'),

          const Divider(),

          _menuTile(theme, Icons.download_outlined, '离线缓存', ''),
          _menuTile(theme, Icons.access_time_outlined, '阅读时长', ''),
          _menuTile(theme, Icons.dark_mode_outlined, '深色模式', ''),
          _menuTile(theme, Icons.settings_outlined, '设置', ''),

          const Divider(),

          // ── Logout ──
          ListTile(
            leading:
                Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('退出登录',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () async {
              await CurrentUser.instance.logout();
              if (!context.mounted) return;
              context.go('/welcome');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _assetItem(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionBlock(ThemeData theme, String label, String value) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _menuTile(
      ThemeData theme, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
