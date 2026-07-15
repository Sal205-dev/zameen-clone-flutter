class AppConstants {
  /// Backend is deployed on Railway — reachable from any device with
  /// internet access, no need to match platform/emulator/LAN IP anymore.
  static String get apiBaseUrl =>
      'https://dha-backend-production.up.railway.app/api';

  // Keys used by flutter_secure_storage to save the JWT tokens
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
