import 'package:app_movil_uubr/features/campanias/domain/campania.dart';
import 'package:app_movil_uubr/features/catastro/domain/predio.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/catalogos_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/evidencias_archivos.dart';
import 'package:app_movil_uubr/features/inspeccion/presentation/screens/inspeccion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'datos_descarga.dart';
import 'inspeccion_en_memoria.dart';

final campaniaAbierta = Campania.fromApi(
  campaniaJson(1, 'Zona Norte', geom: zonaNorte()),
);
final campaniaCerrada = Campania.fromApi(
  campaniaJson(2, 'Vieja', estado: 'cerrada'),
);
final predioPrueba = Predio.fromApi(predioDentro(10));

/// Resultado de la pantalla de inspección (`true` si el acta quedó cerrada al volver).
class ResultadoInspeccion {
  bool? valor;
}

/// Abre el asistente de inspección con un tamaño de teléfono y datos en memoria. Se abre
/// con `push` desde una pantalla de partida, igual que en la app, para poder ver el valor
/// con el que se cierra.
Future<ResultadoInspeccion> abrirInspeccion(
  WidgetTester tester, {
  required ActasEnMemoria almacen,
  Campania? campania,
  EvidenciasFalsas? camara,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final resultado = ResultadoInspeccion();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ActasRepository>.value(value: ActasRepository(almacen)),
        Provider<CatalogosRepository>.value(
          value: CatalogosRepository(CatalogosEnMemoria()),
        ),
        Provider<EvidenciasArchivos>.value(value: camara ?? EvidenciasFalsas()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado.valor = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => InspeccionScreen(
                        campania: campania ?? campaniaAbierta,
                        predio: predioPrueba,
                      ),
                    ),
                  );
                },
                child: const Text('abrir inspección'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir inspección'));
  await tester.pumpAndSettle();
  return resultado;
}

/// Pulsa "Siguiente" [veces] veces.
Future<void> siguiente(WidgetTester tester, [int veces = 1]) async {
  for (var i = 0; i < veces; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }
}
