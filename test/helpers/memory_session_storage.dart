import 'package:app_movil_uubr/core/storage/session_storage.dart';

/// Almacenamiento en memoria para pruebas (sin Keystore/Keychain).
class MemorySessionStorage implements SessionStorage {
  String? access;
  String? refresh;
  String? usuarioJson;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    this.access = access;
    if (refresh != null) this.refresh = refresh;
  }

  @override
  Future<String?> readUsuarioJson() async => usuarioJson;

  @override
  Future<void> saveUsuarioJson(String json) async => usuarioJson = json;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    usuarioJson = null;
  }
}
