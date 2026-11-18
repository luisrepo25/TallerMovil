import 'package:app_movil_uubr/core/location/ubicacion_controller.dart';
import 'package:app_movil_uubr/core/location/ubicacion_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ubicacion_falsa.dart';

void main() {
  test(
    'si el permiso falta, explica primero y luego lo pide al sistema',
    () async {
      final gps = UbicacionFalsa()..explicarPermiso = true;
      var explicaciones = 0;
      final controlador = UbicacionController(
        gps,
        alExplicar: () async {
          explicaciones++;
          return true;
        },
      );

      await controlador.iniciar();

      expect(explicaciones, 1);
      expect(gps.vecesQueSePidioPermiso, 1);
      expect(controlador.permiso, PermisoUbicacion.concedido);
      controlador.dispose();
    },
  );

  test(
    'si el usuario dice "Ahora no", no se pide el permiso al sistema',
    () async {
      final gps = UbicacionFalsa()..explicarPermiso = true;
      final controlador = UbicacionController(
        gps,
        alExplicar: () async => false,
      );

      await controlador.iniciar();

      expect(gps.vecesQueSePidioPermiso, 0);
      expect(gps.alguienEscucha, isFalse);
      expect(controlador.permiso, PermisoUbicacion.denegado);
      expect(controlador.buscando, isFalse);
      controlador.dispose();
    },
  );

  test(
    'con "Ahora no" se puede reintentar desde el aviso y volver a explicar',
    () async {
      final gps = UbicacionFalsa()..explicarPermiso = true;
      var respuesta = false;
      final controlador = UbicacionController(
        gps,
        alExplicar: () async => respuesta,
      );

      await controlador.iniciar();
      respuesta = true;
      await controlador.iniciar();

      expect(gps.vecesQueSePidioPermiso, 1);
      expect(controlador.permiso, PermisoUbicacion.concedido);
      controlador.dispose();
    },
  );

  test('si el permiso ya se resolvió, no vuelve a explicar', () async {
    final gps = UbicacionFalsa();
    var explicaciones = 0;
    final controlador = UbicacionController(
      gps,
      alExplicar: () async {
        explicaciones++;
        return true;
      },
    );

    await controlador.iniciar();

    expect(explicaciones, 0);
    expect(gps.vecesQueSePidioPermiso, 1);
    controlador.dispose();
  });
}
