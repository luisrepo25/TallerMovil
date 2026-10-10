import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_inspeccion.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;

  setUp(() => almacen = ActasEnMemoria());

  ActaLocal unica() => almacen.actas.values.single;

  testWidgets('abre en el paso 1 con los datos del predio y crea el borrador', (
    tester,
  ) async {
    await abrirInspeccion(tester, almacen: almacen);

    expect(find.text('Paso 1 de 6 · Predio'), findsOneWidget);
    expect(find.text('Dentro 10'), findsWidgets);
    expect(find.text('Calle 10'), findsOneWidget);
    expect(find.text('Campaña: Zona Norte'), findsOneWidget);
    expect(unica().estado, EstadoActa.borrador);
  });

  testWidgets('"Siguiente" y "Atrás" recorren los pasos', (tester) async {
    await abrirInspeccion(tester, almacen: almacen);
    expect(
      find.text('Atrás'),
      findsNothing,
      reason: 'en el primer paso no hay "Atrás"',
    );

    await siguiente(tester);
    expect(find.text('Paso 2 de 6 · Seguridad'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 6 · Predio'), findsOneWidget);
  });

  testWidgets(
    'elegir el estado de los extintores se guarda al instante (autoguardado)',
    (tester) async {
      await abrirInspeccion(tester, almacen: almacen);
      await siguiente(tester);

      await tester.tap(find.text('Vencido'));
      await tester.pump();

      expect(unica().estadoExtintoresId, 2);
    },
  );

  testWidgets('las preguntas Sí/No cambian y se guardan', (tester) async {
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester);

    // Fallas eléctricas parte en "No": se marca "Sí"
    await tester.tap(find.text('Sí').first);
    await tester.pumpAndSettle();
    // Rutas despejadas parte en "Sí": se marca "No"
    await tester.tap(find.text('No').last);
    await tester.pumpAndSettle();

    expect(unica().fallasElectricas, isTrue);
    expect(unica().rutasDespejadas, isFalse);
  });

  testWidgets(
    'sin los extintores el resumen explica qué falta y no deja cerrar',
    (tester) async {
      final resultado = await abrirInspeccion(tester, almacen: almacen);
      await siguiente(tester, 5);

      expect(find.text('Paso 6 de 6 · Resumen'), findsOneWidget);
      expect(find.text('Indica el estado de los extintores.'), findsOneWidget);

      await tester.tap(find.text('Cerrar acta'));
      await tester.pumpAndSettle();

      expect(unica().estado, EstadoActa.borrador, reason: 'no se cerró');
      expect(resultado.valor, isNull, reason: 'sigue en la pantalla');
    },
  );
}
