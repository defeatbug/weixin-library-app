import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/current_user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = CurrentUser.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // User info card
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user.displayName ?? '?')[0],
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? '用户',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Menu items
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('离线缓存'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.access_time_outlined),
            title: const Text('阅读时长'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('退出登录',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () async {
              await CurrentUser.instance.logout();
              if (!context.mounted) return;
              context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}
