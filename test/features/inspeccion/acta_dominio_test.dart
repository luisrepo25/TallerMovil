import 'dart:convert';

import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

ActaLocal actaNueva() => ActaLocal(
  uuidLocal: 'uuid-1',
  predioId: 10,
  campaniaId: 1,
  fechaInspeccion: DateTime.utc(2026, 10, 9, 15, 30),
);

void main() {
  group('reglas del acta', () {
    test('no se puede cerrar sin indicar el estado de los extintores', () {
      final acta = actaNueva();

      expect(acta.puedeCerrar, isFalse);
      expect(acta.faltantesParaCerrar, ['Indica el estado de los extintores.']);
    });

    test(
      'con los extintores indicados ya se puede cerrar (materiales e infracciones son opcionales)',
      () {
        final acta = actaNueva().copyWith(estadoExtintoresId: 1);

        expect(acta.puedeCerrar, isTrue);
        expect(acta.materiales, isEmpty);
      },
    );

    test('un acta cerrada ya no es editable ni se puede volver a cerrar', () {
      final cerrada = actaNueva().copyWith(
        estadoExtintoresId: 1,
        estado: EstadoActa.cerradaLocal,
      );

      expect(cerrada.editable, isFalse);
      expect(cerrada.puedeCerrar, isFalse);
    });

    test('por defecto: sin fallas eléctricas y con las rutas despejadas', () {
      final acta = actaNueva();

      expect(acta.fallasElectricas, isFalse);
      expect(acta.rutasDespejadas, isTrue);
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
