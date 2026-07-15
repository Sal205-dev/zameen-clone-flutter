import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';

/// Thin wrapper around flutter_secure_storage.
/// Stores JWT tokens in the device's encrypted keystore (Android Keystore /
/// iOS Keychain) — much safer than SharedPreferences or plain files.
class TokenStorage {
  final _storage = const FlutterSecureStorage(
    // Android: use EncryptedSharedPreferences for extra security
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: access);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  /// Wipes both tokens — called on logout.
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<bool> hasToken() async =>
      (await getAccessToken()) != null;
}
