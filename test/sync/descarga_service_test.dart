import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/features/campanias/data/campanias_local_source.dart';
import 'package:app_movil_uubr/features/catastro/data/predios_local_source.dart';
import 'package:app_movil_uubr/sync/descarga_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_descarga.dart';
import '../helpers/fake_adapter.dart';

void main() {
  late AppDatabase base;

  setUp(() => base = baseEnMemoria());
  tearDown(() => base.cerrar());

  test('descarga campañas y predios y los guarda en SQLite', () async {
    final servicio = crearDescarga(
      base,
      servidorDescarga(
        campanias: [campaniaJson(1, 'Norte', geom: zonaNorte())],
        predios: [predioDentro(10), predioFuera(11)],
      ),
    );

    final resultado = await servicio.descargar();

    expect(resultado.campanias, 1);
    expect(resultado.predios, 2);
    final campania = (await CampaniasLocalSource(base).listar()).single;
    expect(campania.nombre, 'Norte');
    expect(campania.tieneZona, isTrue);
    final predio = (await PrediosLocalSource(base).listar()).first;
    expect(
      predio.areaM2,
      320.5,
      reason: 'el decimal llega como texto y se convierte',
    );
    expect(await servicio.ultimaDescarga(), isNotNull);
  });

  test(
    'una nueva descarga reemplaza lo anterior (lo quitado en el servidor desaparece)',
    () async {
      await crearDescarga(
        base,
        servidorDescarga(
          campanias: [campaniaJson(1, 'Vieja'), campaniaJson(2, 'Otra')],
          predios: [],
        ),
      ).descargar();

      await crearDescarga(
        base,
        servidorDescarga(campanias: [campaniaJson(2, 'Otra')], predios: []),
      ).descargar();

      final ids = (await CampaniasLocalSource(base).listar()).map((c) => c.id);
      expect(ids, [2]);
    },
  );

  test('si el servidor falla, la base NO cambia (descarga atómica)', () async {
    await crearDescarga(
      base,
      servidorDescarga(
        campanias: [campaniaJson(1, 'Guardada')],
        predios: [predioDentro(10)],
      ),
    ).descargar();

    await expectLater(
      crearDescarga(
        base,
        servidorDescarga(campanias: [], predios: [], status: 500),
      ).descargar(),
      throwsA(isA<DescargaFailure>()),
    );

    expect(
      (await CampaniasLocalSource(base).listar()).single.nombre,
      'Guardada',
    );
    expect(await PrediosLocalSource(base).listar(), hasLength(1));
  });

  test('sin conexión se avisa y se conservan los datos anteriores', () async {
    await crearDescarga(
      base,
      servidorDescarga(campanias: [campaniaJson(1, 'Guardada')], predios: []),
    ).descargar();

    final sinRedServicio = crearDescarga(
      base,
      FakeAdapter((o) async => throw sinRed(o)),
    );

    await expectLater(
      sinRedServicio.descargar(),
      throwsA(
        isA<DescargaFailure>().having(
          (f) => f.sinConexion,
          'sinConexion',
          isTrue,
        ),
      ),
    );
    expect(await CampaniasLocalSource(base).listar(), hasLength(1));
  });

  test('limpiar borra todo lo descargado (cierre de sesión)', () async {
    final servicio = crearDescarga(
      base,
      servidorDescarga(
        campanias: [campaniaJson(1, 'Norte')],
        predios: [predioDentro(10)],
      ),
    );
    await servicio.descargar();

    await base.limpiarTodo();

    expect(await CampaniasLocalSource(base).listar(), isEmpty);
    expect(await PrediosLocalSource(base).listar(), isEmpty);
    expect(await servicio.ultimaDescarga(), isNull);
  });
}
