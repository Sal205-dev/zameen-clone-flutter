import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/listings/presentation/screens/post_listing_screen.dart';
import '../../features/listings/presentation/screens/property_detail_screen.dart';
import '../widgets/main_shell.dart';
import '../widgets/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // ── KEY FIX ────────────────────────────────────────────────────────
  // Do NOT use ref.watch(authNotifierProvider) here in the provider body.
  //
  // ref.watch causes routerProvider to rebuild every time auth state
  // changes (login success, login failure, logout, session restore).
  // Each rebuild returns a NEW GoRouter instance. MaterialApp.router
  // receiving a new router destroys and recreates the entire navigation
  // stack — including LoginScreen — wiping any local widget state like
  // _errorMessage back to null before the user ever sees it.
  //
  // The fix: read auth state INSIDE the redirect callback using ref.read.
  // ref.read never creates a subscription so routerProvider only builds
  // once. _AuthStateListenable still notifies the router to re-run
  // redirect whenever auth state changes — that part still works.
  // ──────────────────────────────────────────────────────────────────

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      // ref.read here — gets the current value without subscribing,
      // so this does not cause routerProvider to rebuild.
      final authState = ref.read(authNotifierProvider);

      final isLoading = authState.isLoading;
      final user = authState.value;
      final isLoggedIn = user != null;
      final isOnLoginRoute = state.matchedLocation == '/login';
      final isOnSplash = state.matchedLocation == '/';
      final isOnPostListing = state.matchedLocation == '/post-listing';

      // Still checking secure storage on app start, OR a login/signup
      // submission is in flight — both use AsyncValue.loading() so state
      // alone can't tell them apart. Location can: the session check only
      // ever runs while sitting on splash. If we're already on /login
      // (which also covers SignupScreen, pushed imperatively on top of it),
      // don't redirect — those screens show their own inline spinner, and
      // bouncing to splash would unmount them, losing the error message
      // that arrives a moment later.
      if (isLoading) {
        if (isOnLoginRoute) return null;
        return isOnSplash ? null : '/';
      }

      // Error state (e.g. wrong password) — NOT logged in, stay on login.
      // This is the case that was broken before: error state has a null
      // value, so isLoggedIn = false, and we correctly stay on /login.
      if (!isLoggedIn) return isOnLoginRoute ? null : '/login';

      // Successfully logged in — leave splash/login
      if (isOnSplash || isOnLoginRoute) return '/home';

      // Buyers can't reach the post-listing form
      if (isOnPostListing && !user.isAgent) return '/home';

      return null;
    },
    routes: [
      GoRoute(
          path: '/',
          builder: (context, __) =>
              _localeKeyed(context, const SplashScreen())),
      GoRoute(
          path: '/login',
          builder: (context, __) =>
              _localeKeyed(context, const LoginScreen())),
      GoRoute(
          path: '/home',
          builder: (context, __) =>
              _localeKeyed(context, const MainShell())),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _localeKeyed(context, PropertyDetailScreen(propertyId: id));
        },
      ),
      GoRoute(
        path: '/post-listing',
        builder: (context, __) =>
            _localeKeyed(context, const PostListingScreen()),
      ),
    ],
  );
});

/// Wraps a route's page in a key tied to the current locale so it's torn
/// down and rebuilt the instant the language changes — needed because
/// most of the app calls 'key'.tr() without a BuildContext, so those
/// widgets never register as EasyLocalization dependents and wouldn't
/// otherwise rebuild on their own. Keying at the page level (inside the
/// Navigator) avoids the black-flash a full MaterialApp/Navigator
/// teardown would cause if the key were placed higher up the tree.
Widget _localeKeyed(BuildContext context, Widget child) =>
    KeyedSubtree(key: ValueKey(context.locale), child: child);

/// Notifies go_router to re-run the redirect callback whenever auth state
/// changes. This is intentionally separate from routerProvider watching
/// authNotifierProvider — we want redirect re-evaluation without a full
/// router rebuild.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
