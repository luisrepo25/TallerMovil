import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/transitions/page_transitions.dart';
import '../../../../core/widgets/al_reanudar.dart';
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
    // Cerrar sesión borra los datos del teléfono: si hay actas sin enviar, se pregunta antes
    final pendientes = await context.read<ActasRepository>().contarPendientes();
    if (!context.mounted) return;
    if (pendientes > 0) {
      final confirmo = await confirmarCierreConPendientes(context, pendientes);
      if (!confirmo) return;
    }
    await sesion.cerrarSesion();
    // pushAndRemoveUntil limpia toda la pila: no debe quedar nada a donde volver.
    navegador.pushAndRemoveUntil(
      LogoutToLoginRoute(child: const LoginScreen()),
      (route) => false,
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
        builder: (context) => AlReanudar(
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
    );
  }
}
