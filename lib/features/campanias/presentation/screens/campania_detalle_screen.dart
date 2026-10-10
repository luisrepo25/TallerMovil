import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../../../core/location/ubicacion_controller.dart';
import '../../../../core/location/ubicacion_service.dart';
import '../../../../sync/envio_service.dart';
import '../../../catastro/data/predios_repository.dart';
import '../../../catastro/domain/predio.dart';
import '../../../inspeccion/data/actas_repository.dart';
import '../../../inspeccion/domain/acta_local.dart';
import '../../../inspeccion/presentation/screens/inspeccion_screen.dart';
import '../../domain/campania.dart';
import '../widgets/campania_cabecera.dart';
import '../widgets/campania_mapa.dart';
import '../widgets/mapa_con_ubicacion.dart';
import '../widgets/predios_en_zona.dart';

/// Detalle de una campaña: mapa con su zona y la ubicación del inspector, y los predios
/// descargados que caen en ella con el estado de su inspección. Tocar un predio lo resalta
/// en el mapa; su botón abre (o retoma) la inspección, que funciona sin conexión.
class CampaniaDetalleScreen extends StatefulWidget {
  const CampaniaDetalleScreen({super.key, required this.campania});

  final Campania campania;

  @override
  State<CampaniaDetalleScreen> createState() => _CampaniaDetalleScreenState();
}

class _CampaniaDetalleScreenState extends State<CampaniaDetalleScreen> {
  final _mapa = MapController();
  late final Future<List<Predio>> _predios;
  late final UbicacionController _ubicacion;
  Map<int, EstadoActa> _estados = const {};
  int? _seleccionadoId;

  Campania get _campania => widget.campania;

  @override
  void initState() {
    super.initState();
    _predios = context.read<PrediosRepository>().enZona(_campania);
    // Solo se sigue el GPS si hay zona que mostrar; se detiene al salir de la pantalla
    _ubicacion = UbicacionController(context.read<UbicacionService>());
    if (_campania.tieneZona) _ubicacion.iniciar();
    _cargarEstados();
  }

  @override
  void dispose() {
    _ubicacion.dispose();
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _cargarEstados() async {
    // El envío puede terminar cuando el inspector ya salió de esta pantalla
    if (!mounted) return;
    final estados = await context.read<ActasRepository>().estadoPorPredio(
      _campania.id,
    );
    if (mounted) setState(() => _estados = estados);
  }

  Future<void> _inspeccionar(Predio predio) async {
    final envio = context.read<EnvioService>();
    final cerrada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InspeccionScreen(campania: _campania, predio: predio),
      ),
    );
    // Al volver (cerró el acta o dejó un borrador) se refresca el estado de los predios
    await _cargarEstados();
    if (cerrada == true) {
      // Con señal sale enseguida; sin señal queda "Lista para enviar" y se reintenta sola
      await envio.enviarPendientes();
      await _cargarEstados();
    }
  }

  /// Reabre para corregirla un acta cerrada que todavía no se envió.
  Future<void> _editar(Predio predio) async {
    final mensajes = ScaffoldMessenger.of(context);
    if (context.read<EnvioService>().enCurso) {
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('Se están enviando actas. Intenta en unos segundos.'),
        ),
      );
      return;
    }
    try {
      await context.read<ActasRepository>().reabrirUltima(
        campania: _campania,
        predioId: predio.id,
      );
    } on InspeccionNoPermitida catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
      await _cargarEstados();
      return;
    }
    if (mounted) await _inspeccionar(predio);
  }

  void _seleccionar(Predio predio) {
    setState(() => _seleccionadoId = predio.id);
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(CampaniaMapa.puntos(predio.anillo)),
        padding: const EdgeInsets.all(80),
        maxZoom: 19,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UbicacionController>.value(
      value: _ubicacion,
      child: Scaffold(
        appBar: AppBar(title: Text(_campania.nombre)),
        body: FutureBuilder<List<Predio>>(
          future: _predios,
          builder: (context, snapshot) {
            final predios = snapshot.data ?? const <Predio>[];
            return ListView(
              children: [
                CampaniaCabecera(campania: _campania),
                if (_campania.tieneZona)
                  MapaConUbicacion(
                    campania: _campania,
                    predios: predios,
                    controller: _mapa,
                    predioSeleccionadoId: _seleccionadoId,
                  ),
                PrediosEnZona(
                  tieneZona: _campania.tieneZona,
                  cargando: !snapshot.hasData,
                  predios: predios,
                  seleccionadoId: _seleccionadoId,
                  onSeleccionar: _seleccionar,
                  estados: _estados,
                  puedeInspeccionar: !_campania.estaCerrada,
                  onInspeccionar: _inspeccionar,
                  onEditar: _editar,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
