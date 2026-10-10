import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Fondo neutro con dos formas circulares muy suaves (opacidad baja), a modo de
/// marca de agua discreta. Nada de gradientes saturados.
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grisClaro,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _Blob(
              diametro: 220,
              color: AppColors.azulMarino.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: _Blob(
              diametro: 260,
              color: AppColors.rojoSeguridad.withValues(alpha: 0.04),
            ),
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
