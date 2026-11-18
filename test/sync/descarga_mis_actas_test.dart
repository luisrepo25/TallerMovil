import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/core/network/api_client.dart';
import 'package:app_movil_uubr/features/inspeccion/data/acta_servidor.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_local_source.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/abrir_inspeccion.dart';
import '../helpers/acta_completa.dart';
import '../helpers/datos_descarga.dart';
import '../helpers/fake_adapter.dart';

/// Resumen de una acta ya sincronizada, como lo devuelve `GET .../mis-actas/`.
Map<String, dynamic> actaServidor({
  int id = 1704,
  String? uuid = 'uuid-del-servidor',
  int predio = 10,
  int campania = 1,
  String fecha = '2026-11-18T03:25:00-04:00',
}) => {
  'id': id,
  'uuid_local': uuid,
  'predio_id': predio,
  'campania_id': campania,
  'fecha_inspeccion': fecha,
  'estado_extintores_id': 2,
  'fallas_electricas': true,
  'rutas_evacuacion_despejadas': false,
  'carga_fuego': '83.61',
  'scoring_riesgo': '11.89',
  'cluster_riesgo': 'Bajo',
  'materiales': [
    {'material_id': 1, 'peso_kg': '300.00'},
  ],
  'infracciones': [
    {
      'tipo_infraccion_id': 2,
      'descripcion': 'Pasillo obstruido',
      'es_reincidencia': false,
    },
  ],
};

/// Servidor con una campaña, un predio y las actas que el inspector ya hizo.
FakeAdapter servidor({
  required List<Map<String, dynamic>> actas,
  int? errorMisActas,
}) {
  final base = servidorDescarga(
    campanias: [campaniaJson(1, 'Norte', geom: zonaNorte())],
    predios: [predioDentro(10)],
  );
  return FakeAdapter((o) async {
    if (o.path == ApiRutas.misActas) {
      if (errorMisActas != null) {
        return jsonResponse({'detail': 'x'}, status: errorMisActas);
      }
      return jsonResponse(actas);
    }
    return base.handler(o);
  });
}

void main() {
  late AppDatabase base;
  late ActasLocalSource local;
  late ActasRepository repo;

  setUp(() {
    base = baseEnMemoria();
    local = ActasLocalSource(base);
    repo = ActasRepository(local);
  });
  tearDown(() => base.cerrar());

  group('el acta del servidor en el teléfono', () {
    test('queda sincronizada, con sus datos y resultados', () {
      final acta = actaDesdeServidor(actaServidor());

      expect(acta.estado, EstadoActa.sincronizada);
      expect(acta.estado.pendienteDeEnvio, isFalse);
      expect(acta.uuidLocal, 'uuid-del-servidor');
      expect(acta.actaIdServidor, 1704);
      expect(acta.fallasElectricas, isTrue);
      expect(acta.rutasDespejadas, isFalse);
      expect(acta.materiales.single.pesoKg, 300);
      expect(acta.infracciones.single.descripcion, 'Pasillo obstruido');
      expect(acta.scoringRiesgo, 11.89);
      expect(acta.clusterRiesgo, 'Bajo');
      expect(acta.fechaInspeccion, DateTime.utc(2026, 11, 18, 7, 25));
    });

    test(
      'una acta sin uuid (web u otro aparato) usa uno derivado de su id',
      () {
        final acta = actaDesdeServidor(actaServidor(uuid: null, id: 55));
        expect(acta.uuidLocal, 'servidor-55');
      },
    );

    test('sin materiales queda confirmada como "sin materiales"', () {
      final json = actaServidor()..['materiales'] = <dynamic>[];
      expect(actaDesdeServidor(json).sinMateriales, isTrue);
    });
  });

  group('al descargar sus campañas', () {
    test(
      'un predio ya inspeccionado aparece como enviado, no como pendiente',
      () async {
        await crearDescarga(
          base,
          servidor(actas: [actaServidor()]),
        ).descargar();

        final estados = await repo.estadoPorPredio(1);

        expect(estados[10], EstadoActa.sincronizada);
        expect(
          await repo.contarPendientes(),
          0,
          reason: 'no hay nada que enviar',
        );
      },
    );

    test('descargar otra vez no duplica las actas', () async {
      final servicio = crearDescarga(base, servidor(actas: [actaServidor()]));
      await servicio.descargar();
      await servicio.descargar();

      expect(await local.delPredio(1, 10), hasLength(1));
    });

    test(
      'no pisa un acta que ya está en el teléfono con su detalle completo',
      () async {
        final propia = actaDesdeServidor(actaServidor()).copyWith();
        await local.guardar(
          propia.conInfraccion(1, 'Detalle local').conEvidencia('/f/1.jpg', ''),
        );

        await crearDescarga(
          base,
          servidor(actas: [actaServidor()]),
        ).descargar();

        final guardada = (await local.obtener('uuid-del-servidor'))!;
        expect(
          guardada.evidencias,
          hasLength(1),
          reason: 'se conserva la copia local',
        );
      },
    );

    test(
      'una inspección pendiente más reciente manda sobre la recuperada',
      () async {
        final pendiente = ActaLocal(
          uuidLocal: 'local-1',
          predioId: 10,
          campaniaId: 1,
          fechaInspeccion: DateTime.utc(2026, 11, 19),
        ).completa().copyWith(estado: EstadoActa.cerradaLocal);
        await local.guardar(pendiente);

        await crearDescarga(
          base,
          servidor(actas: [actaServidor()]),
        ).descargar();

        expect((await repo.estadoPorPredio(1))[10], EstadoActa.cerradaLocal);
      },
    );

    test(
      'si el historial falla, la descarga de campañas y predios sigue valiendo',
      () async {
        final resultado = await crearDescarga(
          base,
          servidor(actas: const [], errorMisActas: 500),
        ).descargar();

        expect(resultado.campanias, 1);
        expect(resultado.predios, 1);
        expect(await local.delPredio(1, 10), isEmpty);
      },
    );

    test(
      'una reinspección parte en blanco y ve la recuperada como referencia',
      () async {
        await crearDescarga(
          base,
          servidor(actas: [actaServidor()]),
        ).descargar();

        final nueva = await repo.iniciarOContinuar(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );
        final anterior = await repo.anteriorCerrada(
          campania: campaniaAbierta,
          predioId: predioPrueba.id,
        );

        expect(nueva.precargadaDe, DateTime.utc(2026, 11, 18, 7, 25));
        expect(nueva.fallasElectricas, isNull, reason: 'parte en blanco');
        expect(anterior?.uuidLocal, 'uuid-del-servidor');
        expect(anterior?.materiales.single.pesoKg, 300);
      },
    );
  });
}
