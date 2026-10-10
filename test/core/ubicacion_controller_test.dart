import 'package:app_movil_uubr/core/location/ubicacion_controller.dart';
import 'package:app_movil_uubr/core/location/ubicacion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ubicacion_falsa.dart';

void main() {
  test(
    'con permiso, sigue la posición y se actualiza cuando el inspector se mueve',
    () async {
      final gps = UbicacionFalsa();
      final controlador = UbicacionController(gps);

      await controlador.iniciar();
      expect(
        controlador.buscando,
        isTrue,
        reason: 'aún no llegó la primera posición',
      );

      gps.emitir(-17.785, -63.185);
      await Future<void>.delayed(Duration.zero);

      expect(controlador.actual!.lat, -17.785);
      expect(controlador.buscando, isFalse);

      gps.emitir(-17.786, -63.186, precisionM: 5);
      await Future<void>.delayed(Duration.zero);
      expect(controlador.actual!.lat, -17.786);
      expect(controlador.actual!.precisionM, 5);
      controlador.dispose();
    },
  );

  test(
    'sin permiso no se queda buscando para siempre y no escucha el GPS',
    () async {
      final gps = UbicacionFalsa(permiso: PermisoUbicacion.denegadoParaSiempre);
      final controlador = UbicacionController(gps);

      await controlador.iniciar();

      expect(controlador.permiso, PermisoUbicacion.denegadoParaSiempre);
      expect(controlador.buscando, isFalse);
      expect(controlador.actual, isNull);
      expect(gps.alguienEscucha, isFalse);
      controlador.dispose();
    },
  );

  test(
    'si el usuario activa el GPS, reintentar empieza a seguir la posición',
    () async {
      final gps = UbicacionFalsa(permiso: PermisoUbicacion.gpsApagado);
      final controlador = UbicacionController(gps);
      await controlador.iniciar();
      expect(gps.alguienEscucha, isFalse);

      gps.permiso = PermisoUbicacion.concedido;
      await controlador.iniciar();
      gps.emitir(-17.78, -63.18);
      await Future<void>.delayed(Duration.zero);

      expect(controlador.actual, isNotNull);
      controlador.dispose();
    },
  );

  test('abrirAjustes lleva al ajuste correcto según el motivo', () async {
    final gps = UbicacionFalsa(permiso: PermisoUbicacion.gpsApagado);
    final controlador = UbicacionController(gps);
    await controlador.iniciar();

    await controlador.abrirAjustes();

    expect(gps.ajustesAbiertosPor, PermisoUbicacion.gpsApagado);
    controlador.dispose();
  });

  test(
    'al cerrar la pantalla deja de escuchar el GPS (ahorra batería)',
    () async {
      final gps = UbicacionFalsa();
      final controlador = UbicacionController(gps);
      await controlador.iniciar();
      expect(gps.alguienEscucha, isTrue);

      controlador.dispose();

      expect(gps.alguienEscucha, isFalse);
    },
  );
}
