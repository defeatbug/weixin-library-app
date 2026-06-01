import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../admin/config/admin_router.dart';
import '../../config/app_colors.dart';
import '../../models/current_user.dart';

class MainDesktopPage extends StatefulWidget {
  final Widget? child;
  const MainDesktopPage({super.key, this.child});

  @override
  State<MainDesktopPage> createState() => _MainDesktopPageState();
}

class _MainDesktopPageState extends State<MainDesktopPage> {
  static const _navItems = [
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, '阅读', '/discover'),
    _NavItem(Icons.library_books_outlined, Icons.library_books, '书架', '/'),
    _NavItem(Icons.public_outlined, Icons.public, '书友', '/friends'),
    _NavItem(Icons.person_outline, Icons.person, '我', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = CurrentUser.instance.email == 'admin@weixin.library';
    final sidebarItems =
        isAdmin ? AdminRouter.sidebarItems : <AdminSidebarItem>[];

    return Scaffold(
      body: Row(
        children: [
          Material(
            elevation: 1,
            child: SizedBox(
              width: 56,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Icon(Icons.auto_stories,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 24),
                  ..._navItems.map((item) => _sidebarIcon(item)),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    const Divider(indent: 12, endIndent: 12),
                    const SizedBox(height: 4),
                    ...sidebarItems.map((item) => _sidebarIcon(
                          _NavItem(item.icon, item.icon, item.label, item.path),
                          isAdminItem: true,
                        )),
                  ],
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(child: widget.child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _sidebarIcon(_NavItem item, {bool isAdminItem = false}) {
    final location = GoRouterState.of(context).uri.toString();
    final isActive = location == item.path;

    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: () => context.go(item.path),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            size: 22,
            color: isActive
                ? AppColors.primary
                : isAdminItem
                    ? AppColors.textHint.withValues(alpha: 0.6)
                    : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem(this.icon, this.activeIcon, this.label, this.path);
}
