import 'package:flutter/material.dart';

import '../../../../core/geo/geo.dart';
import '../../../../core/location/ubicacion_controller.dart';
import '../../../../core/location/ubicacion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/campania.dart';

/// Aviso sobre el mapa: dónde está el inspector respecto a la zona de la campaña, o qué
/// hacer si la ubicación no está disponible. Texto + ícono + color (nunca solo color).
class UbicacionChip extends StatelessWidget {
  const UbicacionChip({
    super.key,
    required this.campania,
    required this.ubicacion,
  });

  final Campania campania;
  final UbicacionController ubicacion;

  /// Para pruebas y para el botón: ¿la posición está dentro de la zona?
  static bool estaEnZona(Campania campania, Ubicacion u) =>
      campania.tieneZona &&
      Geo.puntoEnPoligono([u.lat, u.lng], campania.anillo);

  @override
  Widget build(BuildContext context) {
    final u = ubicacion.actual;
    final permiso = ubicacion.permiso;

    if (u != null) {
      final dentro = estaEnZona(campania, u);
      return _Etiqueta(
        icono: dentro ? Icons.check_circle : Icons.warning_amber_rounded,
        texto: dentro
            ? 'Estás en la zona de la campaña'
            : 'Estás fuera de la zona',
        color: dentro ? AppColors.riesgoBajo : AppColors.riesgoMedio,
      );
    }
    if (permiso != null && permiso != PermisoUbicacion.concedido) {
      return _Etiqueta(
        icono: Icons.location_disabled,
        texto: permiso == PermisoUbicacion.gpsApagado
            ? 'GPS apagado · toca para activarlo'
            : 'Ubicación desactivada · toca para activarla',
        color: AppColors.grisTecnico,
        onTap: () => permiso == PermisoUbicacion.denegado
            ? ubicacion.iniciar()
            : ubicacion.abrirAjustes(),
      );
    }
    return const _Etiqueta(
      icono: Icons.my_location,
      texto: 'Buscando tu ubicación...',
      color: AppColors.grisTecnico,
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icono,
    required this.texto,
    required this.color,
    this.onTap,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
