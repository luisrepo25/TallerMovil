import 'acta_local.dart';

/// Formato de envío al servidor. Vive aparte del acta para que la entidad no conozca el
/// contrato de la API.
extension SyncActa on ActaLocal {
  /// Cuerpo que espera `POST /api/fiscalizacion/sync/actas/` para esta acta. Las fechas
  /// van en UTC con zona (ISO 8601).
  Map<String, dynamic> toSyncJson() => {
    'uuid_local': uuidLocal,
    'predio_id': predioId,
    'campania_id': campaniaId,
    'estado_extintores_id': estadoExtintoresId,
    // Cerrar el acta exige responderlas: los valores por defecto no se alcanzan.
    'fallas_electricas': fallasElectricas ?? false,
    'rutas_evacuacion_despejadas': rutasDespejadas ?? true,
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
