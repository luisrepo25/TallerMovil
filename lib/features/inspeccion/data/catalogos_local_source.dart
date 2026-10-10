import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/catalogos.dart';
import 'catalogos_repository.dart';

/// Acceso a las tablas de catálogos de SQLite. Solo SQL: sin reglas de negocio.
class CatalogosLocalSource implements CatalogosStore {
  CatalogosLocalSource(this._database);

  final AppDatabase _database;

  @override
  Future<Catalogos> leer() async {
    final db = await _database.db;
    final estados = await db.query('cat_estados_extintor', orderBy: 'id');
    final infracciones = await db.query(
      'cat_infracciones',
      orderBy: 'nombre COLLATE NOCASE',
    );
    final materiales = await db.query(
      'cat_materiales',
      orderBy: 'nombre COLLATE NOCASE',
    );
    return Catalogos(
      estadosExtintor: estados.map(EstadoExtintor.fromMap).toList(),
      infracciones: infracciones.map(TipoInfraccion.fromMap).toList(),
      materiales: materiales.map(MaterialCombustible.fromMap).toList(),
    );
  }

  /// Reemplaza los tres catálogos dentro de la transacción recibida.
  Future<void> reemplazarEn(DatabaseExecutor txn, Catalogos catalogos) async {
    await txn.delete('cat_estados_extintor');
    await txn.delete('cat_infracciones');
    await txn.delete('cat_materiales');
    final lote = txn.batch();
    for (final e in catalogos.estadosExtintor) {
      lote.insert('cat_estados_extintor', e.toMap());
    }
    for (final i in catalogos.infracciones) {
      lote.insert('cat_infracciones', i.toMap());
    }
    for (final m in catalogos.materiales) {
      lote.insert('cat_materiales', m.toMap());
    }
    await lote.commit(noResult: true);
  }
}
