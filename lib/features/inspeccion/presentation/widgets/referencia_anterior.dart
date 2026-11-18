import 'package:flutter/material.dart';

import '../../../../core/format/fechas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';
import '../../domain/catalogos.dart';

/// Lo que se registró en la inspección anterior del predio, solo como referencia. Nada de
/// esto cuenta en el acta nueva hasta que el inspector lo confirme con "Copiar" o responda
/// él mismo; las infracciones y las fotos nunca se copian.
class ReferenciaAnterior extends StatelessWidget {
  const ReferenciaAnterior({
    super.key,
    required this.anterior,
    required this.catalogos,
    required this.onCopiar,
  });

  final ActaLocal anterior;
  final Catalogos catalogos;
  final VoidCallback onCopiar;

  static String _si(bool? v) => v == null ? '—' : (v ? 'sí' : 'no');

  @override
  Widget build(BuildContext context) {
    final extintores = catalogos
        .estadoExtintor(anterior.estadoExtintoresId)
        ?.nombre;
    final materiales = [
      for (final m in anterior.materiales)
        '${catalogos.material(m.materialId)?.nombre ?? 'Material #${m.materialId}'} '
            '(${m.pesoKg.toStringAsFixed(m.pesoKg % 1 == 0 ? 0 : 2)} kg)',
    ];
    final infracciones = [
      for (final i in anterior.infracciones)
        catalogos.infraccion(i.tipoInfraccionId)?.nombre ??
            'Infracción #${i.tipoInfraccionId}',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inspección anterior · ${Fechas.corta(anterior.fechaInspeccion.toLocal())}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _Linea('Extintores', extintores ?? 'sin indicar'),
            _Linea('Fallas eléctricas', _si(anterior.fallasElectricas)),
            _Linea('Rutas despejadas', _si(anterior.rutasDespejadas)),
            _Linea(
              'Materiales',
              materiales.isEmpty ? 'ninguno' : materiales.join(', '),
            ),
            _Linea(
              'Infracciones',
              infracciones.isEmpty ? 'ninguna' : infracciones.join(', '),
            ),
            const SizedBox(height: 8),
            const Text(
              'Responde de nuevo lo que viste hoy. Si no cambió nada de seguridad ni '
              'de materiales, cópialo con un toque; las infracciones se registran '
              'solo si las vuelves a encontrar.',
              style: TextStyle(color: AppColors.grisTecnico, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopiar,
                icon: const Icon(Icons.copy_all),
                label: const Text('Copiar seguridad y materiales'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea(this.titulo, this.valor);

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}
