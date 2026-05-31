import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../admin/config/admin_router.dart';
import '../../models/current_user.dart';

class MainDesktopPage extends StatefulWidget {
  final Widget? child;
  const MainDesktopPage({super.key, this.child});

  @override
  State<MainDesktopPage> createState() => _MainDesktopPageState();
}

class _MainDesktopPageState extends State<MainDesktopPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = CurrentUser.instance.email == 'admin@weixin.com';
    final sidebarItems = isAdmin ? AdminRouter.sidebarItems : <AdminSidebarItem>[];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Material(
            elevation: 1,
            child: SizedBox(
              width: 56,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // App icon
                  Icon(Icons.auto_stories, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(height: 24),

                  // Main app navigation
                  _sidebarIcon(
                    Icons.menu_book_outlined,
                    Icons.menu_book,
                    '阅读',
                    '/',
                  ),
                  _sidebarIcon(
                    Icons.store_outlined,
                    Icons.store,
                    '书城',
                    '/discover',
                  ),
                  _sidebarIcon(
                    Icons.people_outline,
                    Icons.people,
                    '书友',
                    '/friends',
                  ),
                  _sidebarIcon(
                    Icons.person_outline,
                    Icons.person,
                    '我',
                    '/profile',
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    const Divider(indent: 12, endIndent: 12),
                    const SizedBox(height: 4),
                    ...sidebarItems.map((item) => _sidebarIcon(
                      item.icon,
                      item.icon,
                      item.label,
                      item.path,
                      isAdminItem: true,
                    )),
                  ],
                ],
              ),
            ),
          ),

          // Divider
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),

          // Content area
          Expanded(
            child: widget.child ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, IconData activeIcon, String tooltip, String path, {bool isAdminItem = false}) {
    final isActive = GoRouterState.of(context).uri.toString() == path;
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => context.go(path),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 22,
            color: isActive
                ? theme.colorScheme.primary
                : isAdminItem
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
