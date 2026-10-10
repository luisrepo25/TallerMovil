import 'dart:async';

import 'package:app_movil_uubr/core/location/ubicacion_service.dart';

/// GPS de mentira: se decide el permiso y se emiten posiciones a mano.
class UbicacionFalsa implements UbicacionService {
  UbicacionFalsa({this.permiso = PermisoUbicacion.concedido});

  PermisoUbicacion permiso;
  final _posiciones = StreamController<Ubicacion>.broadcast();
  int vecesQueSePidioPermiso = 0;
  PermisoUbicacion? ajustesAbiertosPor;

  bool get alguienEscucha => _posiciones.hasListener;

  /// Emite una posición como si el inspector se hubiera movido.
  void emitir(double lat, double lng, {double precisionM = 8}) {
    _posiciones.add(Ubicacion(lat: lat, lng: lng, precisionM: precisionM));
  }

  @override
  Future<PermisoUbicacion> verificarYPedirPermiso() async {
    vecesQueSePidioPermiso++;
    return permiso;
  }

  @override
  Stream<Ubicacion> seguir() => _posiciones.stream;

  @override
  Future<void> abrirAjustes(PermisoUbicacion motivo) async {
    ajustesAbiertosPor = motivo;
  }
}
