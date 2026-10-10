import '../domain/acta_local.dart';

/// Dónde se guardan las actas. La implementación real es SQLite ([ActasLocalSource]);
/// las pruebas usan una versión en memoria.
abstract interface class ActasStore {
  Future<void> guardar(ActaLocal acta);
  Future<ActaLocal?> obtener(String uuidLocal);

  /// Actas de un predio en una campaña, la más reciente primero.
  Future<List<ActaLocal>> delPredio(int campaniaId, int predioId);

  /// Estado más reciente de cada predio de la campaña: `predioId -> estado`.
  Future<Map<int, EstadoActa>> estadoPorPredio(int campaniaId);

  /// Actas que todavía no llegaron al servidor.
  Future<int> contarPendientes();

  /// Actas cerradas listas para enviar, la más antigua primero: el servidor detecta
  /// reincidencias comparando con actas anteriores, así que deben llegar en orden.
  Future<List<ActaLocal>> pendientesDeEnvio();
}
