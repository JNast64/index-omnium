import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/shell/home_shell.dart';
import 'features/home/home_page.dart';
import 'features/search/search_page.dart';
import 'features/lists/my_lists_page.dart';
import 'features/lists/list_detail_page.dart';
import 'features/watchlist/watchlist_page.dart';
import 'features/diary/diary_page.dart';
import 'features/diary/diary_entry_page.dart';
import 'features/profile/profile_page.dart';
import 'features/detail/detail_page.dart';
import 'features/browse/type_browse_page.dart';
import 'features/auth/sign_up_page.dart';
import 'services/auth_service.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    // AuthService is a ChangeNotifier singleton; this makes the router rebuild
    // when Firebase auth state changes.
    refreshListenable: AuthService.instance,

    routes: [
      // --- AUTH ROUTES (outside shell) ---
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const SignUpPage(showLogin: true),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignUpPage(showLogin: false),
      ),

      // --- MAIN APP SHELL ---
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (c, st) =>
                SearchPage(initialQuery: st.uri.queryParameters['q'] ?? ''),
          ),
          GoRoute(
            path: '/lists',
            name: 'lists',
            builder: (_, __) => const MyListsPage(),
          ),
          GoRoute(
            path: '/lists/:id',
            name: 'listDetail',
            builder: (c, st) => ListDetailPage(
              listId: st.pathParameters['id']!,
              initialList: st.extra,
            ),
          ),
          GoRoute(
            path: '/watchlist',
            name: 'watchlist',
            builder: (_, __) => const WatchlistPage(),
          ),
          GoRoute(
            path: '/diary',
            name: 'diary',
            builder: (_, __) => const DiaryPage(),
          ),
          GoRoute(
            path: '/diaryEntry/:entryId',
            name: 'diaryEntry',
            builder: (c, st) =>
                DiaryEntryPage(entryId: st.pathParameters['entryId']!),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/detail/:id',
            name: 'detail',
            builder: (c, st) => DetailPage(
              itemId: st.pathParameters['id']!,
              initialItem: st.extra,
            ),
          ),
          GoRoute(
            path: '/browse/:type',
            name: 'browseType',
            builder: (c, st) =>
                TypeBrowsePage(type: st.pathParameters['type']!),
          ),
        ],
      ),
    ],

    // --- LOGIN GATING ---
    redirect: (context, state) {
      final loggedIn = AuthService.instance.currentUser != null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // Not logged in → force auth
      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      // Already logged in → don’t let them sit on auth screens
      if (loggedIn && loggingIn) {
        return '/';
      }

      return null;
    },
  );
}
