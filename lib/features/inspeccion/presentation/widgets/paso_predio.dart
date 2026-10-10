import 'package:flutter/material.dart';

import '../../../../core/format/fechas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../campanias/domain/campania.dart';
import '../../../catastro/domain/predio.dart';

/// Paso 1: confirmar que se está inspeccionando el predio correcto.
class PasoPredio extends StatelessWidget {
  const PasoPredio({
    super.key,
    required this.predio,
    required this.campania,
    this.precargadaDe,
  });

  final Predio predio;
  final Campania campania;

  /// Fecha de la inspección anterior de la que partió esta (reinspección).
  final DateTime? precargadaDe;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirma el predio', style: textos.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Revisa que sea el lugar que vas a inspeccionar.',
          style: TextStyle(color: AppColors.grisTecnico),
        ),
        const SizedBox(height: 16),
        if (precargadaDe != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.riesgoMedio.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, color: AppColors.riesgoMedio),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reinspección: partes de los datos del ${Fechas.corta(precargadaDe!.toLocal())}. '
                    'Verifica cada dato y corrige lo que haya cambiado. Las fotos no se copian.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(predio.nombre, style: textos.titleMedium),
                const SizedBox(height: 12),
                _Dato(
                  Icons.place_outlined,
                  predio.direccion ?? 'Sin dirección registrada',
                ),
                if (predio.tipoNombre != null)
                  _Dato(Icons.category_outlined, predio.tipoNombre!),
                if (predio.areaM2 != null)
                  _Dato(
                    Icons.square_foot,
                    '${predio.areaM2!.toStringAsFixed(0)} m²',
                  ),
                if (predio.aforo != null)
                  _Dato(
                    Icons.groups_outlined,
                    'Aforo: ${predio.aforo} personas',
                  ),
                const Divider(height: 24),
                _Dato(Icons.assignment_outlined, 'Campaña: ${campania.nombre}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.grisTecnico),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
