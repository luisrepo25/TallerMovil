import '../domain/acta_local.dart';

/// Convierte el resumen de un acta ya sincronizada (`GET /api/fiscalizacion/mis-actas/`) en
/// un [ActaLocal] en estado `sincronizada`. Sirve para recuperar el historial del inspector
/// en un teléfono nuevo o tras reinstalar: la app marca "Enviada" y una reinspección puede
/// mostrar la inspección anterior como referencia.
///
/// Nunca vuelve a enviarse (no está pendiente) ni lleva fotos (esas viven en la nube).
ActaLocal actaDesdeServidor(Map<String, dynamic> json) {
  final id = json['id'] as int;
  final materiales = [
    for (final m in (json['materiales'] as List? ?? const []))
      MaterialActa(
        materialId: (m as Map<String, dynamic>)['material_id'] as int,
        pesoKg: _numero(m['peso_kg']) ?? 0,
      ),
  ];

  return ActaLocal(
    // Las actas hechas en este teléfono ya traen su uuid; las demás (web, otro aparato)
    // usan uno derivado del id del servidor, estable entre descargas.
    uuidLocal: (json['uuid_local'] as String?) ?? 'servidor-$id',
    predioId: json['predio_id'] as int,
    campaniaId: json['campania_id'] as int,
    fechaInspeccion: DateTime.parse(json['fecha_inspeccion'] as String).toUtc(),
    estadoExtintoresId: json['estado_extintores_id'] as int?,
    fallasElectricas: json['fallas_electricas'] as bool?,
    rutasDespejadas: json['rutas_evacuacion_despejadas'] as bool?,
    estado: EstadoActa.sincronizada,
    sinMateriales: materiales.isEmpty,
    materiales: materiales,
    infracciones: [
      for (final i in (json['infracciones'] as List? ?? const []))
        InfraccionActa(
          tipoInfraccionId:
              (i as Map<String, dynamic>)['tipo_infraccion_id'] as int,
          descripcion: (i['descripcion'] as String?) ?? '',
        ),
    ],
    actaIdServidor: id,
    cargaFuego: _numero(json['carga_fuego']),
    scoringRiesgo: _numero(json['scoring_riesgo']),
    clusterRiesgo: json['cluster_riesgo'] as String?,
  );
}

double? _numero(Object? valor) =>
    valor == null ? null : double.tryParse(valor.toString());
