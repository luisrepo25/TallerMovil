import 'package:uuid/uuid.dart';

import '../domain/acta_edicion.dart';
import '../domain/acta_envio.dart';
import '../domain/acta_local.dart';

/// Cambios que el inspector le hace al acta abierta (seguridad, materiales, infracciones).
/// Cada uno se aplica y se guarda al instante a través de [modificar], que implementa el
/// controlador; así este archivo no sabe nada de pantallas ni de SQLite.
mixin CambiosDelActa {
  /// Aplica un cambio al acta abierta, la muestra y la guarda en el teléfono.
  Future<void> modificar(ActaLocal Function(ActaLocal) cambio);

  Uuid get uuid;

  /// La inspección anterior del predio (solo en una reinspección).
  ActaLocal? get anterior;

  Future<void> elegirExtintores(int estadoId) =>
      modificar((a) => a.copyWith(estadoExtintoresId: estadoId));

  Future<void> marcarFallasElectricas(bool valor) =>
      modificar((a) => a.copyWith(fallasElectricas: valor));

  Future<void> marcarRutasDespejadas(bool valor) =>
      modificar((a) => a.copyWith(rutasDespejadas: valor));

  /// Un toque para el caso normal: sin fallas eléctricas y rutas despejadas.
  Future<void> seguridadSinProblemas() =>
      modificar((a) => a.conSeguridadSinProblemas());

  Future<void> marcarSinMateriales(bool valor) =>
      modificar((a) => a.conSinMateriales(valor));

  /// Reinspección: copia seguridad y materiales de la anterior (acción explícita).
  Future<void> copiarDeAnterior() async {
    final previa = anterior;
    if (previa == null) return;
    await modificar((a) => a.conSeguridadYMaterialesDe(previa));
  }

  Future<void> guardarMaterial(int materialId, double pesoKg) =>
      modificar((a) => a.conMaterial(materialId, pesoKg));

  Future<void> quitarMaterial(int materialId) =>
      modificar((a) => a.sinMaterial(materialId));

  Future<void> guardarInfraccion(int tipoId, String descripcion) =>
      modificar((a) => a.conInfraccion(tipoId, descripcion));

  Future<void> quitarInfraccion(int tipoId) =>
      modificar((a) => a.sinInfraccion(tipoId));

  /// Pide al administrador un material que no está en el catálogo. No cuenta en la carga
  /// de fuego hasta que lo apruebe; el inspector sigue con su inspección.
  Future<void> solicitarMaterial({
    required String nombre,
    String descripcion = '',
    double? pesoKgEstimado,
  }) => modificar(
    (a) => a.conSolicitudMaterial(
      SolicitudMaterialActa(
        uuidLocal: uuid.v4(),
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        pesoKgEstimado: pesoKgEstimado,
      ),
    ),
  );

  Future<void> quitarSolicitudMaterial(String uuidLocal) =>
      modificar((a) => a.sinSolicitudMaterial(uuidLocal));
}
