import 'acta_local.dart';

/// Cambios de estado que no hace el inspector sino el envío al servidor o la reinspección.
/// Funciones puras: devuelven una copia nueva.
extension EnvioActa on ActaLocal {
  ActaLocal _con({
    EstadoActa? estado,
    List<EvidenciaActa>? evidencias,
    DateTime? fechaCierreLocal,
    bool sinFechaCierre = false,
    int? actaIdServidor,
    double? cargaFuego,
    double? scoringRiesgo,
    String? clusterRiesgo,
    String? motivoRechazo,
    DateTime? precargadaDe,
  }) => ActaLocal(
    uuidLocal: uuidLocal,
    predioId: predioId,
    campaniaId: campaniaId,
    fechaInspeccion: fechaInspeccion,
    estadoExtintoresId: estadoExtintoresId,
    fallasElectricas: fallasElectricas,
    rutasDespejadas: rutasDespejadas,
    estado: estado ?? this.estado,
    sinMateriales: sinMateriales,
    materiales: materiales,
    infracciones: infracciones,
    evidencias: evidencias ?? this.evidencias,
    solicitudesMaterial: solicitudesMaterial,
    fechaCierreLocal: sinFechaCierre
        ? null
        : fechaCierreLocal ?? this.fechaCierreLocal,
    actaIdServidor: actaIdServidor ?? this.actaIdServidor,
    cargaFuego: cargaFuego ?? this.cargaFuego,
    scoringRiesgo: scoringRiesgo ?? this.scoringRiesgo,
    clusterRiesgo: clusterRiesgo ?? this.clusterRiesgo,
    motivoRechazo: motivoRechazo ?? this.motivoRechazo,
    precargadaDe: precargadaDe ?? this.precargadaDe,
  );

  /// Una foto ya subida a la nube: no se vuelve a subir si el envío se corta a la mitad.
  ActaLocal conFotoSubida(String rutaLocal, String url) => _con(
    evidencias: [
      for (final e in evidencias)
        e.rutaLocal == rutaLocal ? e.copyWith(urlRemota: url) : e,
    ],
  );

  /// El servidor la aceptó y calculó la carga de fuego y el riesgo.
  ActaLocal sincronizada({
    required int actaIdServidor,
    double? cargaFuego,
    double? scoringRiesgo,
    String? clusterRiesgo,
  }) => _con(
    estado: EstadoActa.sincronizada,
    actaIdServidor: actaIdServidor,
    cargaFuego: cargaFuego,
    scoringRiesgo: scoringRiesgo,
    clusterRiesgo: clusterRiesgo,
  );

  /// El servidor no la aceptó. Se conserva (nunca se borra sola) con el motivo.
  ActaLocal rechazadaPorServidor(String motivo) =>
      _con(estado: EstadoActa.rechazada, motivoRechazo: motivo);

  /// Devuelve a borrador un acta cerrada que **todavía no llegó al servidor**, para
  /// corregirla. Una ya enviada no se reabre: es la foto histórica de esa fecha.
  ActaLocal reabierta() =>
      _con(estado: EstadoActa.borrador, sinFechaCierre: true);

  /// Marca el acta como reinspección de la hecha en [fecha]. **Parte en blanco**: copiar los
  /// datos de la anterior en silencio haría pasar por verificado lo que el inspector no vio,
  /// y el servidor marcaría como reincidencia infracciones que nadie volvió a constatar.
  ActaLocal comoReinspeccionDe(DateTime fecha) => _con(precargadaDe: fecha);

  /// Copia seguridad y materiales de la inspección anterior. Es una acción explícita del
  /// inspector (un toque) para no repetir lo que no cambió. **No copia infracciones ni
  /// fotos**: pertenecen a la inspección de aquel día y se constatan de nuevo.
  ActaLocal conSeguridadYMaterialesDe(ActaLocal anterior) => copyWith(
    estadoExtintoresId: anterior.estadoExtintoresId,
    fallasElectricas: anterior.fallasElectricas,
    rutasDespejadas: anterior.rutasDespejadas,
    materiales: anterior.materiales,
    sinMateriales: anterior.materiales.isEmpty && anterior.sinMateriales,
  );
}
