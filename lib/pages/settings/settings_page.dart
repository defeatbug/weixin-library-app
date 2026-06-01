import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/current_user.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTheme.version,
      builder: (context, _, __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('设置')),
        body: ListView(
          children: [
            _buildSection([
              _SettingsTile(
                title: '深色模式',
                trailing: appTheme.brightnessStateLabel,
                onTap: () => context.push('/settings/dark_mode'),
              ),
              const _SettingsTile(
                title: '翻页方式',
                trailing: '左右滑动',
              ),
            ]),
            _buildSection([
              const _SettingsTile(title: '通知'),
              const _SettingsTile(title: '登录设备', trailing: '1'),
              const _SettingsTile(title: '清理缓存'),
            ]),
            _buildSection([
              const _SettingsTile(title: '关于微信读书'),
              const _SettingsTile(title: '帮助与反馈'),
            ]),
            const SizedBox(height: 24),
            _buildLogout(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 0.5, color: AppColors.divider, indent: 16),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: const Text(
          '退出登录',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFF453A)),
        ),
        onTap: () async {
          await CurrentUser.instance.logout();
          if (!context.mounted) return;
          context.go('/welcome');
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
        ],
      ),
      onTap: onTap,
    );
  }
}
