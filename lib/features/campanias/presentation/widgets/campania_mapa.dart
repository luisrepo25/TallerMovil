import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/ubicacion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catastro/domain/predio.dart';
import '../../domain/campania.dart';
import 'ubicacion_capa.dart';

/// Mapa de la campaña: la zona asignada (contorno punteado) y los predios que caen
/// dentro (el elegido en rojo). Usa OpenStreetMap, sin API key.
///
/// Sin conexión los mosaicos del fondo no cargan, pero la zona y los predios se siguen
/// dibujando porque salen de la base local.
class CampaniaMapa extends StatelessWidget {
  const CampaniaMapa({
    super.key,
    required this.campania,
    required this.predios,
    required this.controller,
    this.predioSeleccionadoId,
    this.ubicacion,
  });

  final Campania campania;
  final List<Predio> predios;
  final MapController controller;
  final int? predioSeleccionadoId;

  /// Posición del inspector (punto azul); `null` si aún no se conoce.
  final Ubicacion? ubicacion;

  static List<LatLng> puntos(List<List<double>> anillo) => [
    for (final p in anillo) LatLng(p[0], p[1]),
  ];

  @override
  Widget build(BuildContext context) {
    final zona = puntos(campania.anillo);

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        backgroundColor: AppColors.grisClaro,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(zona),
          padding: const EdgeInsets.all(36),
          maxZoom: 18,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'bo.org.uubr.app_movil_uubr',
          maxZoom: 19,
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: zona,
              color: AppColors.azulMarino.withValues(alpha: 0.05),
              borderColor: AppColors.azulMarino,
              borderStrokeWidth: 3,
              pattern: StrokePattern.dashed(segments: [10, 6]),
            ),
            for (final p in predios)
              Polygon(
                points: puntos(p.anillo),
                color:
                    (p.id == predioSeleccionadoId
                            ? AppColors.rojoSeguridad
                            : AppColors.azulMarino)
                        .withValues(
                          alpha: p.id == predioSeleccionadoId ? 0.40 : 0.25,
                        ),
                borderColor: p.id == predioSeleccionadoId
                    ? AppColors.rojoSeguridad
                    : AppColors.azulMarinoSuave,
                borderStrokeWidth: p.id == predioSeleccionadoId ? 3 : 2,
              ),
          ],
        ),
        if (ubicacion != null) UbicacionCapa(ubicacion: ubicacion!),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
