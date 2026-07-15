import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

/// Provides a single AuthRepository instance wired to the real
/// Dio client and TokenStorage from the network layer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Holds the current auth state for the whole app.
///
/// AsyncValue<UserModel?> meaning:
///   loading      → app is checking for a stored session (shown as splash)
///   data(null)   → not logged in → go_router redirects to /login
///   data(user)   → logged in     → go_router redirects to /home
///   error        → something went wrong during login/signup
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // On every app start, check if a valid token exists in secure storage.
    // If it does, fetch the user profile from the real API to restore
    // the session — user skips the login screen entirely.
    final repo = ref.read(authRepositoryProvider);
    final hasToken = await repo.isLoggedIn();
    if (!hasToken) return null;

    try {
      return await repo.getCurrentUser();
    } catch (_) {
      // Token is expired or invalid — clear it and treat as logged out.
      // The DioClient's refresh interceptor already tried to refresh and
      // failed before this catch runs.
      await repo.logout();
      return null;
    }
  }

  /// Called by the signup screen.
  /// Signs up then immediately logs in so the user lands on the home
  /// screen without an extra step.
  Future<void> signup({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.signup(
        username: username,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      // Log in right after signup so tokens are stored
      return repo.login(username: username, password: password);
    });
  }

  /// Called by the login screen.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.login(username: username, password: password),
    );
  }

  /// Called by the logout button in profile/drawer.
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  /// Called by the edit profile screen.
  /// Updates the user's profile on the server and refreshes the local
  /// auth state so the greeting and any other UI shows the new values
  /// immediately without needing an app restart.
  Future<void> updateProfile({String? username}) async {
    final repo = ref.read(authRepositoryProvider);
    // Throws a String on error — caller should catch and display it.
    final updated = await repo.updateProfile(username: username);
    state = AsyncValue.data(updated);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
