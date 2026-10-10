import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pie del onboarding: botón principal (cambia de texto y color en la última tarjeta)
/// y acceso a la ayuda.
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.esUltimaPagina,
    required this.onContinuar,
  });

  final bool esUltimaPagina;
  final VoidCallback onContinuar;

  void _mostrarAyuda(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modo Consulta'),
        content: const Text(
          'Contacta a tu Oficial de Mando o Administrador si necesitas ayuda '
          'para acceder al sistema con tus credenciales de Inspector Técnico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: FilledButton(
              key: ValueKey(esUltimaPagina),
              style: esUltimaPagina
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.rojoSeguridad,
                    )
                  : null,
              onPressed: onContinuar,
              child: Text(esUltimaPagina ? 'Ingresar al Sistema' : 'Continuar'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _mostrarAyuda(context),
            child: const Text(
              'Modo Consulta / Ayuda',
              style: TextStyle(color: AppColors.grisTecnico),
            ),
          ),
        ],
      ),
    );
  }
}
