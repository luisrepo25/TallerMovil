import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../core/database/app_database.dart';
import '../core/network/api_client.dart';
import '../features/campanias/data/campanias_local_source.dart';
import '../features/campanias/domain/campania.dart';
import '../features/catastro/data/predios_local_source.dart';
import '../features/catastro/domain/predio.dart';
import '../features/inspeccion/data/acta_servidor.dart';
import '../features/inspeccion/data/actas_local_source.dart';
import '../features/inspeccion/data/catalogos_local_source.dart';
import '../features/inspeccion/domain/catalogos.dart';

class DescargaFailure implements Exception {
  const DescargaFailure(this.mensaje, {this.sinConexion = false});

  final String mensaje;
  final bool sinConexion;

  @override
  String toString() => 'DescargaFailure($mensaje)';
}

class ResultadoDescarga {
  const ResultadoDescarga({
    required this.campanias,
    required this.predios,
    required this.fecha,
  });

  final int campanias;
  final int predios;
  final DateTime fecha;
}

/// "Descargar para trabajar sin conexión": trae del servidor las campañas asignadas y
/// los predios, y los guarda en SQLite **en una sola transacción** (o se guarda todo o
/// no cambia nada: nunca queda la base a medias si se corta la red).
class DescargaService {
  DescargaService({required ApiClient api, required AppDatabase database})
    : _dio = api.dio,
      _database = database,
      _campanias = CampaniasLocalSource(database),
      _predios = PrediosLocalSource(database),
      _catalogos = CatalogosLocalSource(database),
      _actas = ActasLocalSource(database);

  static const claveUltimaDescarga = 'ultima_descarga';

  final Dio _dio;
  final AppDatabase _database;
  final CampaniasLocalSource _campanias;
  final PrediosLocalSource _predios;
  final CatalogosLocalSource _catalogos;
  final ActasLocalSource _actas;

  /// Recupera lo que el inspector ya inspeccionó y el servidor guarda (la base local solo
  /// conoce lo hecho en este teléfono: tras reinstalar o cerrar sesión se vería "sin
  /// inspeccionar" lo que ya está enviado). Es un extra: si falla, la descarga vale igual.
  /// No pisa nada: un acta que ya está en el teléfono (con su detalle completo) se respeta.
  Future<void> _recuperarMisActas() async {
    try {
      final respuesta = await _dio.get<List<dynamic>>(ApiRutas.misActas);
      for (final json in respuesta.data ?? const <dynamic>[]) {
        final acta = actaDesdeServidor(json as Map<String, dynamic>);
        if (await _actas.obtener(acta.uuidLocal) == null) {
          await _actas.guardar(acta);
        }
      }
    } on Object {
      // Sin este historial la app sigue funcionando; se reintenta en la próxima descarga.
    }
  }

  Future<DateTime?> ultimaDescarga() async {
    final db = await _database.db;
    final filas = await db.query(
      'meta',
      where: 'clave = ?',
      whereArgs: [claveUltimaDescarga],
    );
    return filas.isEmpty
        ? null
        : DateTime.parse(filas.first['valor']! as String);
  }

  Future<ResultadoDescarga> descargar() async {
    try {
      final respuestas = await Future.wait([
        _dio.get<List<dynamic>>(ApiRutas.campanias),
        _dio.get<List<dynamic>>(ApiRutas.predios),
        _dio.get<List<dynamic>>(ApiRutas.estadosExtintor),
        _dio.get<List<dynamic>>(ApiRutas.infracciones),
        _dio.get<List<dynamic>>(ApiRutas.materiales),
      ]);
      List<T> convertir<T>(int i, T Function(Map<String, dynamic>) desde) =>
          respuestas[i].data!
              .map((j) => desde(j as Map<String, dynamic>))
              .toList();

      final campanias = convertir(0, Campania.fromApi);
      final predios = convertir(1, Predio.fromApi);
      final catalogos = Catalogos(
        estadosExtintor: convertir(2, EstadoExtintor.fromApi),
        infracciones: convertir(3, TipoInfraccion.fromApi),
        materiales: convertir(4, MaterialCombustible.fromApi),
      );

      final ahora = DateTime.now();
      final db = await _database.db;
      await db.transaction((txn) async {
        await _campanias.reemplazarEn(txn, campanias);
        await _predios.reemplazarEn(txn, predios);
        await _catalogos.reemplazarEn(txn, catalogos);
        await txn.insert('meta', {
          'clave': claveUltimaDescarga,
          'valor': ahora.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      await _recuperarMisActas();
      return ResultadoDescarga(
        campanias: campanias.length,
        predios: predios.length,
        fecha: ahora,
      );
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  DescargaFailure _traducir(DioException e) {
    if (e.response == null) {
      return const DescargaFailure(
        'Sin conexión: se muestran los datos descargados la última vez.',
        sinConexion: true,
      );
    }
    if (e.response!.statusCode == 403) {
      return const DescargaFailure(
        'Tu cuenta no tiene permiso para descargar estos datos.',
      );
    }
    return const DescargaFailure(
      'El servidor no respondió bien. Intenta de nuevo más tarde.',
    );
  }
}
