import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_inspeccion.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;

  setUp(() => almacen = ActasEnMemoria());

  ActaLocal unica() => almacen.actas.values.single;

  testWidgets('agregar un material con su peso lo muestra y lo guarda', (
    tester,
  ) async {
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester, 2);
    expect(find.text('Paso 3 de 6 · Materiales'), findsOneWidget);

    await tester.tap(find.text('Agregar material'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Madera').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Peso (kg)'),
      '300',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Madera'), findsOneWidget);
    expect(find.text('300 kg'), findsOneWidget);
    expect(unica().materiales.single.materialId, 1);
    expect(unica().materiales.single.pesoKg, 300);
  });

  testWidgets('el peso se valida: vacío, cero y texto no se aceptan', (
    tester,
  ) async {
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester, 2);
    await tester.tap(find.text('Agregar material'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Madera').last);
    await tester.pumpAndSettle();

    Future<void> intentar(String texto) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Peso (kg)'),
        texto,
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    await intentar('');
    expect(find.text('Escribe el peso en kg'), findsOneWidget);
    await intentar('abc');
    expect(find.text('Escribe el peso en kg'), findsOneWidget);
    await intentar('0');
    expect(find.text('Debe ser mayor que cero'), findsOneWidget);
    expect(almacen.actas.values.single.materiales, isEmpty);

    await intentar('12,5'); // se acepta la coma decimal
    expect(unica().materiales.single.pesoKg, 12.5);
  });

  testWidgets('quitar un material lo borra del acta', (tester) async {
    final repo = ActasRepository(almacen);
    final acta = (await repo.iniciarOContinuar(
      campania: campaniaAbierta,
      predioId: predioPrueba.id,
    )).conMaterial(1, 300);
    await repo.guardar(acta);
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester, 2);

    await tester.tap(find.byTooltip('Quitar Madera'));
    await tester.pumpAndSettle();

    expect(unica().materiales, isEmpty);
  });

  testWidgets('registrar una infracción con su detalle', (tester) async {
    await abrirInspeccion(tester, almacen: almacen);
    await siguiente(tester, 3);
    expect(find.text('Paso 4 de 6 · Infracciones'), findsOneWidget);

    await tester.tap(find.text('Registrar infracción'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extintor vencido').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Detalle (opcional)'),
      'Sin carga',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Extintor vencido'), findsOneWidget);
    expect(find.text('Sin carga'), findsOneWidget);
    expect(unica().infracciones.single.tipoInfraccionId, 1);
  });
}
