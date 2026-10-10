import 'package:flutter/material.dart';

import '../../../../core/format/fechas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/campania.dart';
import 'estado_chip.dart';

/// Tarjeta de una campaña en la lista. Toda la tarjeta es el botón (objetivo táctil grande).
class CampaniaCard extends StatelessWidget {
  const CampaniaCard({
    super.key,
    required this.campania,
    required this.prediosEnZona,
    required this.onTap,
  });

  final Campania campania;
  final int prediosEnZona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(campania.nombre, style: textos.titleMedium),
                  ),
                  const SizedBox(width: 8),
                  EstadoChip(estado: campania.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                Fechas.rango(campania.fechaInicio, campania.fechaFin),
                style: textos.bodyMedium?.copyWith(
                  color: AppColors.grisTecnico,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    campania.tieneZona
                        ? Icons.location_city_outlined
                        : Icons.location_off_outlined,
                    size: 18,
                    color: AppColors.grisTecnico,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      campania.tieneZona
                          ? '$prediosEnZona ${prediosEnZona == 1 ? 'predio' : 'predios'} en la zona'
                          : 'Zona aún sin definir',
                      style: textos.bodyMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.grisTecnico),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
