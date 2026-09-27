import 'package:flutter/material.dart';

/// Transicion generica de la app: fade + deslizamiento vertical sutil,
/// mas fluida que el push por defecto de Material. Uso general entre
/// pantallas (ej. login -> home tras autenticar).
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required this.child, this.offset = const Offset(0, 0.04)})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, widget) {
            final curva = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
            return FadeTransition(
              opacity: curva,
              child: SlideTransition(
                position: Tween<Offset>(begin: offset, end: Offset.zero).animate(curva),
                child: widget,
              ),
            );
          },
        );

  final Widget child;
  final Offset offset;
}

/// Transicion de salida del Onboarding hacia el Login: desvanecimiento +
/// deslizamiento vertical mas pronunciado (de abajo hacia arriba), con la
/// curva `fastOutSlowIn` pedida para esta transicion especifica.
class OnboardingToLoginRoute<T> extends PageRouteBuilder<T> {
  OnboardingToLoginRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, widget) {
            final curva = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
            return FadeTransition(
              opacity: curva,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(curva),
                child: widget,
              ),
            );
          },
        );

  final Widget child;
}
