import 'package:flutter/material.dart';

import '../../../../core/widgets/loading_button.dart';
import '../inspeccion_controller.dart';

/// Botones inferiores del asistente: Atrás y Siguiente (en el último paso, Cerrar acta).
/// Fijos abajo y grandes: se usan con una mano y de pie.
class InspeccionBarra extends StatelessWidget {
  const InspeccionBarra({
    super.key,
    required this.controller,
    required this.onCerrar,
  });

  final InspeccionController controller;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final acta = controller.acta!;

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (!controller.esPrimerPaso) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.atras,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: controller.esUltimoPaso
                    ? LoadingButton(
                        label: 'Cerrar acta',
                        loading: controller.cerrando,
                        // Sin lo obligatorio, el botón aparece apagado (el resumen explica qué falta)
                        onPressed: acta.puedeCerrar ? onCerrar : () {},
                      )
                    : FilledButton(
                        onPressed: controller.siguiente,
                        child: const Text('Siguiente'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
