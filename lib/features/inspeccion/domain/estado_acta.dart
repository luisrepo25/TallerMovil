/// Ciclo de vida de un acta en el teléfono:
///
///   borrador -> cerradaLocal -> sincronizada
///                          \-> rechazada (el servidor no la aceptó; NUNCA se borra sola)
enum EstadoActa {
  borrador,
  cerradaLocal,
  sincronizada,
  rechazada;

  /// Valor guardado en SQLite
  String get clave => switch (this) {
    EstadoActa.borrador => 'borrador',
    EstadoActa.cerradaLocal => 'cerrada_local',
    EstadoActa.sincronizada => 'sincronizada',
    EstadoActa.rechazada => 'rechazada',
  };

  static EstadoActa desdeClave(String clave) =>
      EstadoActa.values.firstWhere((e) => e.clave == clave);

  /// ¿Todavía no llegó al servidor? (hay trabajo que se perdería al borrar el teléfono)
  bool get pendienteDeEnvio => this != EstadoActa.sincronizada;

  /// ¿El inspector ya la terminó? (todo menos el borrador)
  bool get cerrada => this != EstadoActa.borrador;
}
