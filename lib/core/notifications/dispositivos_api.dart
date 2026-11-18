import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// Alta y baja del teléfono en el servidor. Es una interfaz para poder sustituirla en las
/// pruebas.
abstract interface class DispositivosRegistro {
  Future<void> registrar(String token);

  Future<void> quitar(String token);
}

/// Implementación real, sobre la API del backend.
class DispositivosApi implements DispositivosRegistro {
  DispositivosApi(this._dio, {this.plataforma = 'android'});

  final Dio _dio;
  final String plataforma;

  /// Idempotente: se puede llamar en cada inicio y cuando Firebase renueva el token.
  @override
  Future<void> registrar(String token) => _dio.post<void>(
    ApiRutas.dispositivos,
    data: {'token': token, 'plataforma': plataforma},
  );

  @override
  Future<void> quitar(String token) =>
      _dio.delete<void>(ApiRutas.dispositivos, data: {'token': token});
}
