import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/acta_local.dart';
import 'acta_mapper.dart';
import 'actas_store.dart';

/// Acceso a las tablas `actas`, `acta_materiales` y `acta_infracciones`.
/// Solo SQL: las reglas (una sola acta abierta por predio, etc.) están en el repositorio.
class ActasLocalSource implements ActasStore {
  ActasLocalSource(this._database);

  final AppDatabase _database;

  /// Guarda el acta y sus hijos en una sola transacción (o todo o nada).
  @override
  Future<void> guardar(ActaLocal acta) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.insert(
        'actas',
        ActaMapper.aFila(acta),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final tabla in [
        'acta_materiales',
        'acta_infracciones',
        'acta_evidencias',
        'acta_solicitudes_material',
      ]) {
        await txn.delete(
          tabla,
          where: 'acta_uuid = ?',
          whereArgs: [acta.uuidLocal],
        );
      }
      final lote = txn.batch();
      for (final m in acta.materiales) {
        lote.insert(
          'acta_materiales',
          ActaMapper.materialAFila(acta.uuidLocal, m),
        );
      }
      for (final i in acta.infracciones) {
        lote.insert(
          'acta_infracciones',
          ActaMapper.infraccionAFila(acta.uuidLocal, i),
        );
      }
      for (final e in acta.evidencias) {
        lote.insert(
          'acta_evidencias',
          ActaMapper.evidenciaAFila(acta.uuidLocal, e),
        );
      }
      for (final s in acta.solicitudesMaterial) {
        lote.insert(
          'acta_solicitudes_material',
          ActaMapper.solicitudAFila(acta.uuidLocal, s),
        );
      }
      await lote.commit(noResult: true);
    });
  }

  @override
  Future<ActaLocal?> obtener(String uuidLocal) async {
    final db = await _database.db;
    final filas = await db.query(
      'actas',
      where: 'uuid_local = ?',
      whereArgs: [uuidLocal],
    );
    return filas.isEmpty ? null : _conHijos(db, filas.first);
  }

  /// Actas de un predio en una campaña, la más reciente primero.
  @override
  Future<List<ActaLocal>> delPredio(int campaniaId, int predioId) async {
    final db = await _database.db;
    final filas = await db.query(
      'actas',
      where: 'campania_id = ? AND predio_id = ?',
      whereArgs: [campaniaId, predioId],
      orderBy: 'fecha_inspeccion DESC',
    );
    return [for (final f in filas) await _conHijos(db, f)];
  }

  /// Estado más reciente de cada predio de una campaña: `predioId -> estado`.
  @override
  Future<Map<int, EstadoActa>> estadoPorPredio(int campaniaId) async {
    final db = await _database.db;
    final filas = await db.query(
      'actas',
      columns: ['predio_id', 'estado'],
      where: 'campania_id = ?',
      whereArgs: [campaniaId],
      orderBy: 'fecha_inspeccion ASC', // la última pisa a las anteriores
    );
    return {
      for (final f in filas)
        f['predio_id']! as int: EstadoActa.desdeClave(f['estado']! as String),
    };
  }

  /// Cuántas actas todavía no llegaron al servidor.
  @override
  Future<int> contarPendientes() async {
    final db = await _database.db;
    final filas = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM actas WHERE estado != 'sincronizada'",
    );
    return filas.first['n']! as int;
  }

  @override
  Future<List<ActaLocal>> pendientesDeEnvio() async {
    final db = await _database.db;
    final filas = await db.query(
      'actas',
      where: 'estado = ?',
      whereArgs: [EstadoActa.cerradaLocal.clave],
      orderBy: 'fecha_inspeccion ASC',
    );
    return [for (final f in filas) await _conHijos(db, f)];
  }

  Future<ActaLocal> _conHijos(Database db, Map<String, Object?> fila) async {
    final uuid = fila['uuid_local']! as String;
    Future<List<Map<String, Object?>>> hijos(String tabla) => db.query(
      tabla,
      where: 'acta_uuid = ?',
      whereArgs: [uuid],
      orderBy: 'id',
    );

    return ActaMapper.desdeFila(
      fila,
      materiales: await hijos('acta_materiales'),
      infracciones: await hijos('acta_infracciones'),
      evidencias: await hijos('acta_evidencias'),
      solicitudes: await db.query(
        'acta_solicitudes_material',
        where: 'acta_uuid = ?',
        whereArgs: [uuid],
        orderBy: 'rowid',
      ),
    );
  }
}
