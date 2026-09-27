import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/page_transitions.dart';
import '../features/auth/login_controller.dart';
import '../features/auth/login_form.dart';
import '../theme/app_theme.dart';
import 'inspector_home_screen.dart';

/// Pantalla de login del cliente movil (uso exclusivo del Inspector Tecnico
/// en campo, ver CLAUDE.md - Alcance). Estructura y fondo viven aqui; los
/// inputs y la logica de negocio estan en features/auth.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        body: Stack(
          children: [
            const _FondoSutil(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _Encabezado(),
                          const SizedBox(height: 28),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Builder(
                                builder: (context) => LoginForm(
                                  onLoginSuccess: () {
                                    Navigator.of(context).pushReplacement(
                                      FadeSlidePageRoute(child: const InspectorHomeScreen()),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Bomberos Voluntarios UUBR',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.grisTecnico),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo neutro con un par de formas circulares muy suaves (opacidad baja),
/// a modo de marca de agua discreta. Nada de gradientes saturados.
class _FondoSutil extends StatelessWidget {
  const _FondoSutil();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grisClaro,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _Blob(diametro: 220, color: AppColors.azulMarino.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: _Blob(diametro: 260, color: AppColors.rojoSeguridad.withValues(alpha: 0.04)),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diametro, required this.color});

  final double diametro;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.azulMarino,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.azulMarino.withValues(alpha: 0.15), width: 1),
          ),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'UUBR',
          style: TextStyle(
            color: AppColors.azulMarino,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Riesgo de Incendios',
          style: TextStyle(color: AppColors.grisTecnico.withValues(alpha: 0.9), fontSize: 15),
        ),
      ],
    );
  }
}
