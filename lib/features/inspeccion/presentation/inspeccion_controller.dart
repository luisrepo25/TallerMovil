import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../campanias/domain/campania.dart';
import '../data/actas_repository.dart';
import '../data/catalogos_repository.dart';
import '../data/evidencias_archivos.dart';
import '../domain/acta_local.dart';
import '../domain/catalogos.dart';
import 'cambios_del_acta.dart';
import 'fotos_del_acta.dart';
import 'paso_inspeccion.dart';

export 'paso_inspeccion.dart';

/// Estado del asistente de inspección. **Autoguarda en el teléfono en cada cambio**: si la
/// app se cierra a la fuerza o se acaba la batería, el inspector retoma donde iba.
class InspeccionController extends ChangeNotifier
    with CambiosDelActa, FotosDelActa {
  InspeccionController({
    required ActasRepository actas,
    required CatalogosRepository catalogos,
    required EvidenciasArchivos archivos,
    required this.campania,
    required this.predioId,
    Uuid? uuid,
  }) : _actas = actas,
       _catalogos = catalogos,
       _archivos = archivos,
       _uuid = uuid ?? const Uuid();

  final ActasRepository _actas;
  final CatalogosRepository _catalogos;
  final EvidenciasArchivos _archivos;

  @override
  EvidenciasArchivos get archivos => _archivos;
  final Uuid _uuid;

  @override
  Uuid get uuid => _uuid;
  final Campania campania;
  final int predioId;

  ActaLocal? acta;

  /// La inspección anterior del predio, solo si esta es una reinspección (referencia).
  @override
  ActaLocal? anterior;
  Catalogos? catalogos;
  PasoInspeccion paso = PasoInspeccion.predio;
  bool cargando = true;
  bool cerrando = false;

  /// Error de carga o de una regla de negocio, listo para mostrar.
  @override
  String? error;

  bool _liberado = false;

  bool get esPrimerPaso => paso.index == 0;
  bool get esUltimoPaso => paso.index == PasoInspeccion.values.length - 1;
  @override
  bool get editable => acta?.editable ?? false;

  Future<void> iniciar() async {
    try {
      catalogos = await _catalogos.leer();
      acta = await _actas.iniciarOContinuar(
        campania: campania,
        predioId: predioId,
      );
      if (acta?.precargadaDe != null) {
        anterior = await _actas.anteriorCerrada(
          campania: campania,
          predioId: predioId,
        );
      }
    } on InspeccionNoPermitida catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    avisar();
  }

  void siguiente() =>
      irAPaso(esUltimoPaso ? paso : PasoInspeccion.values[paso.index + 1]);

  void atras() =>
      irAPaso(esPrimerPaso ? paso : PasoInspeccion.values[paso.index - 1]);

  void irAPaso(PasoInspeccion destino) {
    paso = destino;
    avisar();
  }

  /// Cierra el acta en el teléfono. Devuelve `true` si quedó cerrada.
  Future<bool> cerrar() async {
    final actual = acta;
    if (actual == null || cerrando) return false;
    cerrando = true;
    error = null;
    avisar();
    try {
      acta = await _actas.cerrar(actual);
      return true;
    } on InspeccionNoPermitida catch (e) {
      error = e.mensaje;
      return false;
    } finally {
      cerrando = false;
      avisar();
    }
  }

  @override
  Future<void> modificar(ActaLocal Function(ActaLocal) cambio) async {
    final actual = acta;
    if (actual == null || !actual.editable) return;
    final nueva = cambio(actual);
    acta = nueva; // la pantalla se actualiza al instante
    error = null;
    avisar();
    await _actas.guardar(nueva); // y se guarda en el teléfono
  }

  @override
  void avisar() {
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
