import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../campanias/domain/campania.dart';
import '../../../catastro/domain/predio.dart';
import '../../data/actas_repository.dart';
import '../../data/catalogos_repository.dart';
import '../../data/evidencias_archivos.dart';
import '../inspeccion_controller.dart';
import '../widgets/inspeccion_barra.dart';
import '../widgets/paso_evidencia.dart';
import '../widgets/paso_infracciones.dart';
import '../widgets/paso_materiales.dart';
import '../widgets/paso_predio.dart';
import '../widgets/paso_resumen.dart';
import '../widgets/paso_seguridad.dart';
import '../widgets/pasos_indicador.dart';

/// Asistente de inspección de un predio. Se guarda solo en cada cambio y funciona sin
/// conexión. Devuelve `true` al navegar atrás si el acta quedó cerrada.
class InspeccionScreen extends StatelessWidget {
  const InspeccionScreen({
    super.key,
    required this.campania,
    required this.predio,
  });

  final Campania campania;
  final Predio predio;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InspeccionController(
        actas: context.read<ActasRepository>(),
        catalogos: context.read<CatalogosRepository>(),
        archivos: context.read<EvidenciasArchivos>(),
        campania: campania,
        predioId: predio.id,
      )..iniciar(),
      child: _Contenido(campania: campania, predio: predio),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.campania, required this.predio});

  final Campania campania;
  final Predio predio;

  Future<void> _cerrar(BuildContext context, InspeccionController c) async {
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    if (await c.cerrar()) {
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('Acta guardada. Se enviará cuando haya conexión.'),
        ),
      );
      navegador.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspeccionController>();

    return Scaffold(
      appBar: AppBar(title: Text(predio.nombre)),
      body: _cuerpo(context, c),
      bottomNavigationBar: c.acta == null || c.cargando
          ? null
          : InspeccionBarra(controller: c, onCerrar: () => _cerrar(context, c)),
    );
  }

  Widget _cuerpo(BuildContext context, InspeccionController c) {
    if (c.cargando) {
      return const LoadingState(message: 'Abriendo inspección...');
    }
    if (c.acta == null) {
      return ErrorState(message: c.error ?? 'No se pudo abrir la inspección.');
    }

    return Column(
      children: [
        PasosIndicador(paso: c.paso),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (c.paso) {
              PasoInspeccion.predio => PasoPredio(
                predio: predio,
                campania: campania,
                precargadaDe: c.acta!.precargadaDe,
              ),
              PasoInspeccion.seguridad => PasoSeguridad(controller: c),
              PasoInspeccion.materiales => PasoMateriales(controller: c),
              PasoInspeccion.infracciones => PasoInfracciones(controller: c),
              PasoInspeccion.evidencia => PasoEvidencia(controller: c),
              PasoInspeccion.resumen => PasoResumen(
                controller: c,
                predio: predio,
              ),
            },
          ),
        ),
      ],
    );
  }
}
