import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Modelo simple de una tarjeta del carrusel de onboarding.
class OnboardingItem {
  const OnboardingItem({
    required this.imagenAsset,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.colorAcento,
  });

  final String imagenAsset;
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color colorAcento;
}

/// Lista estatica de las 3 tarjetas, en el orden en que se muestran.
const List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    imagenAsset: 'assets/images/onboarding/onboarding_inspection.png',
    icono: Icons.fact_check_outlined,
    titulo: 'Inspeccion Inteligente en Campo',
    descripcion:
        'Registra actas digitales y georreferencia predios con o sin '
        'conexion a internet (Offline-First).',
    colorAcento: AppColors.azulMarino,
  ),
  OnboardingItem(
    imagenAsset: 'assets/images/onboarding/onboarding_hydrants.png',
    icono: Icons.water_drop_outlined,
    titulo: 'Red de Hidrantes y Cobertura Hidrica',
    descripcion:
        'Localiza hidrantes operativos en tiempo real e identifica rutas '
        'de respuesta inmediata.',
    colorAcento: AppColors.azulMarinoSuave,
  ),
  OnboardingItem(
    imagenAsset: 'assets/images/onboarding/onboarding_risk_map.png',
    icono: Icons.local_fire_department_outlined,
    titulo: 'Zonificacion de Riesgo con IA',
    descripcion:
        'Visualiza mapas de calor y niveles de peligro (Bajo, Medio, '
        'Critico) respaldados por K-Means.',
    colorAcento: AppColors.rojoSeguridad,
  ),
];
