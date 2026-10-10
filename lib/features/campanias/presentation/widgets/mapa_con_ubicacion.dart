import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/location/ubicacion_controller.dart';
import '../../../catastro/domain/predio.dart';
import '../../domain/campania.dart';
import 'campania_mapa.dart';
import 'ubicacion_chip.dart';

/// Mapa de la campaña con la ubicación del inspector: aviso dentro/fuera de la zona
/// arriba a la izquierda y botón para centrarse en su posición abajo a la derecha.
class MapaConUbicacion extends StatelessWidget {
  const MapaConUbicacion({
    super.key,
    required this.campania,
    required this.predios,
    required this.controller,
    required this.predioSeleccionadoId,
  });

  final Campania campania;
  final List<Predio> predios;
  final MapController controller;
  final int? predioSeleccionadoId;

  static const _zoomMinimoAlCentrar = 17.0;

  void _centrar(BuildContext context, UbicacionController ubicacion) {
    final u = ubicacion.actual;
    if (u == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ubicacion.buscando
                  ? 'Buscando tu ubicación...'
                  : 'No se pudo obtener tu ubicación. Revisa el permiso y el GPS.',
            ),
          ),
        );
      if (!ubicacion.buscando) ubicacion.iniciar();
      return;
    }
    final zoom = controller.camera.zoom;
    controller.move(
      LatLng(u.lat, u.lng),
      zoom < _zoomMinimoAlCentrar ? _zoomMinimoAlCentrar : zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = context.watch<UbicacionController>();

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          CampaniaMapa(
            campania: campania,
            predios: predios,
            controller: controller,
            predioSeleccionadoId: predioSeleccionadoId,
            ubicacion: ubicacion.actual,
          ),
          Positioned(
            left: 8,
            top: 8,
            right: 64,
            child: Align(
              alignment: Alignment.centerLeft,
              child: UbicacionChip(campania: campania, ubicacion: ubicacion),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'mi-ubicacion',
              tooltip: 'Mi ubicación',
              onPressed: () => _centrar(context, ubicacion),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
