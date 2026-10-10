/// Posición del inspector. `precisionM` es el radio de error del GPS, en metros.
class Ubicacion {
  const Ubicacion({
    required this.lat,
    required this.lng,
    required this.precisionM,
  });

  final double lat;
  final double lng;
  final double precisionM;
}

/// Por qué se puede (o no) obtener la ubicación.
enum PermisoUbicacion {
  concedido,

  /// El usuario dijo "no", pero se puede volver a preguntar.
  denegado,

  /// "No volver a preguntar": solo se arregla desde los ajustes del teléfono.
  denegadoParaSiempre,

  /// El GPS del teléfono está apagado.
  gpsApagado,
}

/// Acceso a la ubicación del teléfono. Es una interfaz para poder sustituirla en las
/// pruebas (los tests no tienen GPS).
abstract class UbicacionService {
  /// Revisa el permiso y, si hace falta y se puede, lo pide.
  Future<PermisoUbicacion> verificarYPedirPermiso();

  /// Posiciones en vivo, una nueva cada vez que el inspector se mueve unos metros.
  Stream<Ubicacion> seguir();

  /// Abre los ajustes del teléfono donde el usuario puede activar el permiso o el GPS.
  Future<void> abrirAjustes(PermisoUbicacion motivo);
}
