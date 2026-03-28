import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage keys for the customer session.
///
/// Use [clearAuthStorage] on logout and anywhere the session must be wiped
/// (e.g. Dio 401), so access, refresh, and cached profile are removed together.
class AuthStorageKeys {
  AuthStorageKeys._();

  /// Bearer access token (JWT or opaque).
  static const accessToken = 'customer_token';

  /// Refresh token when the backend issues one; may be absent.
  static const refreshToken = 'customer_refresh_token';

  /// JSON-encoded customer snapshot from last login, refresh, or profile update.
  static const customerSnapshot = 'customer_snapshot';
}

/// Removes access token, refresh token, and cached customer snapshot.
Future<void> clearAuthStorage(FlutterSecureStorage storage) async {
  await storage.delete(key: AuthStorageKeys.accessToken);
  await storage.delete(key: AuthStorageKeys.refreshToken);
  await storage.delete(key: AuthStorageKeys.customerSnapshot);
}
