import 'package:app_movil_uubr/features/catastro/domain/predio.dart';
import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/abrir_detalle.dart';
import '../../helpers/datos_descarga.dart';
import '../../helpers/inspeccion_en_memoria.dart';

void main() {
  final zona = Campania.fromApi(
    campaniaJson(1, 'Zona Norte', geom: zonaNorte()),
  );
  final cerrada = Campania.fromApi(
    campaniaJson(2, 'Vieja', geom: zonaNorte(), estado: 'cerrada'),
  );
  final dentro = Predio.fromApi(predioDentro(10));

  ActaLocal acta(EstadoActa estado, {int campania = 1}) => ActaLocal(
    uuidLocal: 'u-${estado.name}',
    predioId: 10,
    campaniaId: campania,
    fechaInspeccion: DateTime.utc(2026, 10, 9, 12),
    estadoExtintoresId: 1,
    estado: estado,
  );

  testWidgets('un predio sin inspeccionar lo dice y ofrece "Inspeccionar"', (
    tester,
  ) async {
    await abrirDetalle(tester, zona, [dentro]);

    expect(find.text('Sin inspeccionar'), findsOneWidget);
    expect(find.text('Inspeccionar'), findsOneWidget);
  });

  testWidgets('con un borrador a medias ofrece "Continuar"', (tester) async {
    final almacen = ActasEnMemoria()..actas['u'] = acta(EstadoActa.borrador);
    await abrirDetalle(tester, zona, [dentro], actas: almacen);

    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets(
    'con el acta cerrada dice "Lista para enviar" y ofrece reinspeccionar',
    (tester) async {
      final almacen = ActasEnMemoria()
        ..actas['u'] = acta(EstadoActa.cerradaLocal);
      await abrirDetalle(tester, zona, [dentro], actas: almacen);

      expect(find.text('Lista para enviar'), findsOneWidget);
      expect(find.text('Reinspeccionar'), findsOneWidget);
    },
  );

  testWidgets('un acta ya enviada se marca como "Enviada"', (tester) async {
    await abrirDetalle(
      tester,
      zona,
      [dentro],
      actas: ActasEnMemoria()..actas['u'] = acta(EstadoActa.sincronizada),
    );

    expect(find.text('Enviada'), findsOneWidget);
  });

  testWidgets('un acta que el servidor rechazó se marca "Rechazada"', (
    tester,
  ) async {
    await abrirDetalle(tester, zona, [
      dentro,
    ], actas: ActasEnMemoria()..actas['u'] = acta(EstadoActa.rechazada));

    expect(find.text('Rechazada'), findsOneWidget);
  });

  testWidgets('el botón abre el asistente de inspección del predio', (
    tester,
  ) async {
    await abrirDetalle(tester, zona, [dentro]);

    await tester.tap(find.text('Inspeccionar'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 6 · Predio'), findsOneWidget);
  });

  testWidgets('al volver de la inspección el predio muestra su nuevo estado', (
    tester,
  ) async {
    final almacen = ActasEnMemoria();
    await abrirDetalle(tester, zona, [dentro], actas: almacen);
    await tester.tap(find.text('Inspeccionar'));
    await tester.pumpAndSettle();
    expect(almacen.actas, hasLength(1), reason: 'se creó el borrador');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('en una campaña cerrada no se ofrece inspeccionar', (
    tester,
  ) async {
    await abrirDetalle(tester, cerrada, [dentro]);

    expect(find.text('Sin inspeccionar'), findsOneWidget);
    expect(find.text('Inspeccionar'), findsNothing);
  });
}
