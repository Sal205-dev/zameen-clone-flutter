import 'package:dio/dio.dart';
import '../../../core/network/token_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dio, this._tokenStorage);

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      await _dio.post('/auth/signup/', data: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'username': username,
        'password': password,
      });
      await _tokenStorage.saveTokens(
        access: response.data['access'] as String,
        refresh: response.data['refresh'] as String,
      );
      return UserModel.fromJson(
          response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// GET /api/auth/check-username/?username=xxx
  /// Returns a map with keys:
  ///   available (bool), status (String), message (String)
  /// Called live from the signup form with a debounce — the backend checks
  /// format, length, character set, and database uniqueness in one call.
  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await _dio.get(
        '/auth/check-username/',
        queryParameters: {'username': username},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (_) {
      // If the server is unreachable, fail silently — the user can still
      // submit; the signup endpoint will catch duplicates server-side.
      return {
        'available': true,
        'status': 'unknown',
        'message': '',
      };
    }
  }

  /// PATCH /api/auth/me/ — update the logged-in user's own profile.
  /// Only sends fields that are non-null — safe to call with only the
  /// fields you want to change (PATCH is partial, not full replace).
  Future<UserModel> updateProfile({String? username}) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;

      final response = await _dio.patch('/auth/me/', data: data);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();
  Future<bool> isLoggedIn() => _tokenStorage.hasToken();

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String) return value;
      }
      if (data.containsKey('detail')) return data['detail'].toString();
    }
    switch (e.response?.statusCode) {
      case 400: return 'Invalid details. Please check your input.';
      case 401: return 'Incorrect username or password.';
      case 500: return 'Server error. Please try again later.';
      default:  return 'Could not connect to server. Is it running?';
    }
  }
}
