import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../catastro/domain/predio.dart';
import '../../../inspeccion/domain/acta_local.dart';
import '../../../inspeccion/presentation/widgets/estado_acta_chip.dart';

/// Fila de un predio dentro de la zona de la campaña. Tocar la fila lo resalta en el mapa;
/// el botón abre (o retoma) su inspección.
class PredioTile extends StatelessWidget {
  const PredioTile({
    super.key,
    required this.predio,
    required this.estado,
    required this.puedeInspeccionar,
    required this.onInspeccionar,
    this.onEditar,
    this.seleccionado = false,
    this.onTap,
  });

  final Predio predio;

  /// Estado de la inspección más reciente; `null` si no se inspeccionó.
  final EstadoActa? estado;

  /// `false` en campañas cerradas.
  final bool puedeInspeccionar;
  final VoidCallback onInspeccionar;

  /// Solo se ofrece mientras el acta está cerrada pero sin enviar; una ya enviada es historia.
  final VoidCallback? onEditar;
  final bool seleccionado;
  final VoidCallback? onTap;

  String get _textoBoton => switch (estado) {
    EstadoActa.borrador => 'Continuar',
    null => 'Inspeccionar',
    _ => 'Reinspeccionar',
  };

  @override
  Widget build(BuildContext context) {
    final detalle = [
      if (predio.tipoNombre != null) predio.tipoNombre!,
      if (predio.areaM2 != null) '${predio.areaM2!.toStringAsFixed(0)} m²',
      if (predio.aforo != null) 'aforo ${predio.aforo}',
    ].join(' · ');

    return Material(
      color: seleccionado
          ? AppColors.rojoSeguridad.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: seleccionado
                        ? AppColors.rojoSeguridad
                        : AppColors.grisClaro,
                    child: Icon(
                      Icons.business_outlined,
                      color: seleccionado ? Colors.white : AppColors.azulMarino,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          predio.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (predio.direccion != null) Text(predio.direccion!),
                        if (detalle.isNotEmpty)
                          Text(
                            detalle,
                            style: const TextStyle(
                              color: AppColors.grisTecnico,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Wrap (no Row): en pantallas angostas o con letra grande el botón baja a una
              // segunda línea en vez de cortarse
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  EstadoActaChip(estado: estado),
                  if (puedeInspeccionar)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (estado == EstadoActa.cerradaLocal &&
                            onEditar != null)
                          TextButton(
                            onPressed: onEditar,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            child: const Text('Editar acta'),
                          ),
                        FilledButton.tonal(
                          onPressed: onInspeccionar,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(_textoBoton),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
