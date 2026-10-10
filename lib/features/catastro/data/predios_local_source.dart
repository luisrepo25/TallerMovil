import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/predio.dart';

/// Acceso a la tabla `predios` de SQLite. Solo SQL: sin reglas de negocio.
class PrediosLocalSource {
  PrediosLocalSource(this._database);

  final AppDatabase _database;

  Future<List<Predio>> listar() async {
    final db = await _database.db;
    final filas = await db.query('predios', orderBy: 'nombre COLLATE NOCASE');
    return filas.map(Predio.fromMap).toList();
  }

  Future<void> reemplazarEn(DatabaseExecutor txn, List<Predio> predios) async {
    await txn.delete('predios');
    final lote = txn.batch();
    for (final p in predios) {
      lote.insert(
        'predios',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await lote.commit(noResult: true);
  }
}
