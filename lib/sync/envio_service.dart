import 'dart:convert';

import '../core/network/api_client.dart';
import '../features/inspeccion/data/actas_store.dart';
import '../features/inspeccion/domain/acta_edicion.dart';
import '../features/inspeccion/domain/acta_envio.dart';
import '../features/inspeccion/domain/acta_local.dart';
import 'envio_api.dart';
import 'envio_resultado.dart';

export 'envio_resultado.dart';

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
    : _api = EnvioApi(api.dio),
      _actas = actas;

  final EnvioApi _api;
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
        } on EnvioDetenido catch (corte) {
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

    await _api.enviarSolicitudes(acta);

    var omitidas = 0;
    for (final foto in acta.evidenciasPorSubir) {
      final url = await _api.subirFoto(foto);
      if (url == null) {
        omitidas++;
        acta = acta.sinEvidencia(foto.rutaLocal);
      } else {
        acta = acta.conFotoSubida(foto.rutaLocal, url);
      }
      // Guardar ya: si el envío se corta, esta foto no se vuelve a subir
      await _actas.guardar(acta);
    }

    final r = await _api.sincronizar(acta);
    if (r == null) {
      throw const EnvioDetenido('El servidor respondió algo inesperado.');
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
        throw const EnvioDetenido(
          'El servidor no pudo procesar el acta. Se reintentará más tarde.',
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
