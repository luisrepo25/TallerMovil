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
    'guardar y leer devuelve el acta completa, con materiales e infracciones en orden',
    () async {
      final original = acta('a1')
          .copyWith(fallasElectricas: true, rutasDespejadas: false)
          .conMaterial(2, 150.5)
          .conMaterial(1, 300)
          .conInfraccion(2, 'Pasillo obstruido')
          .conInfraccion(1, '');

      await fuente.guardar(original);
      final leida = (await fuente.obtener('a1'))!;

      expect(leida.fallasElectricas, isTrue);
      expect(leida.rutasDespejadas, isFalse);
      expect(leida.fechaInspeccion, DateTime.utc(2026, 10, 9, 15));
      expect(leida.fechaInspeccion.isUtc, isTrue);
      expect(leida.materiales.map((m) => (m.materialId, m.pesoKg)), [
        (2, 150.5),
        (1, 300.0),
      ]);
      expect(
        leida.infracciones.map((i) => (i.tipoInfraccionId, i.descripcion)),
        [(2, 'Pasillo obstruido'), (1, '')],
      );
    },
  );

  test('autoguardar reemplaza los hijos: lo quitado no reaparece', () async {
    await fuente.guardar(
      acta('a1').conMaterial(1, 300).conMaterial(2, 100).conInfraccion(1, 'x'),
    );

    await fuente.guardar(acta('a1').conMaterial(1, 350));
    final leida = (await fuente.obtener('a1'))!;

    expect(leida.materiales.map((m) => (m.materialId, m.pesoKg)), [(1, 350.0)]);
    expect(leida.infracciones, isEmpty);
  });

  test('un acta que no existe devuelve null', () async {
    expect(await fuente.obtener('no-existe'), isNull);
  });

  test(
    'delPredio devuelve solo las actas de ese predio y campaña, la más reciente primero',
    () async {
      await fuente.guardar(acta('vieja', hora: 9));
      await fuente.guardar(acta('nueva', hora: 18));
      await fuente.guardar(acta('otro-predio', predio: 11));
      await fuente.guardar(acta('otra-campania', campania: 2));

      final lista = await fuente.delPredio(1, 10);

      expect(lista.map((a) => a.uuidLocal), ['nueva', 'vieja']);
    },
  );

  test(
    'estadoPorPredio: gana la inspección más reciente de cada predio',
    () async {
      await fuente.guardar(
        acta('p10-vieja', hora: 9, estado: EstadoActa.cerradaLocal),
      );
      await fuente.guardar(acta('p10-nueva', hora: 18));
      await fuente.guardar(
        acta('p11', predio: 11, estado: EstadoActa.sincronizada),
      );

      final estados = await fuente.estadoPorPredio(1);

      expect(estados, {10: EstadoActa.borrador, 11: EstadoActa.sincronizada});
    },
  );

  test(
    'contarPendientes ignora las ya enviadas y cuenta las rechazadas',
    () async {
      await fuente.guardar(acta('borrador'));
      await fuente.guardar(
        acta('lista', predio: 11, estado: EstadoActa.cerradaLocal),
      );
      await fuente.guardar(
        acta('rechazada', predio: 12, estado: EstadoActa.rechazada),
      );
      await fuente.guardar(
        acta('enviada', predio: 13, estado: EstadoActa.sincronizada),
      );

      expect(await fuente.contarPendientes(), 3);
    },
  );
}
