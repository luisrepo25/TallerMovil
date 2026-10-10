import 'package:uuid/uuid.dart';

import '../../campanias/domain/campania.dart';
import '../domain/acta_envio.dart';
import '../domain/acta_local.dart';
import 'actas_store.dart';

/// Una regla de negocio de la inspección que no se cumple (se muestra tal cual al inspector).
class InspeccionNoPermitida implements Exception {
  const InspeccionNoPermitida(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'InspeccionNoPermitida($mensaje)';
}

/// Reglas de las actas hechas en el teléfono. La UI no habla con SQLite: pasa por aquí.
class ActasRepository {
  ActasRepository(this._store, {Uuid? uuid, DateTime Function()? ahora})
    : _uuid = uuid ?? const Uuid(),
      _ahora = ahora ?? DateTime.now;

  final ActasStore _store;
  final Uuid _uuid;
  final DateTime Function() _ahora;

  /// Devuelve el borrador abierto del predio en la campaña o crea uno nuevo.
  /// Regla: **una sola acta abierta por predio y campaña**; al cerrarla se puede
  /// volver a inspeccionar (reinspección) y eso crea un acta nueva.
  Future<ActaLocal> iniciarOContinuar({
    required Campania campania,
    required int predioId,
  }) async {
    if (campania.estaCerrada) {
      throw const InspeccionNoPermitida(
        'La campaña está cerrada: ya no admite inspecciones.',
      );
    }
    final existentes = await _store.delPredio(campania.id, predioId);
    final borrador = existentes
        .where((a) => a.estado == EstadoActa.borrador)
        .firstOrNull;
    if (borrador != null) return borrador;

    var nueva = ActaLocal(
      uuidLocal: _uuid.v4(),
      predioId: predioId,
      campaniaId: campania.id,
      // Momento real de la inspección: es el que se enviará al servidor
      fechaInspeccion: _ahora().toUtc(),
    );
    // Una reinspección no empieza de cero: parte de la anterior (la lista viene con la más
    // reciente primero). Es un acta NUEVA: la anterior queda intacta como historia.
    final anterior = existentes
        .where((a) => a.estado.cerrada && a.estado != EstadoActa.rechazada)
        .firstOrNull;
    if (anterior != null) nueva = nueva.conDatosDeAnterior(anterior);
    await _store.guardar(nueva);
    return nueva;
  }

  /// Reabre para corregirla la última acta cerrada del predio **si todavía no se envió**.
  /// Una acta ya enviada es la foto histórica de esa fecha (el servidor la rechazaría y la
  /// reincidencia se calcula contra ella): para corregir algo se hace una reinspección.
  Future<ActaLocal> reabrirUltima({
    required Campania campania,
    required int predioId,
  }) async {
    if (campania.estaCerrada) {
      throw const InspeccionNoPermitida(
        'La campaña está cerrada: ya no admite cambios.',
      );
    }
    final existentes = await _store.delPredio(campania.id, predioId);
    if (existentes.any((a) => a.estado == EstadoActa.borrador)) {
      throw const InspeccionNoPermitida(
        'Ya tienes una inspección en curso en este predio.',
      );
    }
    final cerrada = existentes
        .where((a) => a.estado == EstadoActa.cerradaLocal)
        .firstOrNull;
    if (cerrada == null) {
      throw const InspeccionNoPermitida(
        'Esta acta ya se envió y no se puede modificar. Para corregir algo, '
        'haz una reinspección.',
      );
    }
    final reabierta = cerrada.reabierta();
    await _store.guardar(reabierta);
    return reabierta;
  }

  /// Autoguardado: solo un borrador se puede modificar.
  Future<void> guardar(ActaLocal acta) async {
    if (!acta.editable) {
      throw const InspeccionNoPermitida(
        'Un acta cerrada ya no se puede modificar.',
      );
    }
    await _store.guardar(acta);
  }

  /// Cierra el acta en el teléfono (queda lista para enviarse). Desde ese momento es
  /// inmutable. El riesgo se calcula en el servidor al sincronizar, no aquí.
  Future<ActaLocal> cerrar(ActaLocal acta) async {
    if (!acta.editable) {
      throw const InspeccionNoPermitida('El acta ya está cerrada.');
    }
    final faltantes = acta.faltantesParaCerrar;
    if (faltantes.isNotEmpty) throw InspeccionNoPermitida(faltantes.join(' '));

    final cerrada = acta.copyWith(
      estado: EstadoActa.cerradaLocal,
      fechaCierreLocal: _ahora().toUtc(),
    );
    await _store.guardar(cerrada);
    return cerrada;
  }

  Future<Map<int, EstadoActa>> estadoPorPredio(int campaniaId) =>
      _store.estadoPorPredio(campaniaId);

  /// Actas que todavía no llegaron al servidor (para avisar antes de cerrar sesión).
  Future<int> contarPendientes() => _store.contarPendientes();
}
