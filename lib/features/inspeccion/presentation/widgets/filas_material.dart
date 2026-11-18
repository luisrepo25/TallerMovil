import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';
import '../inspeccion_controller.dart';
import 'material_sheet.dart';

/// Material pedido al administrador: aún no está en el catálogo, no suma a la carga de fuego.
class FilaSolicitud extends StatelessWidget {
  const FilaSolicitud({
    super.key,
    required this.controller,
    required this.solicitud,
  });

  final InspeccionController controller;
  final SolicitudMaterialActa solicitud;

  @override
  Widget build(BuildContext context) {
    final peso = solicitud.pesoKgEstimado;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.hourglass_top, color: AppColors.riesgoMedio),
        title: Text(
          solicitud.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Solicitado al administrador'
          '${peso == null ? '' : ' · ~${peso.toStringAsFixed(peso % 1 == 0 ? 0 : 2)} kg'}',
        ),
        trailing: IconButton(
          tooltip: 'Quitar solicitud de ${solicitud.nombre}',
          icon: const Icon(Icons.delete_outline),
          onPressed: () =>
              controller.quitarSolicitudMaterial(solicitud.uuidLocal),
        ),
      ),
    );
  }
}

class FilaMaterial extends StatelessWidget {
  const FilaMaterial({
    super.key,
    required this.controller,
    required this.material,
  });

  final InspeccionController controller;
  final MaterialActa material;

  @override
  Widget build(BuildContext context) {
    final nombre =
        controller.catalogos!.material(material.materialId)?.nombre ??
        'Material #${material.materialId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () =>
            mostrarMaterialSheet(context, controller, editar: material),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${material.pesoKg.toStringAsFixed(material.pesoKg % 1 == 0 ? 0 : 2)} kg',
        ),
        trailing: IconButton(
          tooltip: 'Quitar $nombre',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => controller.quitarMaterial(material.materialId),
        ),
      ),
    );
  }
}
