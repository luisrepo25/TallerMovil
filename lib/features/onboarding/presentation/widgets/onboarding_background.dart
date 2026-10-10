import 'package:flutter/material.dart';

import '../../domain/onboarding_data.dart';

/// Fondo con dos halos de color que se funden entre el acento de la página actual y
/// el de la siguiente mientras el usuario desliza, para que el fondo neutro no se
/// sienta plano ni desconectado de cada tarjeta.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        double pagina = 0;
        if (pageController.positions.isNotEmpty &&
            pageController.position.haveDimensions) {
          pagina = pageController.page ?? 0;
        }
        final actual = pagina.floor().clamp(0, onboardingItems.length - 1);
        final siguiente = (actual + 1).clamp(0, onboardingItems.length - 1);
        final color = Color.lerp(
          onboardingItems[actual].colorAcento,
          onboardingItems[siguiente].colorAcento,
          pagina - actual,
        )!;

        return Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _Halo(diametro: 260, color: color.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: _Halo(diametro: 300, color: color.withValues(alpha: 0.07)),
            ),
          ],
        );
      },
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.diametro, required this.color});

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
