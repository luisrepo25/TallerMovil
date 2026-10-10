import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../campanias/domain/campania.dart';
import '../data/actas_repository.dart';
import '../data/catalogos_repository.dart';
import '../data/evidencias_archivos.dart';
import '../domain/acta_edicion.dart';
import '../domain/acta_local.dart';
import '../domain/catalogos.dart';
import 'paso_inspeccion.dart';

export 'paso_inspeccion.dart';

/// Estado del asistente de inspección. **Autoguarda en el teléfono en cada cambio**: si la
/// app se cierra a la fuerza o se acaba la batería, el inspector retoma donde iba.
class InspeccionController extends ChangeNotifier {
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
  final Uuid _uuid;
  final Campania campania;
  final int predioId;

  ActaLocal? acta;
  Catalogos? catalogos;
  PasoInspeccion paso = PasoInspeccion.predio;
  bool cargando = true;
  bool cerrando = false;

  /// Error de carga o de una regla de negocio, listo para mostrar.
  String? error;

  bool _liberado = false;

  bool get esPrimerPaso => paso.index == 0;
  bool get esUltimoPaso => paso.index == PasoInspeccion.values.length - 1;
  bool get editable => acta?.editable ?? false;

  Future<void> iniciar() async {
    try {
      catalogos = await _catalogos.leer();
      acta = await _actas.iniciarOContinuar(
        campania: campania,
        predioId: predioId,
      );
    } on InspeccionNoPermitida catch (e) {
      error = e.mensaje;
    }
    cargando = false;
    _avisar();
  }

  void siguiente() =>
      irAPaso(esUltimoPaso ? paso : PasoInspeccion.values[paso.index + 1]);

  void atras() =>
      irAPaso(esPrimerPaso ? paso : PasoInspeccion.values[paso.index - 1]);

  void irAPaso(PasoInspeccion destino) {
    paso = destino;
    _avisar();
  }

  // --- Cambios del inspector (cada uno se guarda al instante) ---

  Future<void> elegirExtintores(int estadoId) =>
      _modificar((a) => a.copyWith(estadoExtintoresId: estadoId));

  Future<void> marcarFallasElectricas(bool valor) =>
      _modificar((a) => a.copyWith(fallasElectricas: valor));

  Future<void> marcarRutasDespejadas(bool valor) =>
      _modificar((a) => a.copyWith(rutasDespejadas: valor));

  Future<void> guardarMaterial(int materialId, double pesoKg) =>
      _modificar((a) => a.conMaterial(materialId, pesoKg));

  Future<void> quitarMaterial(int materialId) =>
      _modificar((a) => a.sinMaterial(materialId));

  Future<void> guardarInfraccion(int tipoId, String descripcion) =>
      _modificar((a) => a.conInfraccion(tipoId, descripcion));

  Future<void> quitarInfraccion(int tipoId) =>
      _modificar((a) => a.sinInfraccion(tipoId));

  /// Pide al administrador un material que no está en el catálogo. No cuenta en la carga
  /// de fuego hasta que lo apruebe; el inspector sigue con su inspección.
  Future<void> solicitarMaterial({
    required String nombre,
    String descripcion = '',
    double? pesoKgEstimado,
  }) => _modificar(
    (a) => a.conSolicitudMaterial(
      SolicitudMaterialActa(
        uuidLocal: _uuid.v4(),
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        pesoKgEstimado: pesoKgEstimado,
      ),
    ),
  );

  Future<void> quitarSolicitudMaterial(String uuidLocal) =>
      _modificar((a) => a.sinSolicitudMaterial(uuidLocal));

  /// Toma (o elige) una foto y la agrega al acta, sin límite de cantidad. Devuelve la ruta de
  /// la foto agregada para que la pantalla pida su descripción, o `null` si se canceló o falló.
  Future<String?> agregarFoto({required bool camara}) async {
    if (!editable) return null;
    try {
      final ruta = await _archivos.capturar(camara: camara);
      if (ruta == null) return null;
      await _modificar((a) => a.conEvidencia(ruta, ''));
      return ruta;
    } on Exception {
      error = camara
          ? 'No se pudo abrir la cámara. Revisa el permiso de la app en Ajustes.'
          : 'No se pudo abrir la galería. Revisa el permiso de la app en Ajustes.';
      _avisar();
      return null;
    }
  }

  Future<void> describirFoto(String ruta, String descripcion) =>
      _modificar((a) => a.conDescripcionEvidencia(ruta, descripcion));

  Future<void> quitarFoto(String ruta) async {
    await _modificar((a) => a.sinEvidencia(ruta));
    await _archivos.borrar(ruta);
  }

  /// Cierra el acta en el teléfono. Devuelve `true` si quedó cerrada.
  Future<bool> cerrar() async {
    final actual = acta;
    if (actual == null || cerrando) return false;
    cerrando = true;
    error = null;
    _avisar();
    try {
      acta = await _actas.cerrar(actual);
      return true;
    } on InspeccionNoPermitida catch (e) {
      error = e.mensaje;
      return false;
    } finally {
      cerrando = false;
      _avisar();
    }
  }

  Future<void> _modificar(ActaLocal Function(ActaLocal) cambio) async {
    final actual = acta;
    if (actual == null || !actual.editable) return;
    final nueva = cambio(actual);
    acta = nueva; // la pantalla se actualiza al instante
    error = null;
    _avisar();
    await _actas.guardar(nueva); // y se guarda en el teléfono
  }

  void _avisar() {
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
