import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_local_source.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_inspeccion.dart';
import '../../helpers/datos_descarga.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;

  setUp(() => almacen = ActasEnMemoria());

  ActaLocal unica() => almacen.actas.values.single;

  Future<void> irAEvidencia(
    WidgetTester tester,
    EvidenciasFalsas camara,
  ) async {
    await abrirInspeccion(tester, almacen: almacen, camara: camara);
    await siguiente(tester, 4);
    expect(find.text('Paso 5 de 6 · Evidencia'), findsOneWidget);
  }

  group('fotos de evidencia', () {
    testWidgets('se pueden agregar tantas fotos como problemas haya', (
      tester,
    ) async {
      final camara = EvidenciasFalsas(['/f/1.jpg', '/f/2.jpg', '/f/3.jpg']);
      await irAEvidencia(tester, camara);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Tomar foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar')); // sin describir: es opcional
        await tester.pumpAndSettle();
      }

      expect(unica().evidencias.map((e) => e.rutaLocal), [
        '/f/1.jpg',
        '/f/2.jpg',
        '/f/3.jpg',
      ]);
      expect(camara.usoCamara, [true, true, true]);
    });

    testWidgets(
      '"Galería" elige una foto existente en vez de abrir la cámara',
      (tester) async {
        final camara = EvidenciasFalsas(['/f/1.jpg']);
        await irAEvidencia(tester, camara);

        await tester.tap(find.text('Galería'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(camara.usoCamara, [false]);
        expect(unica().evidencias, hasLength(1));
      },
    );

    testWidgets('la descripción de la foto se guarda en el acta', (
      tester,
    ) async {
      await irAEvidencia(tester, EvidenciasFalsas(['/f/1.jpg']));

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Extintor sin carga  ');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(unica().evidencias.single.descripcion, 'Extintor sin carga');
      expect(find.text('Extintor sin carga'), findsOneWidget);
    });

    testWidgets('si el inspector cancela la cámara no se agrega nada', (
      tester,
    ) async {
      await irAEvidencia(tester, EvidenciasFalsas([null]));

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(unica().evidencias, isEmpty);
    });

    testWidgets('sin permiso de cámara se explica qué hacer y no se rompe', (
      tester,
    ) async {
      final camara = EvidenciasFalsas()..fallar = true;
      await irAEvidencia(tester, camara);

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Revisa el permiso'), findsOneWidget);
      expect(unica().evidencias, isEmpty);
    });

    testWidgets('quitar una foto la saca del acta y borra el archivo', (
      tester,
    ) async {
      final camara = EvidenciasFalsas(['/f/1.jpg']);
      await irAEvidencia(tester, camara);
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quitar foto'));
      await tester.pumpAndSettle();

      expect(unica().evidencias, isEmpty);
      expect(camara.borradas, ['/f/1.jpg']);
    });

    testWidgets('el resumen cuenta las fotos', (tester) async {
      final camara = EvidenciasFalsas(['/f/1.jpg', '/f/2.jpg']);
      await irAEvidencia(tester, camara);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Tomar foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
      }

      await siguiente(tester);

      expect(find.text('2 fotos'), findsOneWidget);
    });

    test('al sincronizar solo viajan las fotos que ya están en la nube', () {
      final acta = ActaLocal(
        uuidLocal: 'a1',
        predioId: 1,
        campaniaId: 1,
        fechaInspeccion: DateTime.utc(2026, 10, 9),
        evidencias: const [
          EvidenciaActa(
            rutaLocal: '/f/1.jpg',
            descripcion: 'Humedad',
            urlRemota: 'https://res.cloudinary.com/x/1.jpg',
          ),
          EvidenciaActa(rutaLocal: '/f/2.jpg'),
        ],
      );

      expect(acta.toSyncJson()['evidencias'], [
        {
          'url_imagen': 'https://res.cloudinary.com/x/1.jpg',
          'descripcion_infraccion': 'Humedad',
        },
      ]);
      expect(acta.evidenciasPorSubir.map((e) => e.rutaLocal), ['/f/2.jpg']);
    });
  });

  group('solicitar un material nuevo', () {
    Future<void> irAMateriales(WidgetTester tester) async {
      await abrirInspeccion(tester, almacen: almacen);
      await siguiente(tester, 2);
      expect(find.text('Paso 3 de 6 · Materiales'), findsOneWidget);
    }

    Future<void> solicitar(
      WidgetTester tester,
      String nombre, {
      String? peso,
    }) async {
      await tester.tap(find.textContaining('Solicitar al administrador'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del material'),
        nombre,
      );
      if (peso != null) {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Peso aproximado (opcional)'),
          peso,
        );
      }
      await tester.tap(find.text('Solicitar'));
      await tester.pumpAndSettle();
    }

    testWidgets('queda guardada en el acta y visible como pendiente', (
      tester,
    ) async {
      await irAMateriales(tester);

      await solicitar(tester, 'Espuma de poliuretano', peso: '40,5');

      final s = unica().solicitudesMaterial.single;
      expect(s.nombre, 'Espuma de poliuretano');
      expect(s.pesoKgEstimado, 40.5);
      expect(s.uuidLocal, isNotEmpty);
      expect(find.text('Espuma de poliuretano'), findsOneWidget);
      expect(
        find.textContaining('Solicitado al administrador'),
        findsOneWidget,
      );
      // No suma a la carga de fuego: el material real sigue sin existir
      expect(unica().materiales, isEmpty);
    });

    testWidgets('el nombre es obligatorio', (tester) async {
      await irAMateriales(tester);

      await solicitar(tester, '   ');

      expect(find.text('Escribe el nombre del material'), findsOneWidget);
      expect(unica().solicitudesMaterial, isEmpty);
    });

    testWidgets('no se puede pedir dos veces el mismo material', (
      tester,
    ) async {
      await irAMateriales(tester);
      await solicitar(tester, 'Espuma');

      await solicitar(tester, 'ESPUMA');

      expect(unica().solicitudesMaterial, hasLength(1));
    });

    testWidgets('se puede quitar una solicitud', (tester) async {
      await irAMateriales(tester);
      await solicitar(tester, 'Espuma');

      await tester.tap(find.byTooltip('Quitar solicitud de Espuma'));
      await tester.pumpAndSettle();

      expect(unica().solicitudesMaterial, isEmpty);
    });
  });

  group('guardado en SQLite', () {
    late AppDatabase base;
    late ActasLocalSource fuente;

    setUp(() {
      base = baseEnMemoria();
      fuente = ActasLocalSource(base);
    });
    tearDown(() => base.cerrar());

    ActaLocal acta() => ActaLocal(
      uuidLocal: 'a1',
      predioId: 10,
      campaniaId: 1,
      fechaInspeccion: DateTime.utc(2026, 10, 9, 15),
    );

    test('las fotos y las solicitudes sobreviven al cerrar la app', () async {
      final original = acta()
          .conEvidencia('/f/1.jpg', 'Humedad')
          .conEvidencia('/f/2.jpg', '')
          .conSolicitudMaterial(
            const SolicitudMaterialActa(
              uuidLocal: 'u-1',
              nombre: 'Espuma',
              descripcion: 'Colchones',
              pesoKgEstimado: 40.5,
            ),
          );

      await fuente.guardar(original);
      final leida = (await fuente.obtener('a1'))!;

      expect(leida.evidencias.map((e) => (e.rutaLocal, e.descripcion)), [
        ('/f/1.jpg', 'Humedad'),
        ('/f/2.jpg', ''),
      ]);
      expect(leida.evidencias.every((e) => e.urlRemota == null), isTrue);
      final s = leida.solicitudesMaterial.single;
      expect(
        (s.uuidLocal, s.nombre, s.descripcion, s.pesoKgEstimado),
        ('u-1', 'Espuma', 'Colchones', 40.5),
      );
    });

    test('quitar una foto no la hace reaparecer', () async {
      await fuente.guardar(
        acta().conEvidencia('/f/1.jpg', '').conEvidencia('/f/2.jpg', ''),
      );

      await fuente.guardar(acta().conEvidencia('/f/2.jpg', ''));

      final leida = (await fuente.obtener('a1'))!;
      expect(leida.evidencias.map((e) => e.rutaLocal), ['/f/2.jpg']);
    });
  });
}
