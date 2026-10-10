import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/auth_failure.dart';
import '../domain/usuario.dart';

/// Única puerta a la autenticación: habla con la API y con el almacenamiento seguro.
/// La UI nunca toca Dio ni el storage directamente.
class AuthRepository {
  AuthRepository({required ApiClient api, required SessionStorage storage})
    : _dio = api.dio,
      _storage = storage;

  final Dio _dio;
  final SessionStorage _storage;

  /// Inicia sesión y comprueba que la cuenta sea de Inspector Técnico.
  /// Lanza [AuthFailure] con el motivo si algo falla.
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        ApiRutas.login,
        data: {'email': email, 'password': password},
      );
      await _storage.saveTokens(
        access: respuesta.data!['access'] as String,
        refresh: respuesta.data!['refresh'] as String,
      );

      final usuario = await _consultarPerfil();
      if (!usuario.esInspector) {
        await _storage.clear();
        throw const AuthFailure(AuthFailureTipo.noEsInspector);
      }
      await _storage.saveUsuarioJson(usuario.toJsonString());
      return usuario;
    } on DioException catch (e) {
      await _storage.clear();
      throw _traducir(e);
    }
  }

  /// Recupera la sesión al abrir la app. **Funciona sin conexión**: si no se puede
  /// consultar al servidor, devuelve el último usuario conocido. Solo devuelve `null`
  /// (sin sesión) si no hay tokens, o si el servidor confirma que la sesión ya no vale.
  Future<Usuario?> restaurarSesion() async {
    if (await _storage.readRefreshToken() == null) return null;
    final guardado = await _storage.readUsuarioJson();

    try {
      final usuario = await _consultarPerfil();
      if (!usuario.esInspector) {
        await _storage.clear();
        return null;
      }
      await _storage.saveUsuarioJson(usuario.toJsonString());
      return usuario;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clear();
        return null;
      }
      // Sin red o servidor caído: se confía en el último usuario conocido
      return guardado == null ? null : Usuario.fromJsonString(guardado);
    }
  }

  Future<void> cerrarSesion() => _storage.clear();

  Future<Usuario> _consultarPerfil() async {
    final respuesta = await _dio.get<Map<String, dynamic>>(ApiRutas.perfil);
    return Usuario.fromJson(respuesta.data!);
  }

  AuthFailure _traducir(DioException e) {
    // Solo en debug: el mensaje al usuario es genérico, el motivo técnico va al log.
    if (kDebugMode) {
      debugPrint(
        'AuthRepository: ${e.type.name} · estado=${e.response?.statusCode} · '
        '${e.requestOptions.uri} · ${e.error ?? e.message}',
      );
    }
    final estado = e.response?.statusCode;
    if (estado == 401 || estado == 400) {
      return const AuthFailure(AuthFailureTipo.credencialesInvalidas);
    }
    if (estado == null) return const AuthFailure(AuthFailureTipo.sinConexion);
    return const AuthFailure(AuthFailureTipo.servidor);
  }
}
