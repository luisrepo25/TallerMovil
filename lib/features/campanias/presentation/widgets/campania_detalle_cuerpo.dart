import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../catastro/domain/predio.dart';
import '../../../inspeccion/domain/acta_local.dart';
import '../../domain/campania.dart';
import 'campania_cabecera.dart';
import 'mapa_con_ubicacion.dart';
import 'predios_en_zona.dart';

/// Lo que se ve en el detalle de una campaña: cabecera, mapa con la ubicación del inspector
/// (si la campaña tiene zona) y la lista de predios con el estado de su inspección. Solo
/// compone; el estado y las acciones los maneja la pantalla.
class CampaniaDetalleCuerpo extends StatelessWidget {
  const CampaniaDetalleCuerpo({
    super.key,
    required this.campania,
    required this.predios,
    required this.cargando,
    required this.mapa,
    required this.seleccionadoId,
    required this.estados,
    required this.onSeleccionar,
    required this.onInspeccionar,
    required this.onEditar,
  });

  final Campania campania;
  final List<Predio> predios;
  final bool cargando;
  final MapController mapa;
  final int? seleccionadoId;
  final Map<int, EstadoActa> estados;
  final ValueChanged<Predio> onSeleccionar;
  final ValueChanged<Predio> onInspeccionar;
  final ValueChanged<Predio> onEditar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CampaniaCabecera(campania: campania),
        if (campania.tieneZona)
          MapaConUbicacion(
            campania: campania,
            predios: predios,
            controller: mapa,
            predioSeleccionadoId: seleccionadoId,
          ),
        PrediosEnZona(
          tieneZona: campania.tieneZona,
          cargando: cargando,
          predios: predios,
          seleccionadoId: seleccionadoId,
          onSeleccionar: onSeleccionar,
          estados: estados,
          puedeInspeccionar: !campania.estaCerrada,
          onInspeccionar: onInspeccionar,
          onEditar: onEditar,
        ),
      ],
    );
  }
}
