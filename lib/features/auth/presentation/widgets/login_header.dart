import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Marca de la app sobre el formulario de login.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

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
            border: Border.all(
              color: AppColors.azulMarino.withValues(alpha: 0.15),
            ),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 34,
          ),
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
          style: TextStyle(
            color: AppColors.grisTecnico.withValues(alpha: 0.9),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
