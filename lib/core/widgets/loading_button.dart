import 'package:flutter/material.dart';

/// Botón de ancho completo cuyo contenido cambia entre texto y un indicador de carga
/// sin saltos de layout (altura fija; solo se anima el contenido interno).
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: loading
            ? const SizedBox(
                key: ValueKey('cargando'),
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label, key: const ValueKey('texto')),
      ),
    );
  }
}
