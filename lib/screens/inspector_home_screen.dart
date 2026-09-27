import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder de bienvenida tras el login. Las pantallas reales del
/// Inspector (registrar actas, evidencia fotografica, historial) son de
/// Fase 4 del backend y aun no existen (ver PLANBACKEND.md).
class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UUBR'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.riesgoBajo, size: 56),
              const SizedBox(height: 16),
              Text('Sesion iniciada', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Las pantallas de inspeccion (actas, evidencia, historial) se '
                'habilitan cuando el backend implemente la Fase 4.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
