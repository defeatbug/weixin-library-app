import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/wr_bottom_nav.dart';

class MainPage extends StatelessWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/') return 1;
    if (location == '/friends') return 2;
    if (location == '/profile') return 3;
    return 0; // /discover
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: WrBottomNav(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/discover');
            case 1:
              context.go('/');
            case 2:
              context.go('/friends');
            case 3:
              context.go('/profile');
          }
        },
      ),
    );
  }
}
