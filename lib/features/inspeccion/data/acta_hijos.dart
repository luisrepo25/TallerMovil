import 'package:sqflite/sqflite.dart';

import '../domain/acta_local.dart';
import 'acta_mapper.dart';

/// Arma un acta completa a partir de su fila: lee sus materiales, infracciones, fotos y
/// solicitudes de material (las tablas hijas) en el orden en que se agregaron.
Future<ActaLocal> actaConHijos(Database db, Map<String, Object?> fila) async {
  final uuid = fila['uuid_local']! as String;
  Future<List<Map<String, Object?>>> hijos(String tabla) =>
      db.query(tabla, where: 'acta_uuid = ?', whereArgs: [uuid], orderBy: 'id');

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
