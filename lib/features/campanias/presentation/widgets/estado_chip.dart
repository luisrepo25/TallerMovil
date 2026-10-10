import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Estado de la campaña. Siempre texto + color (nunca solo color).
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final String estado;

  static const _etiquetas = {
    'pendiente': 'Pendiente',
    'en_curso': 'En curso',
    'cerrada': 'Cerrada',
  };

  Color get _color {
    switch (estado) {
      case 'en_curso':
        return const Color(0xFF1F6FEB);
      case 'cerrada':
        return AppColors.grisTecnico;
      default:
        return AppColors.riesgoMedio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _etiquetas[estado] ?? estado,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
