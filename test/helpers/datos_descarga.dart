import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/core/network/api_client.dart';
import 'package:app_movil_uubr/features/inspeccion/data/actas_store.dart';
import 'package:app_movil_uubr/sync/descarga_service.dart';
import 'package:app_movil_uubr/sync/envio_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_adapter.dart';
import 'memory_session_storage.dart';

/// Cuadrado GeoJSON ([lng, lat]) con esquina inferior izquierda y lado en grados.
Map<String, dynamic> cuadrado(double lng, double lat, double lado) => {
  'type': 'Polygon',
  'coordinates': [
    [
      [lng, lat],
      [lng + lado, lat],
      [lng + lado, lat + lado],
      [lng, lat + lado],
      [lng, lat],
    ],
  ],
};

/// Zona de campaña usada en las pruebas: 0.01° de lado (~1 km).
Map<String, dynamic> zonaNorte() => cuadrado(-63.19, -17.79, 0.01);

Map<String, dynamic> campaniaJson(
  int id,
  String nombre, {
  Map<String, dynamic>? geom,
  String estado = 'en_curso',
}) => {
  'id': id,
  'nombre': nombre,
  'fecha_inicio': '2026-10-01',
  'fecha_fin': '2026-10-31',
  'estado': estado,
  'geom': geom,
  'inspectores': <dynamic>[],
};

Map<String, dynamic> predioJson(
  int id,
  String nombre,
  Map<String, dynamic> geom,
) => {
  'id': id,
  'nombre': nombre,
  'direccion': 'Calle $id',
  'tipo_predio': {'id': 1, 'nombre': 'Comercial'},
  'aforo': 100,
  'area_m2': '320.50',
  'geom': geom,
};

/// Predio pequeño dentro de [zonaNorte].
Map<String, dynamic> predioDentro(int id) =>
    predioJson(id, 'Dentro $id', cuadrado(-63.185, -17.785, 0.001));

/// Predio lejos de [zonaNorte].
Map<String, dynamic> predioFuera(int id) =>
    predioJson(id, 'Fuera $id', cuadrado(-63.10, -17.70, 0.001));

/// Catálogos tal como los devuelve el backend (los decimales llegan como texto).
final catalogosJson = {
  ApiRutas.estadosExtintor: [
    {'id': 1, 'nombre': 'Vigente'},
    {'id': 2, 'nombre': 'Vencido'},
    {'id': 3, 'nombre': 'No posee'},
  ],
  ApiRutas.infracciones: [
    {'id': 1, 'nombre': 'Extintor vencido', 'peso_severidad': '1.50'},
    {
      'id': 2,
      'nombre': 'Ruta de evacuación obstruida',
      'peso_severidad': '2.50',
    },
  ],
  ApiRutas.materiales: [
    {
      'id': 1,
      'nombre': 'Madera',
      'poder_calorifico_mj_kg': '18.41',
      'coeficiente_peligrosidad': '1.00',
    },
    {
      'id': 2,
      'nombre': 'Plásticos',
      'poder_calorifico_mj_kg': '25.00',
      'coeficiente_peligrosidad': '1.50',
    },
  ],
};

/// Servidor falso con campañas, predios y catálogos; `status` permite simular errores.
FakeAdapter servidorDescarga({
  required List<Map<String, dynamic>> campanias,
  required List<Map<String, dynamic>> predios,
  int status = 200,
}) => FakeAdapter((o) async {
  if (status != 200) return jsonResponse({'detail': 'x'}, status: status);
  if (o.path == ApiRutas.campanias) return jsonResponse(campanias);
  if (o.path == ApiRutas.predios) return jsonResponse(predios);
  return jsonResponse(catalogosJson[o.path] ?? <dynamic>[]);
});

/// Base en memoria con SQLite real (FFI), para probar SQL de verdad sin un teléfono.
AppDatabase baseEnMemoria() {
  sqfliteFfiInit();
  return AppDatabase(ruta: inMemoryDatabasePath, factory: databaseFactoryFfi);
}

EnvioService crearEnvio(ActasStore actas, FakeAdapter adapter) {
  final api = ApiClient(
    storage: MemorySessionStorage()..access = jwtVigente(),
    baseUrl: 'http://servidor.test',
    adapter: adapter,
  );
  return EnvioService(api: api, actas: actas);
}

DescargaService crearDescarga(AppDatabase base, FakeAdapter adapter) {
  final api = ApiClient(
    storage: MemorySessionStorage()..access = jwtVigente(),
    baseUrl: 'http://servidor.test',
    adapter: adapter,
  );
  return DescargaService(api: api, database: base);
}
