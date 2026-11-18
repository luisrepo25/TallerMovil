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
