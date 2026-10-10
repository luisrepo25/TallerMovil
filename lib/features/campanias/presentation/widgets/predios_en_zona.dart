import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../catastro/domain/predio.dart';
import '../../../inspeccion/domain/acta_local.dart';
import 'predio_tile.dart';

/// Predios de la zona de la campaña, con sus estados vacío y de carga.
/// Va dentro de un `ListView`, así que devuelve una sola pieza sin scroll propio.
class PrediosEnZona extends StatelessWidget {
  const PrediosEnZona({
    super.key,
    required this.tieneZona,
    required this.cargando,
    required this.predios,
    required this.seleccionadoId,
    required this.onSeleccionar,
    required this.estados,
    required this.puedeInspeccionar,
    required this.onInspeccionar,
    this.onEditar,
  });

  final bool tieneZona;
  final bool cargando;
  final List<Predio> predios;
  final int? seleccionadoId;
  final ValueChanged<Predio> onSeleccionar;

  /// Estado de la inspección más reciente de cada predio (`predioId -> estado`).
  final Map<int, EstadoActa> estados;

  /// `false` en campañas cerradas.
  final bool puedeInspeccionar;
  final ValueChanged<Predio> onInspeccionar;

  /// Corregir un acta cerrada que aún no se envió.
  final ValueChanged<Predio>? onEditar;

  @override
  Widget build(BuildContext context) {
    if (!tieneZona) {
      return const SizedBox(
        height: 280,
        child: EmptyState(
          icon: Icons.location_off_outlined,
          title: 'Esta campaña aún no tiene zona',
          description:
              'El Administrador debe definir el área de trabajo en la plataforma web.',
        ),
      );
    }
    if (cargando) {
      return const SizedBox(height: 200, child: LoadingState());
    }
    if (predios.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.business_outlined,
          title: 'No hay predios en esta zona',
          description:
              'No se encontraron predios descargados dentro del área de la campaña.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${predios.length} ${predios.length == 1 ? 'predio' : 'predios'} en la zona',
            style: const TextStyle(
              color: AppColors.grisTecnico,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final predio in predios)
          PredioTile(
            predio: predio,
            estado: estados[predio.id],
            puedeInspeccionar: puedeInspeccionar,
            onInspeccionar: () => onInspeccionar(predio),
            onEditar: onEditar == null ? null : () => onEditar!(predio),
            seleccionado: predio.id == seleccionadoId,
            onTap: () => onSeleccionar(predio),
          ),
      ],
    );
  }
}
