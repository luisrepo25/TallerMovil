import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/onboarding_data.dart';

/// Tarjeta flotante individual del carrusel: ilustracion arriba (55-60% de
/// la altura), titulo y descripcion abajo. Solo presentacion, recibe todo
/// por parametro via [item].
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.rojoSeguridad.withValues(alpha: 0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 58,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo de color detras de la ilustracion: le da vida al
                    // fondo blanco de las imagenes sin salirse de la paleta.
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            item.colorAcento.withValues(alpha: 0.20),
                            item.colorAcento.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                    Image.asset(
                      item.imagenAsset,
                      fit: BoxFit.contain,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: AppColors.grisTecnico.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 6),
            Flexible(
              flex: 36,
              // Si el texto no cabe en pantallas chicas, se desplaza en vez de desbordar
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.colorAcento.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        item.icono,
                        size: 20,
                        color: item.colorAcento,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.titulo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.descripcion,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
