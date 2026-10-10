import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/ubicacion_service.dart';

/// Capa del mapa con la posición del inspector: un punto azul y un círculo suave con la
/// precisión del GPS (radio en metros reales, se agranda al alejar el zoom).
class UbicacionCapa extends StatelessWidget {
  const UbicacionCapa({super.key, required this.ubicacion});

  final Ubicacion ubicacion;

  static const azulUbicacion = Color(0xFF1F6FEB);

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(ubicacion.lat, ubicacion.lng);

    return Stack(
      children: [
        CircleLayer(
          circles: [
            CircleMarker(
              point: punto,
              radius: ubicacion.precisionM,
              useRadiusInMeter: true,
              color: azulUbicacion.withValues(alpha: 0.12),
              borderColor: azulUbicacion.withValues(alpha: 0.35),
              borderStrokeWidth: 1,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: punto,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: azulUbicacion,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
