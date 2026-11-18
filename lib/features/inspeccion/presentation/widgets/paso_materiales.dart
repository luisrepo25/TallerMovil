import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../inspeccion_controller.dart';
import 'filas_material.dart';
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
        if (materiales.isEmpty && controller.acta!.solicitudesMaterial.isEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: controller.acta!.sinMateriales,
            onChanged: (v) => controller.marcarSinMateriales(v ?? false),
            title: const Text('Este predio no tiene materiales combustibles'),
            subtitle: const Text(
              'Confírmalo para poder cerrar el acta sin materiales.',
            ),
          ),
        for (final m in materiales)
          FilaMaterial(controller: controller, material: m),
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
          FilaSolicitud(controller: controller, solicitud: s),
      ],
    );
  }
}
