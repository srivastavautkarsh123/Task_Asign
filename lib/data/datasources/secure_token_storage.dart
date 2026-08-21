import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyExpiryTimestamp = 'expiry_timestamp';
  static const String _keyUserId = 'user_id';
  static const String _keyOrgId = 'org_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    required String userId,
    required String orgId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyExpiryTimestamp, value: expiry.toIso8601String());
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyOrgId, value: orgId);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);
  Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  Future<String?> getOrgId() async => await _storage.read(key: _keyOrgId);

  Future<DateTime?> getExpiryTimestamp() async {
    final raw = await _storage.read(key: _keyExpiryTimestamp);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiryTimestamp);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyOrgId);
  }
}
