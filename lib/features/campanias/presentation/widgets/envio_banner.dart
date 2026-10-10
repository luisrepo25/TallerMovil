import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Franja con las actas que esperan salir del teléfono y el resultado del último envío.
/// No aparece si no hay nada pendiente ni que contar. Nunca bloquea el uso de la app.
class EnvioBanner extends StatelessWidget {
  const EnvioBanner({
    super.key,
    required this.pendientes,
    required this.enviando,
    required this.aviso,
    required this.conProblema,
    required this.onEnviar,
  });

  final int pendientes;
  final bool enviando;
  final String? aviso;
  final bool conProblema;
  final VoidCallback onEnviar;

  bool get visible => enviando || pendientes > 0 || aviso != null;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final color = conProblema ? AppColors.riesgoMedio : AppColors.grisTecnico;
    final textos = <String>[
      if (enviando)
        'Enviando actas...'
      else if (pendientes > 0)
        '$pendientes ${pendientes == 1 ? 'acta lista' : 'actas listas'} para enviar',
      if (!enviando && aviso != null) aviso!,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.upload_outlined, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                textos.join('\n'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.azulMarino,
                ),
              ),
            ),
            if (enviando)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              )
            else if (pendientes > 0)
              TextButton(
                onPressed: onEnviar,
                child: const Text('Enviar ahora'),
              ),
          ],
        ),
      ),
    );
  }
}
