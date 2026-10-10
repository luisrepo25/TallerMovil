import 'package:app_movil_uubr/core/location/ubicacion_service.dart';
import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/catastro/domain/predio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/abrir_detalle.dart';
import '../helpers/datos_descarga.dart';
import '../helpers/ubicacion_falsa.dart';

void main() {
  final zona = Campania.fromApi(
    campaniaJson(1, 'Zona Norte', geom: zonaNorte()),
  );
  final predios = [Predio.fromApi(predioDentro(10))];

  testWidgets('mientras llega la posición dice que la está buscando', (
    tester,
  ) async {
    await abrirDetalle(tester, zona, predios);

    expect(find.text('Buscando tu ubicación...'), findsOneWidget);
  });

  testWidgets('dentro de la zona: lo dice con texto y ofrece centrar el mapa', (
    tester,
  ) async {
    final gps = UbicacionFalsa();
    await abrirDetalle(tester, zona, predios, gps: gps);

    await moverInspector(tester, gps, -17.785, -63.185); // dentro de zonaNorte

    expect(find.text('Estás en la zona de la campaña'), findsOneWidget);
    expect(find.byTooltip('Mi ubicación'), findsOneWidget);
  });

  testWidgets('fuera de la zona: avisa que está fuera', (tester) async {
    final gps = UbicacionFalsa();
    await abrirDetalle(tester, zona, predios, gps: gps);

    await moverInspector(tester, gps, -17.70, -63.10); // lejos de la zona

    expect(find.text('Estás fuera de la zona'), findsOneWidget);
  });

  testWidgets(
    'sin permiso explica qué hacer, abre los ajustes y no rompe el mapa',
    (tester) async {
      final gps = UbicacionFalsa(permiso: PermisoUbicacion.denegadoParaSiempre);
      await abrirDetalle(tester, zona, predios, gps: gps);

      expect(find.textContaining('Ubicación desactivada'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);

      await tester.tap(find.textContaining('Ubicación desactivada'));
      await tester.pump();
      expect(gps.ajustesAbiertosPor, PermisoUbicacion.denegadoParaSiempre);
    },
  );

  testWidgets('con el GPS apagado lo indica', (tester) async {
    final gps = UbicacionFalsa(permiso: PermisoUbicacion.gpsApagado);
    await abrirDetalle(tester, zona, predios, gps: gps);

    expect(find.textContaining('GPS apagado'), findsOneWidget);
  });

  testWidgets('al salir de la pantalla se deja de escuchar el GPS', (
    tester,
  ) async {
    final gps = UbicacionFalsa();
    await abrirDetalle(tester, zona, predios, gps: gps);
    expect(gps.alguienEscucha, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(gps.alguienEscucha, isFalse);
  });
}
