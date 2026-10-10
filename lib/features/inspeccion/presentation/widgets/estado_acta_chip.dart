import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';

/// Estado de la inspección de un predio. Texto + ícono + color (nunca solo color).
/// `estado == null`: todavía no se inspeccionó.
class EstadoActaChip extends StatelessWidget {
  const EstadoActaChip({super.key, required this.estado});

  final EstadoActa? estado;

  ({String texto, IconData icono, Color color}) get _aspecto =>
      switch (estado) {
        null => (
          texto: 'Sin inspeccionar',
          icono: Icons.radio_button_unchecked,
          color: AppColors.grisTecnico,
        ),
        EstadoActa.borrador => (
          texto: 'Borrador',
          icono: Icons.edit_note,
          color: AppColors.riesgoMedio,
        ),
        EstadoActa.cerradaLocal => (
          texto: 'Lista para enviar',
          icono: Icons.schedule_send,
          color: const Color(0xFF1F6FEB),
        ),
        EstadoActa.sincronizada => (
          texto: 'Enviada',
          icono: Icons.cloud_done,
          color: AppColors.riesgoBajo,
        ),
        EstadoActa.rechazada => (
          texto: 'Rechazada',
          icono: Icons.error_outline,
          color: AppColors.riesgoCritico,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final a = _aspecto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: a.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.icono, size: 14, color: a.color),
          const SizedBox(width: 4),
          Text(
            a.texto,
            style: TextStyle(
              color: a.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
