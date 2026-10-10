import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../inspeccion_controller.dart';

/// "Paso 2 de 5 · Seguridad" con una barra de avance.
class PasosIndicador extends StatelessWidget {
  const PasosIndicador({super.key, required this.paso});

  final PasoInspeccion paso;

  @override
  Widget build(BuildContext context) {
    final total = PasoInspeccion.values.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso ${paso.index + 1} de $total · ${paso.titulo}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.azulMarino,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (paso.index + 1) / total,
              minHeight: 6,
              backgroundColor: AppColors.grisClaro,
            ),
          ),
        ],
      ),
    );
  }
}
