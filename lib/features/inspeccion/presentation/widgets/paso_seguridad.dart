import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../inspeccion_controller.dart';

/// Paso 2: estado de los extintores, fallas eléctricas y rutas de evacuación.
class PasoSeguridad extends StatelessWidget {
  const PasoSeguridad({super.key, required this.controller});

  final InspeccionController controller;

  @override
  Widget build(BuildContext context) {
    final acta = controller.acta!;
    final estados = controller.catalogos!.estadosExtintor;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seguridad', style: textos.titleLarge),
        const SizedBox(height: 16),
        Text('Estado de los extintores', style: textos.titleSmall),
        const SizedBox(height: 8),
        if (estados.isEmpty)
          const Text(
            'No hay opciones descargadas. Conéctate y actualiza tus campañas.',
            style: TextStyle(color: AppColors.riesgoCritico),
          ),
        for (final estado in estados)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: estado.id == acta.estadoExtintoresId
                ? AppColors.azulMarino.withValues(alpha: 0.08)
                : null,
            child: ListTile(
              onTap: () => controller.elegirExtintores(estado.id),
              title: Text(estado.nombre),
              trailing: Icon(
                estado.id == acta.estadoExtintoresId
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: estado.id == acta.estadoExtintoresId
                    ? AppColors.azulMarino
                    : AppColors.grisTecnico,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _PreguntaSiNo(
          pregunta: '¿Hay fallas eléctricas?',
          valor: acta.fallasElectricas,
          onChanged: controller.marcarFallasElectricas,
        ),
        const SizedBox(height: 16),
        _PreguntaSiNo(
          pregunta: '¿Las rutas de evacuación están despejadas?',
          valor: acta.rutasDespejadas,
          onChanged: controller.marcarRutasDespejadas,
        ),
      ],
    );
  }
}

class _PreguntaSiNo extends StatelessWidget {
  const _PreguntaSiNo({
    required this.pregunta,
    required this.valor,
    required this.onChanged,
  });

  final String pregunta;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Sí')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {valor},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}
