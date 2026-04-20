import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/live_tv/presentation/pages/live_tv_page.dart';
import '../../features/movies/presentation/pages/movies_page.dart';
import '../../features/profiles/presentation/pages/profile_select_page.dart';
import '../../features/series/presentation/pages/series_page.dart';
import '../../features/sports/presentation/pages/sports_page.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/player/presentation/pages/player_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/vod/presentation/pages/series_detail_page.dart';
import '../models/iptv_provider.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/main_scaffold.dart';

// ── Auth notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends ChangeNotifier {
  bool _isLoading = true;
  bool _hasCode = false;

  bool get isLoading => _isLoading;
  bool get hasCode => _hasCode;

  Future<void> init() async {
    _isLoading = true;
    final provider = await IptvProvider.load();
    _hasCode = provider != null &&
        provider.workingHost.isNotEmpty &&
        provider.username.isNotEmpty;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => init();
}

late final AuthNotifier authNotifier;
final authNotifierProvider =
    Provider<AuthNotifier>((_) => authNotifier);

// ── Profile notifier — wraps active profile for router refresh ────────────────
class ProfileNotifier extends ChangeNotifier {
  AppProfile? _profile;
  AppProfile? get profile => _profile;

  void setProfile(AppProfile? p) {
    _profile = p;
    notifyListeners();
  }
}

final profileNotifier = ProfileNotifier();

// ── Combined listenable ───────────────────────────────────────────────────────
class _CombinedNotifier extends ChangeNotifier {
  _CombinedNotifier(this._a, this._b) {
    _a.addListener(notifyListeners);
    _b.addListener(notifyListeners);
  }
  final ChangeNotifier _a;
  final ChangeNotifier _b;

  @override
  void dispose() {
    _a.removeListener(notifyListeners);
    _b.removeListener(notifyListeners);
    super.dispose();
  }
}

final _combinedNotifier =
    _CombinedNotifier(authNotifier as ChangeNotifier,
        profileNotifier as ChangeNotifier);

// ── Navigator keys ────────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ── Router ────────────────────────────────────────────────────────────────────
GoRouter? _previousRouter;

final appRouterProvider = Provider<GoRouter>((ref) {
  _previousRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation:
        _previousRouter?.routerDelegate.currentConfiguration.fullPath ??
            '/splash',
    refreshListenable: _combinedNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Still loading auth
      if (authNotifier.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final loggedIn = authNotifier.hasCode;

      // Not logged in
      if (!loggedIn) {
        if (loc == '/splash') return '/login';
        if (loc != '/login') return '/login';
        return null;
      }

      // Logged in but no profile selected
      final hasProfile = profileNotifier.profile != null;
      if (!hasProfile) {
        if (loc == '/splash') return '/profiles';
        if (loc == '/login') return '/profiles';
        if (loc == '/profiles') return null;
        return '/profiles';
      }

      // Logged in + profile selected
      if (loc == '/splash' ||
          loc == '/login' ||
          loc == '/profiles') {
        return '/live-tv';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/profiles',
        builder: (_, __) => const ProfileSelectPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/live-tv',
            builder: (_, __) => const LiveTvPage(),
          ),
          GoRoute(
            path: '/movies',
            builder: (_, __) => const MoviesPage(),
          ),
          GoRoute(
            path: '/series',
            builder: (_, __) => const SeriesPage(),
          ),
          GoRoute(
            path: '/sports',
            builder: (_, __) => const SportsPage(),
          ),
          GoRoute(
            path: '/account',
            builder: (_, __) => const AccountPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchPage(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlayerPage(
            title: extra?['title'] ?? '',
            url: extra?['url'] ?? '',
            isLive: extra?['isLive'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/series-detail/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id =
              int.tryParse(state.pathParameters['id'] ?? '') ??
                  0;
          return SeriesDetailPage(seriesId: id, extra: extra);
        },
      ),
    ],
  );

  return _previousRouter!;
});
