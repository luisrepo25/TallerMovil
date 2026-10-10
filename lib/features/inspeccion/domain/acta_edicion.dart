import 'acta_local.dart';

/// Cambios que el inspector puede hacerle a un acta abierta. Son funciones puras: devuelven
/// una copia nueva y no tocan SQLite ni la pantalla (por eso se prueban solas).
///
/// Regla: un material y una infracción aparecen una sola vez por acta. Para cambiar la
/// cantidad o el detalle se edita la entrada existente, no se agrega otra.
extension EdicionActa on ActaLocal {
  /// Agrega el material o, si ya estaba, le cambia el peso (conserva su posición).
  ActaLocal conMaterial(int materialId, double pesoKg) {
    final nuevo = MaterialActa(materialId: materialId, pesoKg: pesoKg);
    final existe = materiales.any((m) => m.materialId == materialId);
    return copyWith(
      materiales: existe
          ? [for (final m in materiales) m.materialId == materialId ? nuevo : m]
          : [...materiales, nuevo],
    );
  }

  ActaLocal sinMaterial(int materialId) => copyWith(
    materiales: materiales.where((m) => m.materialId != materialId).toList(),
  );

  /// Agrega la infracción o, si ya estaba, le cambia el detalle.
  ActaLocal conInfraccion(int tipoId, String descripcion) {
    final nueva = InfraccionActa(
      tipoInfraccionId: tipoId,
      descripcion: descripcion.trim(),
    );
    final existe = infracciones.any((i) => i.tipoInfraccionId == tipoId);
    return copyWith(
      infracciones: existe
          ? [
              for (final i in infracciones)
                i.tipoInfraccionId == tipoId ? nueva : i,
            ]
          : [...infracciones, nueva],
    );
  }

  ActaLocal sinInfraccion(int tipoId) => copyWith(
    infracciones: infracciones
        .where((i) => i.tipoInfraccionId != tipoId)
        .toList(),
  );

  /// Las fotos NO tienen tope ni son únicas: una por cada problema que encuentre el inspector.
  ActaLocal conEvidencia(String rutaLocal, String descripcion) => copyWith(
    evidencias: [
      ...evidencias,
      EvidenciaActa(rutaLocal: rutaLocal, descripcion: descripcion.trim()),
    ],
  );

  ActaLocal conDescripcionEvidencia(String rutaLocal, String descripcion) =>
      copyWith(
        evidencias: [
          for (final e in evidencias)
            e.rutaLocal == rutaLocal
                ? e.copyWith(descripcion: descripcion.trim())
                : e,
        ],
      );

  ActaLocal sinEvidencia(String rutaLocal) => copyWith(
    evidencias: evidencias.where((e) => e.rutaLocal != rutaLocal).toList(),
  );

  /// Una solicitud por nombre (sin distinguir mayúsculas): pedir lo mismo dos veces no tiene sentido.
  ActaLocal conSolicitudMaterial(SolicitudMaterialActa solicitud) {
    final nombre = solicitud.nombre.trim().toLowerCase();
    final repetida = solicitudesMaterial.any(
      (s) => s.nombre.trim().toLowerCase() == nombre,
    );
    return repetida
        ? this
        : copyWith(solicitudesMaterial: [...solicitudesMaterial, solicitud]);
  }

  ActaLocal sinSolicitudMaterial(String uuidLocal) => copyWith(
    solicitudesMaterial: solicitudesMaterial
        .where((s) => s.uuidLocal != uuidLocal)
        .toList(),
  );
}
