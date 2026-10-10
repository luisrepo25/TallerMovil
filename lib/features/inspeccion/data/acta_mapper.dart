import '../domain/acta_local.dart';

/// Traduce entre filas de SQLite y [ActaLocal]. Sin acceso a la base: solo conversión.
class ActaMapper {
  ActaMapper._();

  static Map<String, Object?> aFila(ActaLocal a) => {
    'uuid_local': a.uuidLocal,
    'predio_id': a.predioId,
    'campania_id': a.campaniaId,
    'fecha_inspeccion': a.fechaInspeccion.toUtc().toIso8601String(),
    'estado_extintores_id': a.estadoExtintoresId,
    'fallas_electricas': a.fallasElectricas ? 1 : 0,
    'rutas_despejadas': a.rutasDespejadas ? 1 : 0,
    'estado': a.estado.clave,
    'fecha_cierre_local': a.fechaCierreLocal?.toUtc().toIso8601String(),
    'acta_id_servidor': a.actaIdServidor,
    'carga_fuego': a.cargaFuego,
    'scoring_riesgo': a.scoringRiesgo,
    'cluster_riesgo': a.clusterRiesgo,
    'motivo_rechazo': a.motivoRechazo,
    'precargada_de': a.precargadaDe?.toUtc().toIso8601String(),
  };

  static Map<String, Object?> materialAFila(String actaUuid, MaterialActa m) =>
      {'acta_uuid': actaUuid, 'material_id': m.materialId, 'peso_kg': m.pesoKg};

  static Map<String, Object?> infraccionAFila(
    String actaUuid,
    InfraccionActa i,
  ) => {
    'acta_uuid': actaUuid,
    'tipo_infraccion_id': i.tipoInfraccionId,
    'descripcion': i.descripcion,
  };

  static Map<String, Object?> evidenciaAFila(
    String actaUuid,
    EvidenciaActa e,
  ) => {
    'acta_uuid': actaUuid,
    'ruta_local': e.rutaLocal,
    'descripcion': e.descripcion,
    'url_remota': e.urlRemota,
  };

  static Map<String, Object?> solicitudAFila(
    String actaUuid,
    SolicitudMaterialActa s,
  ) => {
    'uuid_local': s.uuidLocal,
    'acta_uuid': actaUuid,
    'nombre': s.nombre,
    'descripcion': s.descripcion,
    'peso_kg_estimado': s.pesoKgEstimado,
  };

  static ActaLocal desdeFila(
    Map<String, Object?> fila, {
    required List<Map<String, Object?>> materiales,
    required List<Map<String, Object?>> infracciones,
    List<Map<String, Object?>> evidencias = const [],
    List<Map<String, Object?>> solicitudes = const [],
  }) {
    final cierre = fila['fecha_cierre_local'] as String?;
    final precargada = fila['precargada_de'] as String?;
    return ActaLocal(
      uuidLocal: fila['uuid_local']! as String,
      predioId: fila['predio_id']! as int,
      campaniaId: fila['campania_id']! as int,
      fechaInspeccion: DateTime.parse(fila['fecha_inspeccion']! as String),
      estadoExtintoresId: fila['estado_extintores_id'] as int?,
      fallasElectricas: (fila['fallas_electricas']! as int) == 1,
      rutasDespejadas: (fila['rutas_despejadas']! as int) == 1,
      estado: EstadoActa.desdeClave(fila['estado']! as String),
      fechaCierreLocal: cierre == null ? null : DateTime.parse(cierre),
      actaIdServidor: fila['acta_id_servidor'] as int?,
      cargaFuego: (fila['carga_fuego'] as num?)?.toDouble(),
      scoringRiesgo: (fila['scoring_riesgo'] as num?)?.toDouble(),
      clusterRiesgo: fila['cluster_riesgo'] as String?,
      motivoRechazo: fila['motivo_rechazo'] as String?,
      precargadaDe: precargada == null ? null : DateTime.parse(precargada),
      materiales: [
        for (final m in materiales)
          MaterialActa(
            materialId: m['material_id']! as int,
            pesoKg: (m['peso_kg']! as num).toDouble(),
          ),
      ],
      infracciones: [
        for (final i in infracciones)
          InfraccionActa(
            tipoInfraccionId: i['tipo_infraccion_id']! as int,
            descripcion: (i['descripcion'] as String?) ?? '',
          ),
      ],
      evidencias: [
        for (final e in evidencias)
          EvidenciaActa(
            rutaLocal: e['ruta_local']! as String,
            descripcion: (e['descripcion'] as String?) ?? '',
            urlRemota: e['url_remota'] as String?,
          ),
      ],
      solicitudesMaterial: [
        for (final s in solicitudes)
          SolicitudMaterialActa(
            uuidLocal: s['uuid_local']! as String,
            nombre: s['nombre']! as String,
            descripcion: (s['descripcion'] as String?) ?? '',
            pesoKgEstimado: (s['peso_kg_estimado'] as num?)?.toDouble(),
          ),
      ],
    );
  }
}
