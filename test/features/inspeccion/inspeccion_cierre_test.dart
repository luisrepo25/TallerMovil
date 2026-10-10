import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_inspeccion.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;

  setUp(() => almacen = ActasEnMemoria());

  ActaLocal unica() => almacen.actas.values.single;

  testWidgets(
    'recorrido completo: llena, revisa y cierra el acta; queda lista para enviar',
    (tester) async {
      final resultado = await abrirInspeccion(tester, almacen: almacen);
      await siguiente(tester);
      await tester.tap(find.text('Vigente'));
      await tester.pump();
      await siguiente(tester, 4);

      expect(find.text('Extintores: Vigente'), findsOneWidget);
      expect(find.text('Ninguno registrado'), findsOneWidget);
      expect(find.text('Indica el estado de los extintores.'), findsNothing);

      await tester.tap(find.text('Cerrar acta'));
      await tester.pumpAndSettle();

      expect(unica().estado, EstadoActa.cerradaLocal);
      expect(unica().fechaCierreLocal, isNotNull);
      expect(
        resultado.valor,
        isTrue,
        reason: 'vuelve al detalle avisando que se cerró',
      );
      expect(find.text('abrir inspección'), findsOneWidget);
      expect(
        find.text('Acta guardada. Se enviará cuando haya conexión.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Editar" en el resumen lleva al paso correspondiente', (
    tester,
  ) async {
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester, 5);

    await tester.tap(find.text('Editar').at(1)); // sección Seguridad
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 6 · Seguridad'), findsOneWidget);
  });

  testWidgets('retoma un borrador a medias: lo que ya llenó sigue ahí', (
    tester,
  ) async {
    final repo = ActasRepository(almacen);
    final previa =
        (await repo.iniciarOContinuar(
              campania: campaniaAbierta,
              predioId: predioPrueba.id,
            ))
            .copyWith(estadoExtintoresId: 2)
            .conMaterial(2, 80)
            .conInfraccion(1, 'Pasillo');
    await repo.guardar(previa);

    await abrirInspeccion(tester, almacen: almacen);

    expect(almacen.actas, hasLength(1), reason: 'no crea otro borrador');
    await siguiente(tester, 2);
    expect(find.text('Plásticos'), findsOneWidget);
    expect(find.text('80 kg'), findsOneWidget);
    await siguiente(tester);
    expect(find.text('Pasillo'), findsOneWidget);
  });

  testWidgets('una campaña cerrada no permite inspeccionar y lo explica', (
    tester,
  ) async {
    await abrirInspeccion(tester, almacen: almacen, campania: campaniaCerrada);

    expect(
      find.text('La campaña está cerrada: ya no admite inspecciones.'),
      findsOneWidget,
    );
    expect(find.text('Siguiente'), findsNothing);
    expect(almacen.actas, isEmpty);
  });
}
