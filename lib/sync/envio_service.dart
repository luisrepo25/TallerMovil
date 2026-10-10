import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../core/network/api_client.dart';
import '../features/inspeccion/data/actas_store.dart';
import '../features/inspeccion/domain/acta_edicion.dart';
import '../features/inspeccion/domain/acta_envio.dart';
import '../features/inspeccion/domain/acta_local.dart';

class ResultadoEnvio {
  const ResultadoEnvio({
    this.enviadas = 0,
    this.rechazadas = 0,
    this.pendientes = 0,
    this.fotosOmitidas = 0,
    this.sinConexion = false,
    this.aviso,
  });

  /// Actas que el servidor aceptó en esta corrida.
  final int enviadas;

  /// Actas que el servidor rechazó (quedan en el teléfono con el motivo).
  final int rechazadas;

  /// Actas que siguen esperando (sin conexión o servidor con problemas).
  final int pendientes;

  /// Fotos que no se pudieron subir (archivo borrado o imagen no válida) y viajaron sin ella.
  final int fotosOmitidas;
  final bool sinConexion;

  /// Problema que cortó el envío, listo para mostrar.
  final String? aviso;
}

/// Una condición que detiene el envío de TODAS las actas pendientes (no solo de la actual).
class _Detenido implements Exception {
  const _Detenido(this.aviso, {this.sinConexion = false});

  final String aviso;
  final bool sinConexion;
}

/// Envía al servidor las actas cerradas en el teléfono, de la más antigua a la más nueva.
///
/// Por cada acta, en este orden: solicitudes de material -> fotos -> acta. Cada paso es
/// **idempotente** (la solicitud y el acta llevan un `uuid_local`, y cada foto subida se
/// guarda al instante), así que un corte a la mitad se reintenta sin duplicar nada.
///
/// El orden importa: el servidor marca una infracción como reincidencia comparándola con las
/// demás actas del predio. Por eso, si un acta no se puede enviar (sin red, servidor caído)
/// se detiene todo y se reintenta después: no se salta a las siguientes.
class EnvioService {
  EnvioService({required ApiClient api, required ActasStore actas})
    : _dio = api.dio,
      _actas = actas;

  final Dio _dio;
  final ActasStore _actas;

  bool _enCurso = false;

  /// ¿Hay un envío corriendo? No se debe reabrir un acta mientras tanto.
  bool get enCurso => _enCurso;

  Future<int> contarPendientes() async =>
      (await _actas.pendientesDeEnvio()).length;

  Future<ResultadoEnvio> enviarPendientes() async {
    if (_enCurso) return const ResultadoEnvio();
    _enCurso = true;
    var enviadas = 0;
    var rechazadas = 0;
    var fotosOmitidas = 0;
    try {
      final pendientes = await _actas.pendientesDeEnvio();
      for (var i = 0; i < pendientes.length; i++) {
        try {
          final resultado = await _enviar(pendientes[i]);
          fotosOmitidas += resultado.fotosOmitidas;
          if (resultado.aceptada) {
            enviadas++;
          } else {
            rechazadas++;
          }
        } on _Detenido catch (corte) {
          return ResultadoEnvio(
            enviadas: enviadas,
            rechazadas: rechazadas,
            pendientes: pendientes.length - i,
            fotosOmitidas: fotosOmitidas,
            sinConexion: corte.sinConexion,
            aviso: corte.aviso,
          );
        }
      }
      return ResultadoEnvio(
        enviadas: enviadas,
        rechazadas: rechazadas,
        fotosOmitidas: fotosOmitidas,
      );
    } finally {
      _enCurso = false;
    }
  }

  Future<({bool aceptada, int fotosOmitidas})> _enviar(
    ActaLocal original,
  ) async {
    var acta = original;

    await _enviarSolicitudes(acta);

    var omitidas = 0;
    for (final foto in acta.evidenciasPorSubir) {
      final url = await _subirFoto(foto);
      if (url == null) {
        omitidas++;
        acta = acta.sinEvidencia(foto.rutaLocal);
      } else {
        acta = acta.conFotoSubida(foto.rutaLocal, url);
      }
      // Guardar ya: si el envío se corta, esta foto no se vuelve a subir
      await _actas.guardar(acta);
    }

    final respuesta = await _llamar(
      () => _dio.post<Map<String, dynamic>>(
        ApiRutas.sincronizarActas,
        data: {
          'actas': [acta.toSyncJson()],
        },
      ),
    );
    final resultados = respuesta.data?['resultados'];
    final r = resultados is List && resultados.isNotEmpty
        ? resultados.first as Map<String, dynamic>
        : null;
    if (r == null) {
      throw const _Detenido('El servidor respondió algo inesperado.');
    }

    switch (r['estado']) {
      case 'sincronizada' || 'ya_sincronizada':
        await _actas.guardar(
          acta.sincronizada(
            actaIdServidor: r['acta_id'] as int,
            cargaFuego: _numero(r['carga_fuego']),
            scoringRiesgo: _numero(r['scoring_riesgo']),
            clusterRiesgo: r['cluster_riesgo'] as String?,
          ),
        );
        return (aceptada: true, fotosOmitidas: omitidas);
      case 'rechazada':
        await _actas.guardar(acta.rechazadaPorServidor(_motivo(r)));
        return (aceptada: false, fotosOmitidas: omitidas);
      default: // error_temporal u otro: se reintenta más tarde
        throw const _Detenido(
          'El servidor no pudo procesar el acta. Se reintentará más tarde.',
        );
    }
  }

  /// Pide al administrador los materiales nuevos. Un 400 o 409 (ya existe, ya hay una
  /// pendiente, datos no válidos) no sirve reintentarlo y no debe frenar el acta.
  Future<void> _enviarSolicitudes(ActaLocal acta) async {
    for (final s in acta.solicitudesMaterial) {
      try {
        await _llamar(
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
  Future<String?> _subirFoto(EvidenciaActa foto) async {
    final archivo = File(foto.rutaLocal);
    if (!await archivo.exists()) return null;
    try {
      final respuesta = await _llamar(
        () async => _dio.post<Map<String, dynamic>>(
          ApiRutas.subirEvidencia,
          data: FormData.fromMap({
            'imagen': await MultipartFile.fromFile(
              archivo.path,
              filename: p.basename(archivo.path),
              contentType: DioMediaType('image', 'jpeg'),
            ),
          }),
        ),
      );
      return respuesta.data?['url_imagen'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return null;
      rethrow;
    }
  }

  /// Hace la llamada y traduce los fallos que cortan el envío completo.
  Future<Response<T>> _llamar<T>(Future<Response<T>> Function() llamada) async {
    try {
      return await llamada();
    } on DioException catch (e) {
      final estado = e.response?.statusCode;
      if (e.response == null) {
        throw const _Detenido(
          'Sin conexión: las actas se enviarán cuando haya señal.',
          sinConexion: true,
        );
      }
      if (estado == 400 || estado == 409) rethrow; // lo decide quien llama
      if (estado == 403) {
        throw const _Detenido('Tu cuenta no tiene permiso para enviar actas.');
      }
      throw const _Detenido(
        'El servidor no respondió bien. Se reintentará más tarde.',
      );
    }
  }

  static double? _numero(Object? valor) =>
      valor == null ? null : double.tryParse(valor.toString());

  static String _motivo(Map<String, dynamic> r) {
    final detalle = r['detalle'];
    if (detalle is String && detalle.isNotEmpty) return detalle;
    if (detalle != null) return 'Datos no válidos: ${jsonEncode(detalle)}';
    return 'El servidor rechazó el acta.';
  }
}
