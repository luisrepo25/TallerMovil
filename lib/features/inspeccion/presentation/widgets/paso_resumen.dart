import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../catastro/domain/predio.dart';
import '../inspeccion_controller.dart';

/// Paso final: revisar todo antes de cerrar el acta. Cada sección tiene "Editar".
class PasoResumen extends StatelessWidget {
  const PasoResumen({
    super.key,
    required this.controller,
    required this.predio,
  });

  final InspeccionController controller;
  final Predio predio;

  @override
  Widget build(BuildContext context) {
    final acta = controller.acta!;
    final catalogos = controller.catalogos!;
    final extintores = catalogos
        .estadoExtintor(acta.estadoExtintoresId)
        ?.nombre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisa y cierra el acta',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final falta in acta.faltantesParaCerrar) ...[
          ErrorBanner(text: falta),
          const SizedBox(height: 8),
        ],
        _Seccion(
          titulo: 'Predio',
          lineas: [
            predio.nombre,
            if (predio.direccion != null) predio.direccion!,
          ],
          onEditar: () => controller.irAPaso(PasoInspeccion.predio),
        ),
        _Seccion(
          titulo: 'Seguridad',
          lineas: [
            'Extintores: ${extintores ?? 'sin indicar'}',
            'Fallas eléctricas: ${acta.fallasElectricas ? 'sí' : 'no'}',
            'Rutas de evacuación despejadas: ${acta.rutasDespejadas ? 'sí' : 'no'}',
          ],
          onEditar: () => controller.irAPaso(PasoInspeccion.seguridad),
        ),
        _Seccion(
          titulo: 'Materiales combustibles',
          lineas: [
            for (final m in acta.materiales)
              '${catalogos.material(m.materialId)?.nombre ?? 'Material #${m.materialId}'}: ${m.pesoKg} kg',
            if (acta.materiales.isEmpty) 'Ninguno registrado',
          ],
          onEditar: () => controller.irAPaso(PasoInspeccion.materiales),
        ),
        if (acta.solicitudesMaterial.isNotEmpty)
          _Seccion(
            titulo: 'Materiales solicitados al administrador',
            lineas: [for (final s in acta.solicitudesMaterial) s.nombre],
            onEditar: () => controller.irAPaso(PasoInspeccion.materiales),
          ),
        _Seccion(
          titulo: 'Infracciones',
          lineas: [
            for (final i in acta.infracciones)
              catalogos.infraccion(i.tipoInfraccionId)?.nombre ??
                  'Infracción #${i.tipoInfraccionId}',
            if (acta.infracciones.isEmpty) 'Ninguna registrada',
          ],
          onEditar: () => controller.irAPaso(PasoInspeccion.infracciones),
        ),
        _Seccion(
          titulo: 'Evidencia fotográfica',
          lineas: [
            acta.evidencias.isEmpty
                ? 'Sin fotos'
                : '${acta.evidencias.length} '
                      '${acta.evidencias.length == 1 ? 'foto' : 'fotos'}',
          ],
          onEditar: () => controller.irAPaso(PasoInspeccion.evidencia),
        ),
        const SizedBox(height: 8),
        const Text(
          'Al cerrar el acta ya no podrás editarla. Su nivel de riesgo se calculará '
          'cuando se envíe al sistema.',
          style: TextStyle(color: AppColors.grisTecnico),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.lineas,
    required this.onEditar,
  });

  final String titulo;
  final List<String> lineas;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(onPressed: onEditar, child: const Text('Editar')),
              ],
            ),
            for (final linea in lineas)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: Text(linea),
              ),
          ],
        ),
      ),
    );
  }
}
