import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import 'token_storage.dart';

/// Shared Dio instance used by every repository in the app.
///
/// Two things happen automatically for every request:
/// 1. The stored JWT access token is attached as an Authorization header —
///    repositories never have to add it manually.
/// 2. If the server returns 401 (token expired), this client silently
///    calls /auth/refresh/, saves the new token, and retries the original
///    request — so the user never gets logged out just because their
///    1-hour access token expired mid-session.
class DioClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  DioClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach the access token to every outgoing request
          final token = await _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          // Don't try to refresh if the failing request is itself an auth
          // endpoint — that would cause an infinite loop
          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/');

          if (isUnauthorized && !isAuthEndpoint) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry the original request with the new access token
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Calls /api/auth/refresh/ with the stored refresh token.
  /// Saves the new access token if successful, clears storage on failure.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Use a plain Dio without interceptors to avoid recursion
      final response = await Dio(
        BaseOptions(baseUrl: AppConstants.apiBaseUrl),
      ).post('/auth/refresh/', data: {'refresh': refreshToken});

      final newAccess = response.data['access'] as String;
      await _tokenStorage.saveTokens(
        access: newAccess,
        refresh: refreshToken,
      );
      return true;
    } catch (_) {
      // Refresh token is also expired — force the user to log in again
      await _tokenStorage.clear();
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final newToken = await _tokenStorage.getAccessToken();
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $newToken',
        },
      ),
    );
  }
}
