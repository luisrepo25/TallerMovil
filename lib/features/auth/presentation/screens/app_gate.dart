import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/loading_state.dart';
import '../../../home/presentation/screens/inspector_home_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../sesion_controller.dart';

/// Pantalla inicial: restaura la sesión guardada (funciona sin conexión) y decide
/// entre el inicio del inspector o el onboarding/login.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    // Después del primer frame: restaurar notifica a los listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionController>().restaurar();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (context.watch<SesionController>().estado) {
      case EstadoSesion.cargando:
        return const Scaffold(body: LoadingState(message: 'Abriendo...'));
      case EstadoSesion.autenticado:
        return const InspectorHomeScreen();
      case EstadoSesion.sinSesion:
        return const OnboardingScreen();
    }
  }
}
