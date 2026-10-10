import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';
import '../inspeccion_controller.dart';
import 'infraccion_sheet.dart';

/// Paso 4: infracciones detectadas. La reincidencia la determina el servidor al enviar.
class PasoInfracciones extends StatelessWidget {
  const PasoInfracciones({super.key, required this.controller});

  final InspeccionController controller;

  @override
  Widget build(BuildContext context) {
    final infracciones = controller.acta!.infracciones;
    final quedanPorAgregar =
        controller.catalogos!.infracciones.length > infracciones.length;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Infracciones', style: textos.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Registra lo que incumple la norma. El sistema avisará si es reincidencia '
          'cuando se envíe el acta.',
          style: TextStyle(color: AppColors.grisTecnico),
        ),
        const SizedBox(height: 16),
        if (infracciones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin infracciones registradas. Si todo está en regla, continúa.',
              style: TextStyle(color: AppColors.grisTecnico),
            ),
          ),
        for (final i in infracciones)
          _FilaInfraccion(controller: controller, infraccion: i),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: quedanPorAgregar
              ? () => mostrarInfraccionSheet(context, controller)
              : null,
          icon: const Icon(Icons.add),
          label: Text(
            quedanPorAgregar
                ? 'Registrar infracción'
                : 'Ya registraste todas las infracciones',
          ),
        ),
      ],
    );
  }
}

class _FilaInfraccion extends StatelessWidget {
  const _FilaInfraccion({required this.controller, required this.infraccion});

  final InspeccionController controller;
  final InfraccionActa infraccion;

  @override
  Widget build(BuildContext context) {
    final nombre =
        controller.catalogos!.infraccion(infraccion.tipoInfraccionId)?.nombre ??
        'Infracción #${infraccion.tipoInfraccionId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () =>
            mostrarInfraccionSheet(context, controller, editar: infraccion),
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.riesgoMedio,
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: infraccion.descripcion.isEmpty
            ? null
            : Text(infraccion.descripcion),
        trailing: IconButton(
          tooltip: 'Quitar $nombre',
          icon: const Icon(Icons.delete_outline),
          onPressed: () =>
              controller.quitarInfraccion(infraccion.tipoInfraccionId),
        ),
      ),
    );
  }
}
