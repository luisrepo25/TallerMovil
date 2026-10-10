import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/features/campanias/data/campanias_local_source.dart';
import 'package:app_movil_uubr/features/campanias/data/campanias_repository.dart';
import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/campanias/presentation/campanias_controller.dart';
import 'package:app_movil_uubr/features/catastro/data/predios_local_source.dart';
import 'package:app_movil_uubr/features/catastro/data/predios_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_local_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_descarga.dart';
import '../helpers/fake_adapter.dart';

void main() {
  late AppDatabase base;

  setUp(() => base = baseEnMemoria());
  tearDown(() => base.cerrar());

  CampaniasController crearControlador(FakeAdapter adapter) =>
      CampaniasController(
        campanias: CampaniasRepository(CampaniasLocalSource(base)),
        predios: PrediosRepository(PrediosLocalSource(base)),
        descarga: crearDescarga(base, adapter),
        envio: crearEnvio(ActasLocalSource(base), adapter),
      );

  test(
    'con red: descarga, muestra las campañas y cuenta los predios de cada zona',
    () async {
      final controlador = crearControlador(
        servidorDescarga(
          campanias: [
            campaniaJson(1, 'Norte', geom: zonaNorte()),
            campaniaJson(2, 'Sin zona'),
          ],
          predios: [predioDentro(10), predioDentro(11), predioFuera(12)],
        ),
      );

      await controlador.iniciar();

      expect(
        controlador.items.map((c) => c.nombre),
        containsAll(['Norte', 'Sin zona']),
      );
      expect(
        controlador.prediosPorCampania[1],
        2,
        reason: 'solo los 2 predios dentro de la zona',
      );
      expect(controlador.prediosPorCampania[2], 0);
      expect(controlador.aviso, isNull);
      expect(controlador.ultimaDescarga, isNotNull);
      expect(controlador.cargandoInicial, isFalse);
    },
  );

  test(
    'SIN CONEXIÓN: sigue mostrando lo descargado y avisa que no pudo actualizar',
    () async {
      await crearControlador(
        servidorDescarga(
          campanias: [campaniaJson(1, 'Norte', geom: zonaNorte())],
          predios: [],
        ),
      ).iniciar();

      final sinRedControlador = crearControlador(
        FakeAdapter((o) async => throw sinRed(o)),
      );
      await sinRedControlador.iniciar();

      expect(sinRedControlador.items.single.nombre, 'Norte');
      expect(sinRedControlador.sinConexion, isTrue);
      expect(sinRedControlador.aviso, contains('Sin conexión'));
    },
  );

  test(
    'primera vez y sin conexión: lista vacía con aviso, sin romperse',
    () async {
      final controlador = crearControlador(
        FakeAdapter((o) async => throw sinRed(o)),
      );

      await controlador.iniciar();

      expect(controlador.items, isEmpty);
      expect(controlador.aviso, isNotNull);
      expect(controlador.ultimaDescarga, isNull);
    },
  );

  test('los predios de una campaña son los que caen en su zona', () async {
    await crearControlador(
      servidorDescarga(
        campanias: [campaniaJson(1, 'Norte', geom: zonaNorte())],
        predios: [predioDentro(10), predioFuera(11)],
      ),
    ).iniciar();
    final repositorio = PrediosRepository(PrediosLocalSource(base));
    final campania = (await CampaniasLocalSource(base).listar()).single;

    final enZona = await repositorio.enZona(campania);

    expect(enZona.map((p) => p.id), [10]);
  });

  test('una campaña sin zona no tiene predios', () async {
    final repositorio = PrediosRepository(PrediosLocalSource(base));
    final sinZona = Campania.fromApi(campaniaJson(1, 'Sin zona'));

    expect(await repositorio.enZona(sinZona), isEmpty);
  });
}
