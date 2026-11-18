import 'dart:async';

import 'package:app_movil_uubr/sync/reintento_envio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deja pasar el tiempo real (los intervalos de estas pruebas son de milisegundos).
Future<void> esperar(int ms) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late StreamController<bool> red;
  late int envios;
  late bool pendientes;
  late ReintentoEnvio reintento;

  setUp(() {
    red = StreamController<bool>();
    envios = 0;
    pendientes = true;
    reintento = ReintentoEnvio(
      conexion: red.stream,
      enviar: () async => envios++,
      hayPendientes: () => pendientes,
      intervalo: const Duration(milliseconds: 80),
    );
  });

  tearDown(() {
    reintento.detener();
    red.close();
  });

  test('al volver la red con actas pendientes, intenta enviar', () async {
    reintento.iniciar();
    red.add(true);
    await esperar(10);
    expect(envios, 1);
  });

  test('al perder la red no intenta enviar', () async {
    reintento.iniciar();
    red.add(false);
    await esperar(10);
    expect(envios, 0);
  });

  test(
    'sin actas pendientes no envía, ni por red ni por el temporizador',
    () async {
      pendientes = false;
      reintento.iniciar();
      red.add(true);
      await esperar(200);
      expect(envios, 0);
    },
  );

  test('aunque no llegue el aviso de red, reintenta periódicamente', () async {
    reintento.iniciar();
    await esperar(40);
    expect(envios, 0, reason: 'todavía no pasó el intervalo');
    await esperar(200);
    expect(envios, greaterThanOrEqualTo(2));
  });

  test('al detener, deja de reintentar', () async {
    reintento.iniciar();
    reintento.detener();
    red.add(true);
    await esperar(200);
    expect(envios, 0);
  });
}
