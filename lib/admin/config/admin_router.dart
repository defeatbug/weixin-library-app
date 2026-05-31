import 'package:flutter/material.dart';

class AdminRouter {
  static const booksPath = '/admin/books';
  static const usersPath = '/admin/users';

  static const sidebarItems = [
    AdminSidebarItem(
      icon: Icons.auto_stories,
      label: '图书管理',
      path: booksPath,
    ),
    AdminSidebarItem(
      icon: Icons.people,
      label: '用户管理',
      path: usersPath,
    ),
  ];
}

class AdminSidebarItem {
  final IconData icon;
  final String label;
  final String path;

  const AdminSidebarItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}
