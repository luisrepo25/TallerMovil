import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../campanias_controller.dart';
import '../widgets/campania_card.dart';
import '../widgets/envio_banner.dart';
import '../widgets/sync_banner.dart';
import 'campania_detalle_screen.dart';

/// Cuerpo de la pantalla de inicio: franja de sincronización + lista de campañas.
/// Deslizar hacia abajo vuelve a descargar.
class MisCampaniasView extends StatelessWidget {
  const MisCampaniasView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CampaniasController>();
    if (c.cargandoInicial) {
      return const LoadingState(message: 'Abriendo tus campañas...');
    }

    return RefreshIndicator(
      onRefresh: c.sincronizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SyncBanner(
            ultimaDescarga: c.ultimaDescarga,
            descargando: c.descargando,
            sinConexion: c.sinConexion,
            aviso: c.aviso,
            onActualizar: c.sincronizar,
          ),
          EnvioBanner(
            pendientes: c.pendientesEnvio,
            enviando: c.enviando,
            aviso: c.avisoEnvio,
            conProblema: c.envioConProblema,
            onEnviar: c.enviar,
          ),
          const SizedBox(height: 16),
          if (c.items.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.assignment_outlined,
                title: 'Aún no tienes campañas asignadas',
                description:
                    'Cuando un Administrador te asigne una campaña aparecerá aquí. '
                    'Desliza hacia abajo para actualizar.',
              ),
            )
          else
            for (final campania in c.items) ...[
              CampaniaCard(
                campania: campania,
                prediosEnZona: c.prediosPorCampania[campania.id] ?? 0,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CampaniaDetalleScreen(campania: campania),
                    ),
                  );
                  // Al volver puede haber actas nuevas por enviar (o ya enviadas)
                  await c.actualizarPendientes();
                },
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
