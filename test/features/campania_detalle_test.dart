import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/campanias/presentation/widgets/predio_tile.dart';
import 'package:app_movil_uubr/features/catastro/domain/predio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/abrir_detalle.dart';
import '../helpers/datos_descarga.dart';

void main() {
  final zona = Campania.fromApi(
    campaniaJson(1, 'Zona Norte', geom: zonaNorte()),
  );
  final dentro = Predio.fromApi(predioDentro(10));
  final fuera = Predio.fromApi(predioFuera(11));

  testWidgets(
    'muestra el mapa de la zona y la lista de predios que caen en ella',
    (tester) async {
      await abrirDetalle(tester, zona, [dentro, fuera]);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('1 predio en la zona'), findsOneWidget);
      expect(find.text('Dentro 10'), findsOneWidget);
      expect(
        find.text('Fuera 11'),
        findsNothing,
        reason: 'cae fuera de la zona',
      );
    },
  );

  testWidgets('tocar un predio de la lista lo deja seleccionado', (
    tester,
  ) async {
    await abrirDetalle(tester, zona, [dentro]);
    expect(
      tester.widget<PredioTile>(find.byType(PredioTile)).seleccionado,
      isFalse,
    );

    await tester.tap(find.text('Dentro 10'));
    await tester.pump();

    expect(
      tester.widget<PredioTile>(find.byType(PredioTile)).seleccionado,
      isTrue,
    );
  });

  testWidgets('una campaña sin zona no muestra mapa y lo explica', (
    tester,
  ) async {
    await abrirDetalle(tester, Campania.fromApi(campaniaJson(2, 'Sin zona')), [
      dentro,
    ]);

    expect(find.byType(FlutterMap), findsNothing);
    expect(find.text('Esta campaña aún no tiene zona'), findsOneWidget);
  });
}
