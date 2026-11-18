import 'dart:convert';

import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/acta_completa.dart';

ActaLocal actaNueva() => ActaLocal(
  uuidLocal: 'uuid-1',
  predioId: 10,
  campaniaId: 1,
  fechaInspeccion: DateTime.utc(2026, 10, 9, 15, 30),
);

void main() {
  group('reglas del acta', () {
    test('un acta en blanco no se puede cerrar y dice qué falta', () {
      final acta = actaNueva();

      expect(acta.puedeCerrar, isFalse);
      expect(acta.faltantesParaCerrar, [
        'Indica el estado de los extintores.',
        'Responde si hay fallas eléctricas.',
        'Responde si las rutas de evacuación están despejadas.',
        'Registra los materiales combustibles o confirma que no hay.',
      ]);
    });

    test('con todo respondido ya se puede cerrar', () {
      final acta = actaNueva().completa();

      expect(acta.puedeCerrar, isTrue);
      expect(acta.faltantesParaCerrar, isEmpty);
    });

    test('las respuestas no tienen valor por defecto: hay que darlas', () {
      final acta = actaNueva();

      expect(acta.fallasElectricas, isNull);
      expect(acta.rutasDespejadas, isNull);
    });

    test(
      'responder "No" a las fallas cuenta como respuesta (no es lo mismo que vacío)',
      () {
        final acta = actaNueva().copyWith(fallasElectricas: false);

        expect(
          acta.faltantesParaCerrar,
          isNot(contains('Responde si hay fallas eléctricas.')),
        );
      },
    );

    test(
      '"Sin fallas y rutas despejadas" responde las dos preguntas de una vez',
      () {
        final acta = actaNueva().conSeguridadSinProblemas();

        expect(acta.fallasElectricas, isFalse);
        expect(acta.rutasDespejadas, isTrue);
      },
    );

    test('sin materiales: o se registra alguno o se confirma que no hay', () {
      final base = actaNueva().copyWith(
        estadoExtintoresId: 1,
        fallasElectricas: false,
        rutasDespejadas: true,
      );

      expect(base.puedeCerrar, isFalse);
      expect(base.conSinMateriales(true).puedeCerrar, isTrue);
      expect(base.conMaterial(1, 10).puedeCerrar, isTrue);
    });

    test('agregar un material anula la confirmación de "sin materiales"', () {
      final acta = actaNueva().conSinMateriales(true).conMaterial(1, 10);

      expect(acta.sinMateriales, isFalse);
      expect(acta.materiales, hasLength(1));
    });

    test('confirmar "sin materiales" vacía la lista', () {
      final acta = actaNueva().conMaterial(1, 10).conSinMateriales(true);

      expect(acta.sinMateriales, isTrue);
      expect(acta.materiales, isEmpty);
    });

    test(
      'una solicitud de material nuevo también cuenta como material pendiente',
      () {
        final acta = actaNueva()
            .completa()
            .conSinMateriales(false)
            .conSolicitudMaterial(
              const SolicitudMaterialActa(uuidLocal: 's1', nombre: 'Espuma'),
            );

        expect(acta.faltantesParaCerrar, isEmpty);
      },
    );

    test('con infracciones se exige al menos una foto de evidencia', () {
      final sinFoto = actaNueva().completa().conInfraccion(1, 'Sin carga');

      expect(sinFoto.puedeCerrar, isFalse);
      expect(sinFoto.faltantesParaCerrar, [
        'Agrega al menos una foto de evidencia de las infracciones.',
      ]);
      expect(sinFoto.conEvidencia('/f/1.jpg', '').puedeCerrar, isTrue);
    });

    test('sin infracciones no se pide foto', () {
      expect(actaNueva().completa().puedeCerrar, isTrue);
    });

    test('un acta cerrada ya no es editable ni se puede volver a cerrar', () {
      final cerrada = actaNueva().completa().copyWith(
        estado: EstadoActa.cerradaLocal,
      );

      expect(cerrada.editable, isFalse);
      expect(cerrada.puedeCerrar, isFalse);
    });

    test('solo "enviada" deja de ser trabajo pendiente', () {
      final pendientes = EstadoActa.values.where((e) => e.pendienteDeEnvio);

      expect(pendientes, isNot(contains(EstadoActa.sincronizada)));
      expect(
        pendientes,
        containsAll([
          EstadoActa.borrador,
          EstadoActa.cerradaLocal,
          EstadoActa.rechazada,
        ]),
      );
    });

    test(
      'un acta rechazada sigue contando como pendiente: nunca se pierde en silencio',
      () {
        expect(EstadoActa.rechazada.pendienteDeEnvio, isTrue);
      },
    );
  });

  group('formato para el servidor (POST sync/actas)', () {
    test(
      'lleva lo que el endpoint espera, con la fecha de la inspección en UTC con zona',
      () {
        final acta = actaNueva()
            .copyWith(
              estadoExtintoresId: 2,
              fallasElectricas: true,
              rutasDespejadas: false,
            )
            .conMaterial(1, 300)
            .conMaterial(2, 150.5)
            .conInfraccion(1, 'Sin carga');

        final json = acta.toSyncJson();

        expect(json['uuid_local'], 'uuid-1');
        expect(json['predio_id'], 10);
        expect(json['campania_id'], 1);
        expect(json['estado_extintores_id'], 2);
        expect(json['fallas_electricas'], isTrue);
        expect(json['rutas_evacuacion_despejadas'], isFalse);
        expect(json['fecha_inspeccion'], '2026-10-09T15:30:00.000Z');
        expect(json['materiales'], [
          {'material_id': 1, 'peso_kg': '300.00'},
          {'material_id': 2, 'peso_kg': '150.50'},
        ]);
        expect(json['infracciones'], [
          {'tipo_infraccion_id': 1, 'descripcion': 'Sin carga'},
        ]);
        expect(
          () => jsonEncode(json),
          returnsNormally,
          reason: 'debe poder serializarse',
        );
      },
    );

    test('NO envía carga de fuego ni scoring: los calcula el servidor', () {
      final json = actaNueva().copyWith(estadoExtintoresId: 1).toSyncJson();

      expect(json.keys, isNot(contains('carga_fuego')));
      expect(json.keys, isNot(contains('scoring_riesgo')));
      expect(json.keys, isNot(contains('cluster_riesgo')));
    });
  });
}
