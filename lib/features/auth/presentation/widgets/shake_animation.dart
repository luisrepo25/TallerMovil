import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Envuelve [child] y lo desplaza horizontalmente en una curva senoidal amortiguada
/// cuando [controller] corre, simulando una sacudida ligera (credenciales rechazadas).
class ShakeAnimation extends StatelessWidget {
  const ShakeAnimation({
    super.key,
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  static const _vueltas = 4;
  static const _amplitud = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, hijo) {
        final progreso = controller.value;
        final desplazamiento = progreso == 0
            ? 0.0
            : _amplitud *
                  (1 - progreso) *
                  math.sin(progreso * _vueltas * 2 * math.pi);
        return Transform.translate(
          offset: Offset(desplazamiento, 0),
          child: hijo,
        );
      },
      child: child,
    );
  }
}
