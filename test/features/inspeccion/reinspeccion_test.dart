import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_envio.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_inspeccion.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;
  late ActasRepository repo;
  var hora = 8;

  setUp(() {
    almacen = ActasEnMemoria();
    hora = 8;
    // Cada llamada al reloj avanza una hora: las actas quedan en orden
    repo = ActasRepository(
      almacen,
      ahora: () => DateTime.utc(2026, 10, 9, hora++),
    );
  });

  /// Primera inspección completa y cerrada (todavía sin enviar).
  Future<ActaLocal> primeraCerrada() async {
    final borrador =
        (await repo.iniciarOContinuar(
              campania: campaniaAbierta,
              predioId: predioPrueba.id,
            ))
            .copyWith(
              estadoExtintoresId: 2,
              fallasElectricas: true,
              rutasDespejadas: false,
            )
            .conMaterial(1, 300)
            .conInfraccion(1, 'Sin carga')
            .conEvidencia('/f/1.jpg', 'Extintor')
            .conSolicitudMaterial(
              const SolicitudMaterialActa(uuidLocal: 's1', nombre: 'Espuma'),
            );
    await repo.guardar(borrador);
    return repo.cerrar(borrador);
  }

  group('reinspección: no empieza de cero', () {
    test('la primera inspección sí parte vacía', () async {
      final acta = await repo.iniciarOContinuar(
        campania: campaniaAbierta,
        predioId: predioPrueba.id,
      );

      expect(acta.precargadaDe, isNull);
      expect(acta.estadoExtintoresId, isNull);
      expect(acta.materiales, isEmpty);
    });

    test(
      'la segunda parte de los datos de la anterior, que queda intacta',
      () async {
        final primera = await primeraCerrada();

        final segunda = await repo.iniciarOContinuar(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );

        expect(
          segunda.uuidLocal,
          isNot(primera.uuidLocal),
          reason: 'acta nueva',
        );
        expect(segunda.estado, EstadoActa.borrador);
        expect(segunda.precargadaDe, primera.fechaInspeccion);
        expect(segunda.estadoExtintoresId, 2);
        expect(segunda.fallasElectricas, isTrue);
        expect(segunda.rutasDespejadas, isFalse);
        expect(segunda.materiales.single.pesoKg, 300);
        expect(segunda.infracciones.single.descripcion, 'Sin carga');
        // La anterior es historia: no se toca
        expect(
          almacen.actas[primera.uuidLocal]!.estado,
          EstadoActa.cerradaLocal,
        );
        expect(almacen.actas[primera.uuidLocal]!.evidencias, hasLength(1));
      },
    );

    test(
      'las fotos y las solicitudes NO se copian: son de la inspección de ese día',
      () async {
        await primeraCerrada();

        final segunda = await repo.iniciarOContinuar(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );

        expect(segunda.evidencias, isEmpty);
        expect(segunda.solicitudesMaterial, isEmpty);
      },
    );

    test(
      'la fecha de inspección es la de ahora, no la de la anterior',
      () async {
        final primera = await primeraCerrada();

        final segunda = await repo.iniciarOContinuar(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );

        expect(
          segunda.fechaInspeccion.isAfter(primera.fechaInspeccion),
          isTrue,
        );
      },
    );

    test('una acta rechazada por el servidor no sirve de base', () async {
      final primera = await primeraCerrada();
      await almacen.guardar(primera.rechazadaPorServidor('x'));

      final segunda = await repo.iniciarOContinuar(
        campania: campaniaAbierta,
        predioId: predioPrueba.id,
      );

      expect(segunda.precargadaDe, isNull);
      expect(segunda.materiales, isEmpty);
    });

    test('la parte de la anterior se puede corregir antes de cerrar', () async {
      await primeraCerrada();
      final segunda = await repo.iniciarOContinuar(
        campania: campaniaAbierta,
        predioId: predioPrueba.id,
      );

      final corregida = segunda
          .copyWith(estadoExtintoresId: 1)
          .conMaterial(1, 120)
          .sinInfraccion(1);
      await repo.guardar(corregida);

      final guardada = almacen.actas[segunda.uuidLocal]!;
      expect(guardada.estadoExtintoresId, 1);
      expect(guardada.materiales.single.pesoKg, 120);
      expect(guardada.infracciones, isEmpty);
    });
  });

  group('reabrir un acta que aún no se envió', () {
    test(
      'vuelve a borrador con el mismo identificador y sin perder nada',
      () async {
        final cerrada = await primeraCerrada();

        final reabierta = await repo.reabrirUltima(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );

        expect(reabierta.uuidLocal, cerrada.uuidLocal);
        expect(reabierta.estado, EstadoActa.borrador);
        expect(reabierta.fechaCierreLocal, isNull);
        expect(reabierta.materiales, hasLength(1));
        expect(reabierta.evidencias, hasLength(1));
        expect(reabierta.solicitudesMaterial, hasLength(1));
        expect(almacen.actas, hasLength(1), reason: 'no crea otra acta');
      },
    );

    test('al reabrirla se puede editar y volver a cerrar', () async {
      await primeraCerrada();
      final reabierta = await repo.reabrirUltima(
        campania: campaniaAbierta,
        predioId: predioPrueba.id,
      );

      await repo.guardar(reabierta.conMaterial(1, 50));
      final cerrada = await repo.cerrar(almacen.actas.values.single);

      expect(cerrada.estado, EstadoActa.cerradaLocal);
      expect(cerrada.materiales.single.pesoKg, 50);
    });

    test(
      'una acta ya enviada no se reabre: se hace una reinspección',
      () async {
        final cerrada = await primeraCerrada();
        await almacen.guardar(cerrada.sincronizada(actaIdServidor: 5));

        expect(
          () => repo.reabrirUltima(
            campania: campaniaAbierta,
            predioId: predioPrueba.id,
          ),
          throwsA(
            isA<InspeccionNoPermitida>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('reinspección'),
            ),
          ),
        );
        expect(almacen.actas.values.single.estado, EstadoActa.sincronizada);
      },
    );

    test(
      'no se reabre si ya hay otra inspección en curso en el predio',
      () async {
        await primeraCerrada();
        await repo.iniciarOContinuar(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        ); // la reinspección (borrador)

        expect(
          () => repo.reabrirUltima(
            campania: campaniaAbierta,
            predioId: predioPrueba.id,
          ),
          throwsA(isA<InspeccionNoPermitida>()),
        );
      },
    );

    test('en una campaña cerrada ya no se puede reabrir', () async {
      await primeraCerrada();

      expect(
        () => repo.reabrirUltima(
          campania: campaniaCerrada,
          predioId: predioPrueba.id,
        ),
        throwsA(isA<InspeccionNoPermitida>()),
      );
    });
  });

  testWidgets(
    'el asistente avisa que es una reinspección y de qué fecha parte',
    (tester) async {
      await primeraCerrada();

      await abrirInspeccion(tester, almacen: almacen);

      expect(
        find.textContaining('Reinspección: partes de los datos del'),
        findsOneWidget,
      );
      expect(find.textContaining('09 oct 2026'), findsOneWidget);
    },
  );
}
