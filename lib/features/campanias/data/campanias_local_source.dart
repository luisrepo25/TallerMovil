import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/campania.dart';

/// Acceso a la tabla `campanias` de SQLite. Solo SQL: sin reglas de negocio.
class CampaniasLocalSource {
  CampaniasLocalSource(this._database);

  final AppDatabase _database;

  Future<List<Campania>> listar() async {
    final db = await _database.db;
    final filas = await db.query('campanias', orderBy: 'id DESC');
    return filas.map(Campania.fromMap).toList();
  }

  Future<Campania?> obtener(int id) async {
    final db = await _database.db;
    final filas = await db.query('campanias', where: 'id = ?', whereArgs: [id]);
    return filas.isEmpty ? null : Campania.fromMap(filas.first);
  }

  /// Reemplaza TODAS las campañas dentro de la transacción recibida. Lo que ya no está
  /// en el servidor (campaña reasignada o quitada) desaparece también del teléfono.
  Future<void> reemplazarEn(
    DatabaseExecutor txn,
    List<Campania> campanias,
  ) async {
    await txn.delete('campanias');
    final lote = txn.batch();
    for (final c in campanias) {
      lote.insert(
        'campanias',
        c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await lote.commit(noResult: true);
  }
}
