import 'package:app_movil_uubr/core/location/ubicacion_service.dart';
import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/campanias/presentation/screens/campania_detalle_screen.dart';
import 'package:app_movil_uubr/features/catastro/data/predios_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/catalogos_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/evidencias_archivos.dart';
import 'package:app_movil_uubr/sync/envio_service.dart';
import 'package:app_movil_uubr/features/catastro/domain/predio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'datos_descarga.dart';
import 'fake_adapter.dart';
import 'inspeccion_en_memoria.dart';
import 'ubicacion_falsa.dart';

/// Repositorio con datos en memoria: evita SQLite (asíncrono real) dentro de una prueba de pantalla.
class PrediosFalsos implements PrediosRepository {
  PrediosFalsos(this.predios);

  final List<Predio> predios;

  @override
  Future<List<Predio>> listar() async => predios;

  @override
  Future<List<Predio>> enZona(Campania campania) async =>
      PrediosRepository.filtrarEnZona(predios, campania);
}

/// Abre el detalle de una campaña con un tamaño de teléfono, predios simulados y un GPS falso.
Future<void> abrirDetalle(
  WidgetTester tester,
  Campania campania,
  List<Predio> predios, {
  UbicacionFalsa? gps,
  ActasEnMemoria? actas,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final almacen = actas ?? ActasEnMemoria();
  // Sin red: lo que se cierre en la prueba queda "Lista para enviar"
  final envio = crearEnvio(almacen, FakeAdapter((o) async => throw sinRed(o)));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<EnvioService>.value(value: envio),
        Provider<PrediosRepository>.value(value: PrediosFalsos(predios)),
        Provider<UbicacionService>.value(value: gps ?? UbicacionFalsa()),
        Provider<ActasRepository>.value(value: ActasRepository(almacen)),
        Provider<CatalogosRepository>.value(
          value: CatalogosRepository(CatalogosEnMemoria()),
        ),
        Provider<EvidenciasArchivos>.value(value: EvidenciasFalsas()),
      ],
      child: MaterialApp(home: CampaniaDetalleScreen(campania: campania)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Mueve al "inspector" y deja que el evento llegue y la pantalla se redibuje
/// (el flujo entrega el evento en un microtask: hace falta un redibujado extra).
Future<void> moverInspector(
  WidgetTester tester,
  UbicacionFalsa gps,
  double lat,
  double lng,
) async {
  gps.emitir(lat, lng);
  await tester.pump();
  await tester.pump();
}
