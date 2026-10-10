import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_storage.dart';

/// Implementación real: Keystore (Android) / Keychain (iOS).
/// Los tokens nunca van a `shared_preferences` ni a los logs.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'uubr_access_token';
  static const _kRefresh = 'uubr_refresh_token';
  static const _kUsuario = 'uubr_usuario';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _kAccess, value: access);
    // La renovación solo devuelve un access nuevo: el refresh se conserva.
    if (refresh != null) await _storage.write(key: _kRefresh, value: refresh);
  }

  @override
  Future<String?> readUsuarioJson() => _storage.read(key: _kUsuario);

  @override
  Future<void> saveUsuarioJson(String json) =>
      _storage.write(key: _kUsuario, value: json);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUsuario);
  }
}
