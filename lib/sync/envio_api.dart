import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../core/network/api_client.dart';
import '../features/inspeccion/domain/acta_local.dart';
import 'envio_resultado.dart';

/// Las llamadas HTTP del envío de actas. Traduce los fallos de red y de servidor a
/// [EnvioDetenido] (cortan todo el envío) o los devuelve para que decida quien llama.
class EnvioApi {
  EnvioApi(this._dio);

  final Dio _dio;

  /// Pide al administrador los materiales nuevos. Un 400 o 409 (ya existe, ya hay una
  /// pendiente, datos no válidos) no sirve reintentarlo y no debe frenar el acta.
  Future<void> enviarSolicitudes(ActaLocal acta) async {
    for (final s in acta.solicitudesMaterial) {
      try {
        await llamar(
          () => _dio.post<void>(ApiRutas.solicitudesMaterial, data: s.toJson()),
        );
      } on DioException catch (e) {
        final estado = e.response?.statusCode;
        if (estado != 400 && estado != 409) rethrow;
      }
    }
  }

  /// Sube una foto. Devuelve `null` si no se puede (archivo borrado o rechazado como no
  /// válido): la inspección se envía igual, sin esa foto.
  Future<String?> subirFoto(EvidenciaActa foto) async {
    final archivo = File(foto.rutaLocal);
    if (!await archivo.exists()) return null;
    try {
      final respuesta = await llamar(
        () async => _dio.post<Map<String, dynamic>>(
          ApiRutas.subirEvidencia,
          data: FormData.fromMap({
            'imagen': await MultipartFile.fromFile(
              archivo.path,
              filename: p.basename(archivo.path),
              contentType: DioMediaType('image', 'jpeg'),
            ),
          }),
          // Una foto con señal débil tarda más que una petición normal (20 s): sin esto se
          // tomaría por "sin conexión" y se reintentaría sin fin.
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ),
      );
      return respuesta.data?['url_imagen'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return null;
      rethrow;
    }
  }

  /// Hace la llamada y traduce los fallos que cortan el envío completo.
  Future<Response<T>> llamar<T>(Future<Response<T>> Function() llamada) async {
    try {
      return await llamada();
    } on DioException catch (e) {
      final estado = e.response?.statusCode;
      if (e.response == null) {
        throw const EnvioDetenido(
          'Sin conexión: las actas se enviarán cuando haya señal.',
          sinConexion: true,
        );
      }
      if (estado == 400 || estado == 409) rethrow; // lo decide quien llama
      if (estado == 403) {
        throw const EnvioDetenido(
          'Tu cuenta no tiene permiso para enviar actas.',
        );
      }
      throw const EnvioDetenido(
        'El servidor no respondió bien. Se reintentará más tarde.',
      );
    }
  }

  /// Envía el acta completa. Devuelve el resultado que el servidor da para ella, o `null`
  /// si la respuesta no tiene la forma esperada.
  Future<Map<String, dynamic>?> sincronizar(ActaLocal acta) async {
    final respuesta = await llamar(
      () => _dio.post<Map<String, dynamic>>(
        ApiRutas.sincronizarActas,
        data: {
          'actas': [acta.toSyncJson()],
        },
      ),
    );
    final resultados = respuesta.data?['resultados'];
    return resultados is List && resultados.isNotEmpty
        ? resultados.first as Map<String, dynamic>
        : null;
  }
}
