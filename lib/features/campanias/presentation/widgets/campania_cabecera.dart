import 'package:flutter/material.dart';

import '../../../../core/format/fechas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/campania.dart';
import 'estado_chip.dart';

/// Franja superior del detalle: estado y fechas de la campaña.
class CampaniaCabecera extends StatelessWidget {
  const CampaniaCabecera({super.key, required this.campania});

  final Campania campania;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EstadoChip(estado: campania.estado),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Fechas.rango(campania.fechaInicio, campania.fechaFin),
                  style: const TextStyle(color: AppColors.grisTecnico),
                ),
              ),
            ],
          ),
          if (campania.estaCerrada) ...[
            const SizedBox(height: 12),
            const Text(
              'Campaña cerrada: ya no admite nuevas inspecciones.',
              style: TextStyle(color: AppColors.grisTecnico),
            ),
          ],
        ],
      ),
    );
  }
}
