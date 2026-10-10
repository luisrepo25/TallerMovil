import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/session_storage.dart';
import 'jwt.dart';

/// Inyecta el JWT en cada petición y lo mantiene vigente, igual que la web:
///  1. Antes de enviar, si el access token vence en < 30 s, lo **renueva de antemano**.
///  2. Las renovaciones simultáneas **comparten una sola petición**.
///  3. Si aun así llega un 401, renueva y reintenta una vez; si el refresh también
///     falló, avisa con [onSesionExpirada].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.dio,
    required this.dioSinInterceptores,
    required this.rutaRefresh,
    this.rutasPublicas = const [],
    this.onSesionExpirada,
  });

  final SessionStorage storage;
  final Dio dio;

  /// Cliente sin interceptores para pedir el refresh (evita bucles).
  final Dio dioSinInterceptores;
  final String rutaRefresh;
  final List<String> rutasPublicas;
  final void Function()? onSesionExpirada;

  Future<String?>? _renovacionEnCurso;

  bool _esPublica(String path) =>
      path.contains(rutaRefresh) || rutasPublicas.any(path.contains);

  /// Pide un access token nuevo. Devuelve `null` si no se pudo.
  Future<String?> _renovar() {
    return _renovacionEnCurso ??= () async {
      try {
        final refresh = await storage.readRefreshToken();
        if (refresh == null) return null;
        final respuesta = await dioSinInterceptores.post<Map<String, dynamic>>(
          rutaRefresh,
          data: {'refresh': refresh},
        );
        final access = respuesta.data?['access'] as String?;
        if (access != null) await storage.saveTokens(access: access);
        return access;
      } on DioException {
        return null;
      } finally {
        _renovacionEnCurso = null;
      }
    }();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_esPublica(options.path)) return handler.next(options);

    var token = await storage.readAccessToken();
    if (token != null && Jwt.venceProntoOYa(token)) {
      // Si no se pudo renovar (sin red), se envía igual: el resultado decidirá.
      token = await _renovar() ?? token;
    }
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final peticion = err.requestOptions;
    final es401 = err.response?.statusCode == 401;
    if (!es401 ||
        peticion.extra['reintentada'] == true ||
        _esPublica(peticion.path)) {
      return handler.next(err);
    }

    final nuevoToken = await _renovar();
    if (nuevoToken == null) {
      // Sin red no se puede renovar, pero eso no es una sesión vencida
      if (await storage.readRefreshToken() != null &&
          err.type != DioExceptionType.connectionError) {
        onSesionExpirada?.call();
      }
      return handler.next(err);
    }

    peticion.extra['reintentada'] = true;
    peticion.headers['Authorization'] = 'Bearer $nuevoToken';
    try {
      handler.resolve(await dio.fetch<dynamic>(peticion));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
