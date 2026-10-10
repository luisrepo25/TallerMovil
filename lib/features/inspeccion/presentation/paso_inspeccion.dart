/// Pasos del asistente de inspección, en orden.
enum PasoInspeccion {
  predio('Predio'),
  seguridad('Seguridad'),
  materiales('Materiales'),
  infracciones('Infracciones'),
  evidencia('Evidencia'),
  resumen('Resumen');

  const PasoInspeccion(this.titulo);

  final String titulo;
}
