import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/social_api.dart';
import '../../config/app_colors.dart';
import '../../models/current_user.dart';
import '../../widgets/wr_card.dart';
import '../../widgets/wr_coming_soon.dart';

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

  void _showProfileInfo() {
    final user = CurrentUser.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (user.displayName ?? '?')[0],
                  style: TextStyle(
                    fontSize: 28,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? '用户',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email ?? '',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/settings');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('账号设置'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = CurrentUser.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildTopBar(),
            _buildUserHeader(user),
            const SizedBox(height: 12),
            _buildVipCard(),
            const SizedBox(height: 12),
            _buildAssetRow(),
            const SizedBox(height: 12),
            _buildReadingStats(),
            const SizedBox(height: 12),
            _buildReadingStatus(),
            const SizedBox(height: 12),
            _buildNotesAndSubscribe(),
            const SizedBox(height: 12),
            _buildBooklist(),
            if (CurrentUser.instance.email == 'admin@weixin.library') ...[
              const SizedBox(height: 12),
              _buildAdminSection(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showComingSoonSheet(context, title: '消息中心'),
            child: Icon(Icons.mail_outline, size: 22, color: AppColors.textPrimary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Icon(Icons.tune,
                size: 22, color: AppColors.textPrimary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(CurrentUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showProfileInfo,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (user.displayName ?? '?')[0],
                style: TextStyle(
                  fontSize: 22,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(
                    user.displayName ?? '用户',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => showComingSoonSheet(context, title: '阅读勋章'),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.searchBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.military_tech,
                              size: 12, color: AppColors.iconOrange),
                          const SizedBox(width: 2),
                          Text(
                            '勋章',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildVipCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WrCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => showComingSoonSheet(context, title: '付费会员'),
        child: Row(
          children: [
            const WrIconCircle(
              icon: Icons.all_inclusive,
              color: AppColors.iconYellow,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '成为付费会员',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.vipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '首月特惠 9 元/月',
                style: TextStyle(fontSize: 12, color: AppColors.vipGold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _assetCard(
              icon: Icons.monetization_on,
              iconColor: AppColors.iconYellow,
              title: '充值币',
              subtitle: '余额 0.00',
              onTap: () => showComingSoonSheet(context, title: '充值币'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _assetCard(
              icon: Icons.card_giftcard,
              iconColor: AppColors.iconOrange,
              title: '福利',
              subtitle: '0 天 | 赠币 0.00',
              onTap: () => showComingSoonSheet(context, title: '福利中心'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return WrCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          WrIconCircle(icon: icon, color: iconColor, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WrCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statRow(
              icon: Icons.bar_chart,
              iconColor: AppColors.iconOrange,
              title: '读书排行榜',
              trailing: '第 1 名',
              trailingSub: '3 分钟',
              onTap: () => showComingSoonSheet(context, title: '读书排行榜'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 0.5, color: AppColors.divider),
            ),
            _statRow(
              icon: Icons.access_time,
              iconColor: AppColors.iconCoral,
              title: '阅读时长',
              trailing: '5 分钟',
              trailingSub: '本月 3 分钟',
              onTap: () => showComingSoonSheet(context, title: '阅读时长'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
    required String trailingSub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          WrIconCircle(icon: icon, color: iconColor, size: 36),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                trailingSub,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _buildReadingStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statusCard(
              icon: Icons.menu_book,
              iconColor: AppColors.iconTeal,
              title: '在读',
              subtitle: _booksReadingCount > 0
                  ? '$_booksReadingCount 本'
                  : '暂无在读的书',
              onTap: () => context.go('/'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statusCard(
              icon: Icons.check_circle_outline,
              iconColor: AppColors.iconBlue,
              title: '读完',
              subtitle: '暂无读完的书',
              onTap: () => showSnack(context, '暂无已读完的书籍'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return WrCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          WrIconCircle(icon: icon, color: iconColor, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesAndSubscribe() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statusCard(
              icon: Icons.edit_note,
              iconColor: AppColors.iconBlue,
              title: '笔记',
              subtitle:
                  _reviewCount > 0 ? '$_reviewCount 条' : '尚未留下笔记',
              onTap: () => context.go('/friends'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statusCard(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.iconBlue,
              title: '订阅',
              subtitle: '尚未上架',
              onTap: () => showComingSoonSheet(context, title: '订阅更新'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooklist() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WrCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.go('/'),
        child: Row(
          children: [
            const WrIconCircle(
              icon: Icons.format_list_bulleted,
              color: AppColors.iconPurple,
              size: 36,
            ),
            const SizedBox(width: 12),
            Text(
              '书单',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$_bookshelfCount 个',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WrCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _adminTile(
              icon: Icons.menu_book_outlined,
              title: '图书管理',
              onTap: () => context.push('/admin/books'),
            ),
            Divider(height: 0.5, color: AppColors.divider),
            _adminTile(
              icon: Icons.people_outline,
              title: '用户管理',
              onTap: () => context.push('/admin/users'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
