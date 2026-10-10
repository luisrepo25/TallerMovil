import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_local_source.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/datos_descarga.dart';

ActaLocal acta(
  String uuid, {
  int predio = 10,
  int campania = 1,
  int hora = 15,
  EstadoActa estado = EstadoActa.borrador,
}) => ActaLocal(
  uuidLocal: uuid,
  predioId: predio,
  campaniaId: campania,
  fechaInspeccion: DateTime.utc(2026, 10, 9, hora),
  estadoExtintoresId: 1,
  estado: estado,
);

void main() {
  late AppDatabase base;
  late ActasLocalSource fuente;

  setUp(() {
    base = baseEnMemoria();
    fuente = ActasLocalSource(base);
  });
  tearDown(() => base.cerrar());

  test(
    'borrar un acta borra en cascada sus materiales e infracciones',
    () async {
      await fuente.guardar(
        acta('a1').conMaterial(1, 300).conInfraccion(1, 'x'),
      );
      final db = await base.db;

      await db.delete('actas', where: 'uuid_local = ?', whereArgs: ['a1']);

      expect(await db.query('acta_materiales'), isEmpty);
      expect(await db.query('acta_infracciones'), isEmpty);
    },
  );

  test('limpiarTodo (cierre de sesión) borra también las actas', () async {
    await fuente.guardar(acta('a1').conMaterial(1, 300));

    await base.limpiarTodo();

    expect(await fuente.obtener('a1'), isNull);
    expect(await fuente.contarPendientes(), 0);
    expect(await (await base.db).query('acta_materiales'), isEmpty);
  });
}
