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

class MaterialActa {
  const MaterialActa({required this.materialId, required this.pesoKg});

  final int materialId;
  final double pesoKg;
}

class InfraccionActa {
  const InfraccionActa({required this.tipoInfraccionId, this.descripcion = ''});

  final int tipoInfraccionId;
  final String descripcion;
}

/// Foto de evidencia. Se guarda en el teléfono ([rutaLocal]) y se sube a la nube al
/// sincronizar; solo entonces tiene [urlRemota]. No hay tope de fotos por acta.
class EvidenciaActa {
  const EvidenciaActa({
    required this.rutaLocal,
    this.descripcion = '',
    this.urlRemota,
  });

  final String rutaLocal;
  final String descripcion;
  final String? urlRemota;

  EvidenciaActa copyWith({String? descripcion, String? urlRemota}) =>
      EvidenciaActa(
        rutaLocal: rutaLocal,
        descripcion: descripcion ?? this.descripcion,
        urlRemota: urlRemota ?? this.urlRemota,
      );
}

/// Pedido al administrador para dar de alta un material que no está en el catálogo.
/// El inspector no define su poder calorífico ni su peligrosidad (son datos de la norma):
/// el administrador lo aprueba con esos valores. Mientras tanto NO cuenta en la carga de fuego.
class SolicitudMaterialActa {
  const SolicitudMaterialActa({
    required this.uuidLocal,
    required this.nombre,
    this.descripcion = '',
    this.pesoKgEstimado,
  });

  /// Identificador único: permite reenviar la solicitud sin duplicarla.
  final String uuidLocal;
  final String nombre;
  final String descripcion;
  final double? pesoKgEstimado;

  /// Cuerpo de `POST /api/fiscalizacion/solicitudes-material/`.
  Map<String, dynamic> toJson() => {
    'uuid_local': uuidLocal,
    'nombre': nombre,
    if (descripcion.isNotEmpty) 'descripcion': descripcion,
    if (pesoKgEstimado != null)
      'peso_kg_estimado': pesoKgEstimado!.toStringAsFixed(2),
  };
}

/// Acta de inspección hecha en el teléfono. Inmutable: cada cambio crea una copia.
/// **No lleva carga de fuego ni scoring calculados aquí**: los pone el servidor al
/// sincronizar (`cargaFuego`, `scoringRiesgo`, `clusterRiesgo` quedan nulos hasta entonces).
class ActaLocal {
  const ActaLocal({
    required this.uuidLocal,
    required this.predioId,
    required this.campaniaId,
    required this.fechaInspeccion,
    this.estadoExtintoresId,
    this.fallasElectricas = false,
    this.rutasDespejadas = true,
    this.estado = EstadoActa.borrador,
    this.materiales = const [],
    this.infracciones = const [],
    this.evidencias = const [],
    this.solicitudesMaterial = const [],
    this.fechaCierreLocal,
    this.actaIdServidor,
    this.cargaFuego,
    this.scoringRiesgo,
    this.clusterRiesgo,
    this.motivoRechazo,
    this.precargadaDe,
  });

  final String uuidLocal;
  final int predioId;
  final int campaniaId;

  /// Momento real de la inspección (UTC). Es el que se envía al servidor, no el de la
  /// sincronización.
  final DateTime fechaInspeccion;
  final int? estadoExtintoresId;
  final bool fallasElectricas;
  final bool rutasDespejadas;
  final EstadoActa estado;
  final List<MaterialActa> materiales;
  final List<InfraccionActa> infracciones;
  final List<EvidenciaActa> evidencias;
  final List<SolicitudMaterialActa> solicitudesMaterial;
  final DateTime? fechaCierreLocal;

  // Resultados del servidor (solo tras sincronizar)
  final int? actaIdServidor;
  final double? cargaFuego;
  final double? scoringRiesgo;
  final String? clusterRiesgo;
  final String? motivoRechazo;

  /// Fecha de la inspección anterior de la que se copiaron los datos de partida (una
  /// reinspección no empieza de cero). `null` en una primera inspección.
  final DateTime? precargadaDe;

  bool get editable => estado == EstadoActa.borrador;

  /// Qué falta para poder cerrar el acta (vacío = lista para cerrar).
  List<String> get faltantesParaCerrar => [
    if (estadoExtintoresId == null) 'Indica el estado de los extintores.',
  ];

  bool get puedeCerrar => editable && faltantesParaCerrar.isEmpty;

  ActaLocal copyWith({
    int? estadoExtintoresId,
    bool? fallasElectricas,
    bool? rutasDespejadas,
    EstadoActa? estado,
    List<MaterialActa>? materiales,
    List<InfraccionActa>? infracciones,
    List<EvidenciaActa>? evidencias,
    List<SolicitudMaterialActa>? solicitudesMaterial,
    DateTime? fechaCierreLocal,
  }) => ActaLocal(
    uuidLocal: uuidLocal,
    predioId: predioId,
    campaniaId: campaniaId,
    fechaInspeccion: fechaInspeccion,
    estadoExtintoresId: estadoExtintoresId ?? this.estadoExtintoresId,
    fallasElectricas: fallasElectricas ?? this.fallasElectricas,
    rutasDespejadas: rutasDespejadas ?? this.rutasDespejadas,
    estado: estado ?? this.estado,
    materiales: materiales ?? this.materiales,
    infracciones: infracciones ?? this.infracciones,
    evidencias: evidencias ?? this.evidencias,
    solicitudesMaterial: solicitudesMaterial ?? this.solicitudesMaterial,
    fechaCierreLocal: fechaCierreLocal ?? this.fechaCierreLocal,
    actaIdServidor: actaIdServidor,
    cargaFuego: cargaFuego,
    scoringRiesgo: scoringRiesgo,
    clusterRiesgo: clusterRiesgo,
    motivoRechazo: motivoRechazo,
    precargadaDe: precargadaDe,
  );

  /// Fotos que ya están en la nube. El envío del acta debe subir antes las que faltan
  /// (`POST /api/fiscalizacion/evidencias/subir/`); una foto sin URL no viaja en el acta.
  List<EvidenciaActa> get evidenciasPorSubir =>
      evidencias.where((e) => e.urlRemota == null).toList();

  /// Cuerpo que espera `POST /api/fiscalizacion/sync/actas/` para esta acta. Las fechas
  /// van en UTC con zona (ISO 8601).
  Map<String, dynamic> toSyncJson() => {
    'uuid_local': uuidLocal,
    'predio_id': predioId,
    'campania_id': campaniaId,
    'estado_extintores_id': estadoExtintoresId,
    'fallas_electricas': fallasElectricas,
    'rutas_evacuacion_despejadas': rutasDespejadas,
    'fecha_inspeccion': fechaInspeccion.toUtc().toIso8601String(),
    'materiales': [
      for (final m in materiales)
        {'material_id': m.materialId, 'peso_kg': m.pesoKg.toStringAsFixed(2)},
    ],
    'infracciones': [
      for (final i in infracciones)
        {
          'tipo_infraccion_id': i.tipoInfraccionId,
          'descripcion': i.descripcion,
        },
    ],
    'evidencias': [
      for (final e in evidencias)
        if (e.urlRemota != null)
          {'url_imagen': e.urlRemota, 'descripcion_infraccion': e.descripcion},
    ],
  };
}
