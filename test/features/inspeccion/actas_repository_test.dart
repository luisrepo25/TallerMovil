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
  final cerrada = Campania.fromApi(campaniaJson(2, 'Vieja', estado: 'cerrada'));

  setUp(() {
    almacen = ActasEnMemoria();
    reloj = DateTime.utc(2026, 10, 9, 15);
    repositorio = ActasRepository(almacen, ahora: () => reloj);
  });

  test(
    'iniciar crea un borrador con la hora real de la inspección (UTC)',
    () async {
      final acta = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      );

      expect(acta.estado, EstadoActa.borrador);
      expect(acta.predioId, 10);
      expect(acta.campaniaId, 1);
      expect(acta.fechaInspeccion, reloj);
      expect(acta.uuidLocal, isNotEmpty);
      expect(almacen.actas, hasLength(1), reason: 'se guarda de inmediato');
    },
  );

  test(
    'volver a abrir el mismo predio retoma el borrador: una sola acta abierta',
    () async {
      final primera = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      );
      final segunda = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      );

      expect(segunda.uuidLocal, primera.uuidLocal);
      expect(almacen.actas, hasLength(1));
    },
  );

  test(
    'predios distintos tienen actas distintas, con identificadores distintos',
    () async {
      final a = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      );
      final b = await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 11,
      );

      expect(a.uuidLocal, isNot(b.uuidLocal));
    },
  );

  test('no se puede inspeccionar en una campaña cerrada', () async {
    await expectLater(
      repositorio.iniciarOContinuar(campania: cerrada, predioId: 10),
      throwsA(
        isA<InspeccionNoPermitida>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('cerrada'),
        ),
      ),
    );
    expect(almacen.actas, isEmpty);
  });

  test('cerrar sin lo obligatorio se rechaza explicando qué falta', () async {
    final acta = await repositorio.iniciarOContinuar(
      campania: abierta,
      predioId: 10,
    );

    await expectLater(
      repositorio.cerrar(acta),
      throwsA(
        isA<InspeccionNoPermitida>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('extintores'),
        ),
      ),
    );
    expect(almacen.actas[acta.uuidLocal]!.estado, EstadoActa.borrador);
  });

  test(
    'cerrar deja el acta lista para enviar, con la hora de cierre',
    () async {
      final acta = (await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      )).copyWith(estadoExtintoresId: 1);
      reloj = DateTime.utc(2026, 10, 9, 15, 20);

      final resultado = await repositorio.cerrar(acta);

      expect(resultado.estado, EstadoActa.cerradaLocal);
      expect(resultado.fechaCierreLocal, reloj);
      expect(almacen.actas[acta.uuidLocal]!.estado, EstadoActa.cerradaLocal);
    },
  );

  test(
    'un acta cerrada es inmutable: ni se modifica ni se vuelve a cerrar',
    () async {
      final acta = (await repositorio.iniciarOContinuar(
        campania: abierta,
        predioId: 10,
      )).copyWith(estadoExtintoresId: 1);
      final cerradaLocal = await repositorio.cerrar(acta);

      await expectLater(
        repositorio.guardar(cerradaLocal),
        throwsA(isA<InspeccionNoPermitida>()),
      );
      await expectLater(
        repositorio.cerrar(cerradaLocal),
        throwsA(isA<InspeccionNoPermitida>()),
      );
    },
  );
}
