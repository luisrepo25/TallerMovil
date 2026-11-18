class ResultadoEnvio {
  const ResultadoEnvio({
    this.enviadas = 0,
    this.rechazadas = 0,
    this.pendientes = 0,
    this.fotosOmitidas = 0,
    this.sinConexion = false,
    this.aviso,
  });

  /// Actas que el servidor aceptó en esta corrida.
  final int enviadas;

  /// Actas que el servidor rechazó (quedan en el teléfono con el motivo).
  final int rechazadas;

  /// Actas que siguen esperando (sin conexión o servidor con problemas).
  final int pendientes;

  /// Fotos que no se pudieron subir (archivo borrado o imagen no válida) y viajaron sin ella.
  final int fotosOmitidas;
  final bool sinConexion;

  /// Problema que cortó el envío, listo para mostrar.
  final String? aviso;
}

/// Una condición que detiene el envío de TODAS las actas pendientes (no solo de la actual).
class EnvioDetenido implements Exception {
  const EnvioDetenido(this.aviso, {this.sinConexion = false});

  final String aviso;
  final bool sinConexion;
}
