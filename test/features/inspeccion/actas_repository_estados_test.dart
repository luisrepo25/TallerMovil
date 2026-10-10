import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/datos_descarga.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;
  late ActasRepository repositorio;
  late DateTime reloj;
  final abierta = Campania.fromApi(campaniaJson(1, 'Norte', geom: zonaNorte()));

  setUp(() {
    almacen = ActasEnMemoria();
    reloj = DateTime.utc(2026, 10, 9, 15);
    repositorio = ActasRepository(almacen, ahora: () => reloj);
  });

  test(
    'después de cerrar se puede reinspeccionar: crea un acta nueva, la anterior se conserva',
    () async {
      final primera = (await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      )).copyWith(estadoExtintoresId: 1);
      await repositorio.cerrar(primera);

      final segunda = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      );

      expect(segunda.uuidLocal, isNot(primera.uuidLocal));
      expect(segunda.estado, EstadoActa.borrador);
      expect(almacen.actas, hasLength(2));
    },
  );

  test(
    'el estado de cada predio es el de su inspección más reciente',
    () async {
      final a = (await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      )).copyWith(estadoExtintoresId: 1);
      await repositorio.cerrar(a);
      reloj = DateTime.utc(2026, 10, 9, 16); // la reinspección es posterior
      await repositorio.iniciarOContinuar(campania: abierta, predioId: 10);
      await repositorio.iniciarOContinuar(campania: abierta, predioId: 11);

      final estados = await repositorio.estadoPorPredio(1);

      expect(estados, {10: EstadoActa.borrador, 11: EstadoActa.borrador});
    },
  );

  test(
    'cuenta las actas que aún no llegaron al servidor (para avisar al cerrar sesión)',
    () async {
      final a = (await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      )).copyWith(estadoExtintoresId: 1);
      await repositorio.cerrar(a);
      await repositorio.iniciarOContinuar(campania: abierta, predioId: 11);

      expect(await repositorio.contarPendientes(), 2);

      almacen.actas[a.uuidLocal] = almacen.actas[a.uuidLocal]!.copyWith(
        estado: EstadoActa.sincronizada,
      );
      expect(await repositorio.contarPendientes(), 1);
    },
  );
}
