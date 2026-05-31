import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin/pages/book/a_books_page.dart';
import '../admin/pages/user/a_users_page.dart';
import '../models/current_user.dart';
import '../pages/bookshelf/bookshelf_page.dart';
import '../pages/book_detail/book_detail_page.dart';
import '../pages/discover/discover_page.dart';
import '../pages/friends/friend_feed_page.dart';
import '../pages/login/login_page.dart';
import '../pages/main/main_desktop_page.dart';
import '../pages/main/main_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/reader/reader_page.dart';
import '../pages/add_book/add_book_page.dart';
import '../pages/search/search_page.dart';
import '../pages/welcome/welcome_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: _authGuard,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('路由错误: ${state.error}'),
      ),
    ),
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          const WelcomePage(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          const LoginPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _noTransitionPage(
              context,
              state,
              const BookshelfPage(),
            ),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => _noTransitionPage(
              context,
              state,
              const DiscoverPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _noTransitionPage(
              context,
              state,
              const ProfilePage(),
            ),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (context, state) => _noTransitionPage(
              context,
              state,
              const FriendFeedPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/book/:id',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          BookDetailPage(bookId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/reader/:id',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          ReaderPage(bookId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          const SearchPage(),
        ),
      ),
      GoRoute(
        path: '/add-book',
        pageBuilder: (context, state) => _fadeTransitionPage(
          context,
          state,
          const AddBookPage(),
        ),
      ),

      // ── Admin routes (desktop sidebar layout) ──
      ShellRoute(
        builder: (context, state, child) => MainDesktopPage(child: child),
        routes: [
          GoRoute(
            path: '/admin/books',
            pageBuilder: (context, state) => _fadeTransitionPage(
              context, state, const ABooksPage(),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => _fadeTransitionPage(
              context, state, const AUsersPage(),
            ),
          ),
        ],
      ),
    ],
  );

  static String? _authGuard(BuildContext context, GoRouterState state) {
    final loggedIn = CurrentUser.instance.loggedIn;
    final path = state.fullPath;
    if (path == null) return null;

    final publicPaths = ['/welcome', '/login'];
    final isPublic = publicPaths.contains(path);

    if (!loggedIn && !isPublic) return '/welcome';
    if (loggedIn && isPublic) return '/';

    return null;
  }

  static Page _fadeTransitionPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Page _noTransitionPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}
