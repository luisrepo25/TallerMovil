import 'package:flutter/material.dart';

import '../../../../core/format/fechas.dart';
import '../../../../core/theme/app_colors.dart';

/// Franja con el estado de los datos del teléfono: cuándo se descargaron por última vez
/// y si hay problema (por ejemplo, sin conexión). Nunca bloquea el uso de la app.
class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.ultimaDescarga,
    required this.descargando,
    required this.sinConexion,
    required this.aviso,
    required this.onActualizar,
  });

  final DateTime? ultimaDescarga;
  final bool descargando;
  final bool sinConexion;
  final String? aviso;
  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) {
    final conProblema = aviso != null;
    final color = conProblema ? AppColors.riesgoMedio : AppColors.grisTecnico;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            sinConexion ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _texto(),
              style: const TextStyle(fontSize: 13, color: AppColors.azulMarino),
            ),
          ),
          descargando
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : IconButton(
                  onPressed: onActualizar,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
        ],
      ),
    );
  }

  String _texto() {
    if (descargando) return 'Actualizando datos...';
    if (aviso != null) return aviso!;
    if (ultimaDescarga == null) return 'Aún no se han descargado datos.';
    return 'Datos descargados ${Fechas.haceCuanto(ultimaDescarga!)}';
  }
}
