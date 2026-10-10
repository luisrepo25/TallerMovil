import 'package:geolocator/geolocator.dart';

import 'ubicacion_service.dart';

/// Implementación real sobre el GPS del teléfono (paquete `geolocator`).
class GeolocatorUbicacionService implements UbicacionService {
  /// Se emite una posición nueva cada 5 m: suficiente para caminar entre predios sin
  /// gastar batería de más.
  static const _filtroDistanciaM = 5;

  @override
  Future<PermisoUbicacion> verificarYPedirPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PermisoUbicacion.gpsApagado;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    switch (permiso) {
      case LocationPermission.deniedForever:
        return PermisoUbicacion.denegadoParaSiempre;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermisoUbicacion.denegado;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return PermisoUbicacion.concedido;
    }
  }

  @override
  Stream<Ubicacion> seguir() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _filtroDistanciaM,
      ),
    ).map(
      (p) =>
          Ubicacion(lat: p.latitude, lng: p.longitude, precisionM: p.accuracy),
    );
  }

  @override
  Future<void> abrirAjustes(PermisoUbicacion motivo) async {
    if (motivo == PermisoUbicacion.gpsApagado) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
