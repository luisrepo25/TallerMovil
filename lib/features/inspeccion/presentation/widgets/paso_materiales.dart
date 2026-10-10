import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';
import '../inspeccion_controller.dart';
import 'material_sheet.dart';
import 'solicitud_material_sheet.dart';

/// Paso 3: materiales combustibles y su peso. La carga de fuego NO se ingresa: la
/// calcula el servidor al enviar el acta.
class PasoMateriales extends StatelessWidget {
  const PasoMateriales({super.key, required this.controller});

  final InspeccionController controller;

  @override
  Widget build(BuildContext context) {
    final materiales = controller.acta!.materiales;
    final catalogo = controller.catalogos!;
    final quedanPorAgregar = catalogo.materiales.length > materiales.length;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Materiales combustibles', style: textos.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Anota cuántos kg hay de cada material. No calcules la carga de fuego: '
          'el sistema la calcula al enviar el acta.',
          style: TextStyle(color: AppColors.grisTecnico),
        ),
        const SizedBox(height: 16),
        if (materiales.isEmpty)
          const _Vacio(
            'Aún no agregaste materiales. Si el predio no almacena material combustible, puedes continuar.',
          ),
        for (final m in materiales)
          _FilaMaterial(controller: controller, material: m),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: quedanPorAgregar
              ? () => mostrarMaterialSheet(context, controller)
              : null,
          icon: const Icon(Icons.add),
          label: Text(
            quedanPorAgregar
                ? 'Agregar material'
                : 'Ya agregaste todos los materiales',
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => mostrarSolicitudMaterialSheet(context, controller),
          icon: const Icon(Icons.help_outline),
          label: const Text('¿No está tu material? Solicitar al administrador'),
        ),
        for (final s in controller.acta!.solicitudesMaterial)
          _FilaSolicitud(controller: controller, solicitud: s),
      ],
    );
  }
}

/// Material pedido al administrador: aún no está en el catálogo, no suma a la carga de fuego.
class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud({required this.controller, required this.solicitud});

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

class _FilaMaterial extends StatelessWidget {
  const _FilaMaterial({required this.controller, required this.material});

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

class _Vacio extends StatelessWidget {
  const _Vacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(texto, style: const TextStyle(color: AppColors.grisTecnico)),
    );
  }
}
