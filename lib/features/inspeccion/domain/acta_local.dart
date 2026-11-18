// Los tipos que forman un acta viven en archivos propios; se reexportan aquí para que
// quien importe `acta_local.dart` los siga viendo.
export 'acta_partes.dart';
export 'acta_sync_json.dart';
export 'estado_acta.dart';

import 'acta_partes.dart';
import 'estado_acta.dart';

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
    this.fallasElectricas,
    this.rutasDespejadas,
    this.estado = EstadoActa.borrador,
    this.sinMateriales = false,
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

  /// `null` = el inspector todavía no respondió. No hay valor por defecto: un "no" por
  /// descuido cambiaría el riesgo del predio, así que cerrar el acta exige responder.
  final bool? fallasElectricas;
  final bool? rutasDespejadas;
  final EstadoActa estado;

  /// El inspector confirmó que el predio no tiene materiales combustibles.
  final bool sinMateriales;
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
    if (fallasElectricas == null) 'Responde si hay fallas eléctricas.',
    if (rutasDespejadas == null)
      'Responde si las rutas de evacuación están despejadas.',
    if (materiales.isEmpty && solicitudesMaterial.isEmpty && !sinMateriales)
      'Registra los materiales combustibles o confirma que no hay.',
    if (infracciones.isNotEmpty && evidencias.isEmpty)
      'Agrega al menos una foto de evidencia de las infracciones.',
  ];

  bool get puedeCerrar => editable && faltantesParaCerrar.isEmpty;

  ActaLocal copyWith({
    int? estadoExtintoresId,
    bool? fallasElectricas,
    bool? rutasDespejadas,
    EstadoActa? estado,
    bool? sinMateriales,
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
    sinMateriales: sinMateriales ?? this.sinMateriales,
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
}
