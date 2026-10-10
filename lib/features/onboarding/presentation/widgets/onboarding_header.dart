import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Barra superior del onboarding: "atrás" (solo desde la 2.ª tarjeta) y "Saltar".
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.mostrarAtras,
    required this.onAtras,
    required this.onSaltar,
  });

  final bool mostrarAtras;
  final VoidCallback onAtras;
  final VoidCallback onSaltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: mostrarAtras
                ? IconButton(
                    key: const ValueKey('atras'),
                    onPressed: onAtras,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.grisTecnico,
                    ),
                    tooltip: 'Atrás',
                  )
                : const SizedBox(
                    width: 48,
                    height: 48,
                    key: ValueKey('sin-atras'),
                  ),
          ),
          TextButton(
            onPressed: onSaltar,
            child: const Text(
              'Saltar',
              style: TextStyle(color: AppColors.grisTecnico),
            ),
          ),
        ],
      ),
    );
  }
}
