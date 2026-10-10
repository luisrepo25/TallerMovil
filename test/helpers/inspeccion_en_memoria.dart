import 'package:app_movil_uubr/features/inspeccion/data/actas_store.dart';
import 'package:app_movil_uubr/features/inspeccion/data/catalogos_repository.dart';
import 'package:app_movil_uubr/features/inspeccion/data/evidencias_archivos.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/catalogos.dart';

/// Actas en memoria: permite probar reglas y pantallas sin SQLite.
class ActasEnMemoria implements ActasStore {
  final Map<String, ActaLocal> actas = {};

  @override
  Future<void> guardar(ActaLocal acta) async => actas[acta.uuidLocal] = acta;

  @override
  Future<ActaLocal?> obtener(String uuidLocal) async => actas[uuidLocal];

  @override
  Future<List<ActaLocal>> delPredio(int campaniaId, int predioId) async {
    final lista =
        actas.values
            .where((a) => a.campaniaId == campaniaId && a.predioId == predioId)
            .toList()
          ..sort((a, b) => b.fechaInspeccion.compareTo(a.fechaInspeccion));
    return lista;
  }

  @override
  Future<Map<int, EstadoActa>> estadoPorPredio(int campaniaId) async {
    final delaCampania =
        actas.values.where((a) => a.campaniaId == campaniaId).toList()
          ..sort((a, b) => a.fechaInspeccion.compareTo(b.fechaInspeccion));
    return {for (final a in delaCampania) a.predioId: a.estado};
  }

  @override
  Future<int> contarPendientes() async =>
      actas.values.where((a) => a.estado.pendienteDeEnvio).length;

  @override
  Future<List<ActaLocal>> pendientesDeEnvio() async =>
      (actas.values.where((a) => a.estado == EstadoActa.cerradaLocal).toList()
        ..sort((a, b) => a.fechaInspeccion.compareTo(b.fechaInspeccion)));
}

/// Cámara falsa: cada captura devuelve la siguiente ruta de [rutas] (o `null` = canceló).
class EvidenciasFalsas implements EvidenciasArchivos {
  EvidenciasFalsas([List<String?> rutas = const []]) : _rutas = [...rutas];

  final List<String?> _rutas;
  final List<bool> usoCamara = [];
  final List<String> borradas = [];

  /// Simula que el permiso de la cámara fue denegado.
  bool fallar = false;

  @override
  Future<String?> capturar({required bool camara}) async {
    if (fallar) throw Exception('permiso denegado');
    usoCamara.add(camara);
    return _rutas.isEmpty ? null : _rutas.removeAt(0);
  }

  @override
  Future<void> borrar(String ruta) async => borradas.add(ruta);
}

class CatalogosEnMemoria implements CatalogosStore {
  CatalogosEnMemoria([Catalogos? catalogos])
    : catalogos = catalogos ?? catalogosDePrueba();

  Catalogos catalogos;

  @override
  Future<Catalogos> leer() async => catalogos;
}

Catalogos catalogosDePrueba() => const Catalogos(
  estadosExtintor: [
    EstadoExtintor(id: 1, nombre: 'Vigente'),
    EstadoExtintor(id: 2, nombre: 'Vencido'),
    EstadoExtintor(id: 3, nombre: 'No posee'),
  ],
  infracciones: [
    TipoInfraccion(id: 1, nombre: 'Extintor vencido', pesoSeveridad: 1.5),
    TipoInfraccion(
      id: 2,
      nombre: 'Ruta de evacuación obstruida',
      pesoSeveridad: 2.5,
    ),
  ],
  materiales: [
    MaterialCombustible(
      id: 1,
      nombre: 'Madera',
      poderCalorifico: 18.41,
      coeficientePeligrosidad: 1.0,
    ),
    MaterialCombustible(
      id: 2,
      nombre: 'Plásticos',
      poderCalorifico: 25.0,
      coeficientePeligrosidad: 1.5,
    ),
  ],
);
