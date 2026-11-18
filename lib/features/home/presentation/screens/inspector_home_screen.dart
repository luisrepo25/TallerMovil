import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/notifications/notificaciones_controller.dart';
import '../../../../core/notifications/notificaciones_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/transitions/page_transitions.dart';
import '../../../../core/widgets/al_reanudar.dart';
import '../../../../core/widgets/envio_automatico.dart';
import '../../../../core/widgets/notificaciones_activas.dart';
import '../../../../sync/conexion.dart';
import '../../../../sync/descarga_service.dart';
import '../../../../sync/envio_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/sesion_controller.dart';
import '../../../campanias/data/campanias_repository.dart';
import '../../../campanias/presentation/campanias_controller.dart';
import '../../../campanias/presentation/screens/mis_campanias_view.dart';
import '../../../catastro/data/predios_repository.dart';
import '../../../inspeccion/data/actas_repository.dart';
import '../widgets/confirmar_cierre_sesion.dart';

/// Inicio del Inspector: sus campañas asignadas, disponibles sin conexión. Al abrirse y al
/// volver a la app envía las actas pendientes.
class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final navegador = Navigator.of(context);
    final sesion = context.read<SesionController>();
    final notificaciones = context.read<NotificacionesController>();
    // Cerrar sesión borra los datos del teléfono: si hay actas sin enviar, se pregunta antes
    final pendientes = await context.read<ActasRepository>().contarPendientes();
    if (!context.mounted) return;
    if (pendientes > 0) {
      final confirmo = await confirmarCierreConPendientes(context, pendientes);
      if (!confirmo) return;
    }
    // El aviso al servidor necesita la sesión: se hace antes de borrarla y sin demorar
    // el cierre si no hay red.
    await notificaciones.cerrarSesion().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    await sesion.cerrarSesion();
    // pushAndRemoveUntil limpia toda la pila: no debe quedar nada a donde volver.
    navegador.pushAndRemoveUntil(
      LogoutToLoginRoute(child: const LoginScreen()),
      (route) => false,
    );
  }

  /// Una campaña nueva asignada llegó con la app abierta: se descarga y se avisa.
  void _alRecibirAviso(BuildContext context, AvisoPush aviso) {
    if (!aviso.esCampaniaAsignada || !context.mounted) return;
    context.read<CampaniasController>().sincronizar();
    final nombre = aviso.cuerpo;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nombre == null
              ? 'Nueva campaña asignada'
              : 'Nueva campaña asignada: $nombre',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionController>().usuario;

    return ChangeNotifierProvider(
      create: (context) => CampaniasController(
        campanias: context.read<CampaniasRepository>(),
        predios: context.read<PrediosRepository>(),
        descarga: context.read<DescargaService>(),
        envio: context.read<EnvioService>(),
      )..iniciar(),
      // Builder: necesita un contexto dentro del provider para leer el controlador
      child: Builder(
        builder: (context) => NotificacionesActivas(
          alRecibir: (aviso) => _alRecibirAviso(context, aviso),
          child: EnvioAutomatico(
            conexion: cambiosDeConexion(),
            enviar: context.read<CampaniasController>().enviar,
            hayPendientes: () =>
                context.read<CampaniasController>().pendientesEnvio > 0,
            child: AlReanudar(
              onReanudar: context.read<CampaniasController>().enviar,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Mis campañas'),
                  actions: [
                    IconButton(
                      onPressed: () => _cerrarSesion(context),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Cerrar sesión',
                    ),
                  ],
                  bottom: usuario == null
                      ? null
                      : PreferredSize(
                          preferredSize: const Size.fromHeight(28),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Hola, ${usuario.nombreCompleto}',
                              style: const TextStyle(
                                color: AppColors.grisClaro,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                ),
                body: const MisCampaniasView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
