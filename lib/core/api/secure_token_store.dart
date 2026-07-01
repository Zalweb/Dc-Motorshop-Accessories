import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over token persistence so the API client can be unit-tested with a fake.
abstract interface class TokenStore {
  Future<void> save({required String access, required String refresh});
  Future<String?> accessToken();
  Future<String?> refreshToken();
  Future<bool> hasSession();
  Future<void> clear();
}

/// Persists JWT access + refresh tokens in the platform keystore/keychain
/// (BACKEND_PLAN §2 — never SharedPreferences).
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'dc_access_token';
  static const _refreshKey = 'dc_refresh_token';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<bool> hasSession() async => (await refreshToken()) != null;

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
